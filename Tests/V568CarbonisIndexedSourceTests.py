#!/usr/bin/env python3
"""Fail-closed source-level test for real CARBONIS Level 01 (v568 C279).

Runs against four original audited ZIPs, not a stock sphere or generated GLB.
Exercises the original indexed source geometry and byte-for-byte three
textures. Actual iOS GPU scene / mission gameplay are NOT claimed here.
"""
import importlib.util
import json
import tempfile
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location(
    "carbonis568",ROOT/"Tools/prepare_v568_carbonis_sector01.py")
m=importlib.util.module_from_spec(spec)
spec.loader.exec_module(m)

with tempfile.TemporaryDirectory() as d:
    target=Path(d)/"Assets"
    m.stage(ROOT,target)
    out=json.loads((target/"Sector01CarbonisSource.json").read_text())
    assert out["source"]=="Windows/src/Carbonis277.cs; original v568"
    assert out["level"]==1 and out["planet"]=="CARBONIS / PBR"
    assert out["triangleCount"]==270249
    assert out["uniqueVertexCount"]==137067
    assert out["materialGroups"]==[
        {"index":0,"firstIndex":0,"indexCount":803712},
        {"index":1,"firstIndex":803712,"indexCount":7035}
    ]
    assert out["indexedGpuBytes"]==9822204
    assert out["expandedEquivalentBytes"]==38915856
    assert out["nativeSector01GameplayIntegrated"] is False
    for filename,expected in (
      ("Sector01CarbonisVertices.bin",m.VERTEX_SHA),
      ("Sector01CarbonisIndices.bin",m.INDEX_SHA),
      ("Sector01CarbonisHeightMap.dat",m.HEIGHT_SHA),
      ("Sector01CarbonisBase.dat",m.FILES["carbonis277.base.jpg"]),
      ("Sector01CarbonisEmissive.dat",m.FILES["carbonis277.emissive.png"]),
      ("Sector01CarbonisIrradiance.dat",m.FILES["carbonis288.irradiance.png"])
    ):
        assert m.sha((target/filename).read_bytes())==expected,filename
    assert len((target/"Sector01CarbonisVertices.bin").read_bytes())==6579216
    assert len((target/"Sector01CarbonisIndices.bin").read_bytes())==3242988
    assert len((target/"Sector01CarbonisHeightMap.dat").read_bytes())==524296
    # Re-running is lossless, but a modified output must be rejected.
    m.stage(ROOT,target)
    corrupted=target/"Sector01CarbonisIndices.bin"
    corrupted.write_bytes(corrupted.read_bytes()[:128])
    try:
        m.stage(ROOT,target)
    except ValueError as e:
        assert "Refusing overwrite" in str(e)
    else:
        raise AssertionError("Modified indexed source geometry passed validation")
print("PASS: original v568 C279 Carbonis 270249 triangles, source indices/UVs, two groups, 3 texture SHA, 512x256 collision heights")
print("PASS: 9.82MB indexed geometry instead of 38.92MB expanded GPU data; source and material identity protected")
print("LIMIT: native in-game rendering, source shaders, mission launch, and physical iPhone/iPad behavior not yet proven")
