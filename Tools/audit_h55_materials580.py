#!/usr/bin/env python3
"""Read-only GLB 2.0 material census for ASTEROIDY PC v580 H55.

Inspects only the JSON chunk; never decodes, rewrites or copies 126 MB BIN.
The output is an audit, not proof of SceneKit visual parity.
"""
from __future__ import annotations
import argparse
import collections
import json
import math
import os
import struct
from pathlib import Path

class AuditError(ValueError):
    pass

def glb_document(path: Path) -> dict:
    with path.open("rb") as stream:
        header = stream.read(12)
        if len(header) != 12:
            raise AuditError("Truncated GLB header")
        magic, version, length = struct.unpack("<4sII", header)
        if magic != b"glTF" or version != 2:
            raise AuditError("Expected GLB 2.0")
        if length != os.fstat(stream.fileno()).st_size:
            raise AuditError("Incorrect GLB declared length")
        chunk = stream.read(8)
        if len(chunk) != 8:
            raise AuditError("Missing JSON chunk header")
        json_length, chunk_type = struct.unpack("<I4s", chunk)
        if chunk_type != b"JSON" or json_length > 64 * 1024 * 1024:
            raise AuditError("Invalid JSON chunk type or size")
        if json_length % 4 or json_length + 20 > length:
            raise AuditError("Invalid JSON chunk bounds/alignment")
        data = stream.read(json_length)
        if len(data) != json_length:
            raise AuditError("Truncated JSON chunk")
    try:
        document = json.loads(data.rstrip(b" \x00\t\r\n").decode("utf-8"))
    except (UnicodeDecodeError, json.JSONDecodeError) as exc:
        raise AuditError("Invalid UTF-8 JSON chunk") from exc
    if not isinstance(document, dict) or document.get("asset", {}).get("version") != "2.0":
        raise AuditError("Expected glTF asset.version 2.0")
    return document

def audit_materials(doc: dict) -> dict:
    materials = doc.get("materials", [])
    if not isinstance(materials, list):
        raise AuditError("materials must be an array")
    alpha_modes = collections.Counter()
    extensions = collections.Counter()
    issues = []
    double_sided = 0
    textured = 0
    translucent = []
    transmission = []
    for i, material in enumerate(materials):
        if not isinstance(material, dict):
            raise AuditError(f"material[{i}] is not a JSON object")
        label = material.get("name") or f"material[{i}]"
        alpha = material.get("alphaMode", "OPAQUE")
        alpha_modes[str(alpha)] += 1
        if alpha not in ("OPAQUE", "MASK", "BLEND"):
            issues.append(f"{label}: unknown alphaMode={alpha!r}")
        if material.get("doubleSided", False) is True:
            double_sided += 1
        elif not isinstance(material.get("doubleSided", False), bool):
            issues.append(f"{label}: doubleSided is not boolean")
        pbr = material.get("pbrMetallicRoughness", {})
        if not isinstance(pbr, dict):
            issues.append(f"{label}: invalid pbrMetallicRoughness")
            pbr = {}
        if isinstance(pbr.get("baseColorTexture"), dict):
            textured += 1
        factor = pbr.get("baseColorFactor", [1, 1, 1, 1])
        if not isinstance(factor, list) or len(factor) != 4 or any(
            not isinstance(x, (int, float)) or not math.isfinite(x) for x in factor
        ):
            issues.append(f"{label}: malformed baseColorFactor")
        if alpha == "MASK":
            cutoff = material.get("alphaCutoff", 0.5)
            if not isinstance(cutoff, (int, float)) or not math.isfinite(cutoff) or not (0 <= cutoff <= 1):
                issues.append(f"{label}: invalid alphaCutoff")
        if alpha == "BLEND":
            translucent.append({"index": i, "name": label})
        ext = material.get("extensions", {})
        if not isinstance(ext, dict):
            issues.append(f"{label}: extensions must be object")
            ext = {}
        for key in ext:
            extensions[str(key)] += 1
        if "KHR_materials_transmission" in ext or "KHR_materials_volume" in ext:
            transmission.append({"index": i, "name": label, "extensions": [
                k for k in ("KHR_materials_transmission", "KHR_materials_volume") if k in ext
            ]})
    return {
        "materialCount": len(materials),
        "meshCount": len(doc.get("meshes", [])),
        "imageCount": len(doc.get("images", [])),
        "alphaModeCounts": dict(sorted(alpha_modes.items())),
        "doubleSidedCount": double_sided,
        "baseColorTexturedCount": textured,
        "materialExtensions": dict(sorted(extensions.items())),
        "alphaBlendMaterials": translucent,
        "transmissionOrVolumeMaterials": transmission,
        "issues": issues,
        "note": "JSON metadata only; does not measure SceneKit rendering, audio or device FPS.",
    }

def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("hangar_glb", type=Path, help="Original hangar_h55.glb (read-only)")
    parser.add_argument("--output", type=Path, help="Write detailed JSON audit")
    args = parser.parse_args()
    result = audit_materials(glb_document(args.hangar_glb))
    encoded = json.dumps(result, indent=2, ensure_ascii=False) + "\n"
    if args.output:
        args.output.write_text(encoded, encoding="utf-8")
    else:
        print(encoded, end="")

if __name__ == "__main__":
    main()
