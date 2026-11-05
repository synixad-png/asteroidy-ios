#!/usr/bin/env python3
"""Import *actual* user-owned ASTEROIDY PC v568 Vanguard431 assets.

Nothing is downloaded from the Internet or approximated. This reads the
embedded v4311 GPU mesh (12 floats per vertex, original normals/UV)
and BaseColor JPEG from the specified original source ZIP. The two
outputs must be committed into ASTEROIDYiOS/Assets in order for the
textured Metal pipeline to become active in a later IPA.

Usage:
  python3 Tools/import_original_vanguard431.py <PC_V568_SOURCE.zip> \
      [<output directory>]

The old Vanguard556.as3d and shaders are deliberately untouched.
"""
import gzip
import hashlib
import json
import pathlib
import struct
import sys
import zipfile

MESH_PATH="Shared/assets/vanguard431/vanguard431.mesh.gz"
JPEG_PATH="Shared/assets/vanguard431/vanguard431.base.jpg"
GLB_PATH="Shared/assets/vanguard431/Vanguard_551_SOURCE.glb"
BAKE_PATH="Shared/assets/vanguard431/BakeInfo.json"
MESH_SHA256="f5d6d0107437fa54c3e8505f9adfbf6143cc877cb970eef687603609e26f9f4a"
JPEG_SHA256="2945f711a6b559bfb5fdfb79750a2f2f77e2071aa5f3f4173eb450bce81b8b95"


def base_from_glb(blob):
    if blob[:4] != b"glTF" or struct.unpack_from("<I",blob,4)[0] != 2:
        raise ValueError("Expected original glTF 2.0 source")
    js = None
    bin_chunk = None
    pos = 12
    while pos < len(blob):
        length, kind = struct.unpack_from("<I4s",blob,pos)
        pos += 8
        if kind == b"JSON":
            js = json.loads(blob[pos:pos+length])
        elif kind == b"BIN\\0".replace(b"\\0",b"\x00"):
            bin_chunk = memoryview(blob)[pos:pos+length]
        pos += length
    if js is None or bin_chunk is None:
        raise ValueError("Missing original glTF JSON/BIN chunks")
    primitive = js["meshes"][0]["primitives"][0]
    material = js["materials"][primitive["material"]]
    base_index = material["pbrMetallicRoughness"]["baseColorTexture"]["index"]
    image = js["images"][js["textures"][base_index]["source"]]
    view = js["bufferViews"][image["bufferView"]]
    if image["mimeType"] != "image/jpeg":
        raise ValueError("Expected authentic source JPEG BaseColor")
    offset = view.get("byteOffset",0)
    return bytes(bin_chunk[offset:offset+view["byteLength"]])


def main(zip_path,folder):
    with zipfile.ZipFile(zip_path) as archive:
        raw = gzip.decompress(archive.read(MESH_PATH))
        jpeg = archive.read(JPEG_PATH)
        metadata = json.loads(archive.read(BAKE_PATH))
        original_jpeg = base_from_glb(archive.read(GLB_PATH))
    if jpeg != original_jpeg:
        raise ValueError("Embedded source glTF BaseColor differs from v4311 runtime skin")
    if hashlib.sha256(raw).hexdigest() != MESH_SHA256:
        raise ValueError("Not the verified original v568 Vanguard431 mesh")
    if hashlib.sha256(jpeg).hexdigest() != JPEG_SHA256:
        raise ValueError("Not the verified original 2048px Vanguard431 BaseColor")
    version, engines = struct.unpack_from("<ii",raw,0)
    if (version,engines) != (4311,2):
        raise ValueError("Invalid original v4311 resource header")
    float_count = struct.unpack_from("<i",raw,32)[0]
    if float_count != 194427 * 12:
        raise ValueError("Unexpected original GPU vertex count")
    faces_offset=36+float_count*4
    cpu_faces=struct.unpack_from("<i",raw,faces_offset)[0]
    if cpu_faces != 10802 or faces_offset+4+cpu_faces*9*4 != len(raw):
        raise ValueError("Invalid original CPU mesh trailer")
    if metadata["gpu_vertices"] != 194427 or metadata["jpeg_bytes"] != len(jpeg):
        raise ValueError("Original BakeInfo.json does not match source assets")
    output=pathlib.Path(folder)
    output.mkdir(parents=True,exist_ok=True)
    mesh_dest=output/"Vanguard431Source.mesh"
    base_dest=output/"Vanguard431Base.jpg"
    mesh_dest.write_bytes(raw)
    base_dest.write_bytes(jpeg)
    print("PASS: verified actual PC v4311 source data and glTF BaseColor")
    print(f"Original GPU vertices: {float_count//12:,}; CPU faces: {cpu_faces:,}")
    for path in (mesh_dest,base_dest):
        print(f"{path}: {path.stat().st_size:,} bytes, sha256={hashlib.sha256(path.read_bytes()).hexdigest()}")
    print("Source export does not modify Vanguard556.as3d or any combat files")


if __name__ == "__main__":
    if len(sys.argv) not in (2,3):
        raise SystemExit("usage: import_original_vanguard431.py PC_V568_SOURCE.zip [ASTEROIDYiOS/Assets]")
    main(sys.argv[1],sys.argv[2] if len(sys.argv)==3 else "ASTEROIDYiOS/Assets")
