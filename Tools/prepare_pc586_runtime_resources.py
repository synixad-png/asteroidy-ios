#!/usr/bin/env python3
"""Convert FOUR SHA-locked PC v586 GLBs into original Metal mesh/JPEG resources.

This is an offline build step, not an extra renderer or a frame-time loader.
Output is a source model GLB, a losslessly expanded 12-float triangle stream,
and the unchanged embedded JPEG for each of the four source kinds.
"""
import argparse
import hashlib
import io
import json
import math
import os
import struct
import tempfile
import zipfile
from pathlib import Path

ORIGINALS = {
    "shield.glb": (478320, "531f1d49ea9782a2c40ce6870cd308d067461cc5f80cfaefc659f3db4ffe5a62"),
    "boost.glb": (502996, "6f7a083b493b029f4907988b55dbf9cdc49c7d5d187e023fa20521319b494362"),
    "energy.glb": (506076, "df9c3a85ef45d55d3ce08d9d82ec9ec1f0ec1b8c2cdf06fb35550eb96aa3aca1"),
    "bomb.glb": (483424, "e8787ce4b11c8b44b6b710a93419b0c8cc263cafe27c35e580b0c4cb8bffaaee"),
}


def sha(data):
    return hashlib.sha256(data).hexdigest()


def glb_parts(data):
    if len(data) < 28 or data[:4] != b"glTF" or struct.unpack_from("<II", data, 4) != (2, len(data)):
        raise ValueError("Invalid binary glTF header")
    offset = 12
    parts = {}
    while offset + 8 <= len(data):
        length, kind = struct.unpack_from("<I4s", data, offset)
        offset += 8
        if length > len(data) - offset or kind in parts:
            raise ValueError("Invalid or duplicated GLB chunk")
        parts[kind] = data[offset:offset + length]
        offset += length
    if offset != len(data) or b"JSON" not in parts or b"BIN\0" not in parts:
        raise ValueError("Incomplete GLB")
    return json.loads(parts[b"JSON"]), parts[b"BIN\0"]


