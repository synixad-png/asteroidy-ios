#!/usr/bin/env python3
"""Isolated H13 GLB metadata checks; no original hangar is claimed."""
import importlib.util
import json
import struct
import tempfile
from pathlib import Path

SOURCE = Path(__file__).resolve().parents[1] / "Tools" / "audit_h55_materials580.py"
spec = importlib.util.spec_from_file_location("h13_audit", SOURCE)
assert spec and spec.loader
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)

def make_glb(path, doc):
    data = json.dumps(doc, separators=(",", ":")).encode()
    data += b" " * ((-len(data)) % 4)
    path.write_bytes(struct.pack("<4sII", b"glTF", 2, 20 + len(data)) +
                     struct.pack("<I4s", len(data), b"JSON") + data)

with tempfile.TemporaryDirectory() as folder:
    path = Path(folder) / "sample.glb"
    make_glb(path, {"asset": {"version": "2.0"}, "materials": [
        {"name": "Floor"},
        {"name": "Fence", "alphaMode": "MASK", "alphaCutoff": 0.35, "doubleSided": True},
        {"name": "Window", "alphaMode": "BLEND", "pbrMetallicRoughness": {
            "baseColorTexture": {"index": 0}, "baseColorFactor": [1, 1, 1, 0.6]}},
        {"name": "Glass", "extensions": {"KHR_materials_transmission": {
            "transmissionFactor": 0.8}}}
    ], "images": [{"bufferView": 0, "mimeType": "image/png"}]})
    result = module.audit_materials(module.glb_document(path))
    assert result["materialCount"] == 4 and result["imageCount"] == 1
    assert result["alphaModeCounts"] == {"BLEND": 1, "MASK": 1, "OPAQUE": 2}
    assert result["doubleSidedCount"] == 1
    assert result["baseColorTexturedCount"] == 1
    assert result["alphaBlendMaterials"][0]["name"] == "Window"
    assert result["transmissionOrVolumeMaterials"][0]["name"] == "Glass"
    assert not result["issues"]
    make_glb(path, {"asset": {"version": "2.0"}, "materials": [
        {"name": "Bad", "alphaMode": "MASK", "alphaCutoff": 9,
         "pbrMetallicRoughness": {"baseColorFactor": [1, 2]}}
    ]})
    bad = module.audit_materials(module.glb_document(path))
    assert len(bad["issues"]) == 2
    before = path.read_bytes()
    module.glb_document(path)
    assert path.read_bytes() == before
    path.write_bytes(path.read_bytes()[:-4])
    try:
        module.glb_document(path)
    except module.AuditError:
        pass
    else:
        raise AssertionError("Truncated GLB accepted")
print("PASS H13: JSON-only GLB material census, alpha modes, volume/transmission, malformed input, read-only integrity")