def convert(name, data):
    expected_size, expected_hash = ORIGINALS[name]
    if len(data) != expected_size or sha(data) != expected_hash:
        raise ValueError("Unverified original GLB: " + name)
    document, binary = glb_parts(data)
    scene = document["scenes"][document.get("scene", 0)]
    nodes = document["nodes"]
    if len(scene["nodes"]) != 1 or len(nodes) != 1 or nodes[0].get("mesh") != 0:
        raise ValueError("Unexpected model hierarchy: " + name)
    if any(k in nodes[0] for k in ("matrix", "translation", "rotation", "scale")):
        raise ValueError("Unapplied source transform: " + name)
    primitives = document["meshes"][0]["primitives"]
    if len(primitives) != 1 or primitives[0].get("mode", 4) != 4:
        raise ValueError("Expected one triangle primitive: " + name)
    primitive = primitives[0]
    if set(primitive["attributes"]) != {"POSITION", "NORMAL", "TEXCOORD_0"}:
        raise ValueError("Unexpected source vertex semantics: " + name)
    material = document["materials"][primitive["material"]]
    if not material.get("doubleSided") or material.get("alphaMode", "OPAQUE") != "OPAQUE":
        raise ValueError("Unexpected source material: " + name)
    pbr = material["pbrMetallicRoughness"]
    rgba = pbr.get("baseColorFactor", [1, 1, 1, 1])
    image = document["images"][document["textures"][pbr["baseColorTexture"]["index"]]["source"]]
    if image.get("mimeType") != "image/jpeg":
        raise ValueError("Original texture must be JPEG: " + name)
    views = document["bufferViews"]
    accessors = document["accessors"]

    def view_bytes(index):
        view = views[index]
        if view["buffer"] != 0:
            raise ValueError("Unexpected external binary buffer")
        offset = view.get("byteOffset", 0)
        length = view["byteLength"]
        if offset < 0 or length < 0 or offset + length > len(binary):
            raise ValueError("Out-of-bounds buffer view")
        return binary[offset:offset + length]

    def attribute(key, components):
        accessor = accessors[primitive["attributes"][key]]
        if accessor.get("componentType") != 5126 or accessor.get("type") != f"VEC{components}" or accessor.get("sparse"):
            raise ValueError("Original float attribute required: " + key)
        raw = view_bytes(accessor["bufferView"])
        offset = accessor.get("byteOffset", 0)
        stride = views[accessor["bufferView"]].get("byteStride", components * 4)
        count = accessor["count"]
        if count < 1 or stride < components * 4 or offset + stride * (count - 1) + components * 4 > len(raw):
            raise ValueError("Attribute data exceeds buffer view: " + key)
        values = [struct.unpack_from("<" + "f" * components, raw, offset + i * stride) for i in range(count)]
        if any(not all(map(math.isfinite, entry)) for entry in values):
            raise ValueError("Nonfinite original vertex: " + key)
        return values

    position = attribute("POSITION", 3)
    normal = attribute("NORMAL", 3)
    uv = attribute("TEXCOORD_0", 2)
    if len(position) != len(normal) or len(position) != len(uv):
        raise ValueError("Attribute counts differ")
    indices = accessors[primitive["indices"]]
    if indices.get("type") != "SCALAR" or indices.get("componentType") not in (5123, 5125) or indices["count"] % 3:
        raise ValueError("Unexpected triangle index format")
    raw = view_bytes(indices["bufferView"])
    offset = indices.get("byteOffset", 0)
    stride = 2 if indices["componentType"] == 5123 else 4
    count = indices["count"]
    if offset + count * stride > len(raw):
        raise ValueError("Truncated GLB index buffer")
    numbers = struct.unpack_from("<" + ("H" if stride == 2 else "I") * count, raw, offset)
    if any(i >= len(position) for i in numbers):
        raise ValueError("Out-of-bounds triangle index")

    stream = io.BytesIO()
    stream.write(b"P586" + struct.pack("<I", count) + bytes.fromhex(expected_hash))
    for index in numbers:
        stream.write(struct.pack("<12f", *position[index], *normal[index], *rgba, *uv[index]))
    jpeg = view_bytes(image["bufferView"])
    if not jpeg.startswith(b"\xff\xd8") or not jpeg.endswith(b"\xff\xd9"):
        raise ValueError("Malformed embedded source JPEG")
    return stream.getvalue(), jpeg, {"vertices": count, "triangles": count // 3}


def read_originals(path):
    found = {}
    with zipfile.ZipFile(path) as archive:
        if archive.testzip() is not None:
            raise ValueError("Source ZIP CRC failure")
        names = set(archive.namelist())
        for name in ORIGINALS:
            matches = [candidate for candidate in
                       ("Shared/assets/pickups/" + name, "pickups/" + name, name)
                       if candidate in names]
            if len(matches) != 1:
                raise ValueError("Missing or ambiguous original GLB: " + name)
            found[name] = archive.read(matches[0])
    return found


def stage(source, destination):
    originals = read_originals(source)
    payloads = {}
    manifest = {}
    for name, original in originals.items():
        mesh, jpeg, counts = convert(name, original)
        base = name.removesuffix(".glb")
        payloads[name] = original
        payloads[base + ".mesh"] = mesh
        payloads[base + ".jpg"] = jpeg
        manifest[name] = {
            **counts, "model_sha256": sha(original),
            "mesh_sha256": sha(mesh), "jpg_sha256": sha(jpeg)
        }
    destination.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="staging_", dir=destination) as temp:
        staging = Path(temp)
        for name, payload in payloads.items():
            (staging / name).write_bytes(payload)
        for name, payload in payloads.items():
            if (staging / name).read_bytes() != payload:
                raise ValueError("Staging integrity mismatch: " + name)
        for name in payloads:
            os.replace(staging / name, destination / name)
    print(json.dumps({"result": "PASS", "files": sorted(payloads),
                      "manifest": manifest}, indent=2))


def main():
    cli = argparse.ArgumentParser()
    cli.add_argument("--models", type=Path, required=True)
    cli.add_argument("--destination", type=Path, required=True)
    args = cli.parse_args()
    stage(args.models, args.destination)


if __name__ == "__main__":
    main()
