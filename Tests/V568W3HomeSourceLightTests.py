#!/usr/bin/env python3
"""Protect real v568 W3 NewHome290 lighting constants; no image parity claim.

PC source reference is the 4 SHA-pinned v568 ZIPs in this repository,
not a similarly named GLB or a visual guess.
"""
from pathlib import Path
import importlib.util
import re

ROOT=Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location("archive568", ROOT/"Tools/stage_v568_resources.py")
archive=importlib.util.module_from_spec(spec)
spec.loader.exec_module(archive)

streams=[]
try:
    streams,entries,hashes,total=archive.verify_archive_set(ROOT)
    def pc(name):
        filename="PortingReferenceCode/v568/Windows/src/"+name
        z,info=entries[filename]
        return z.read(info).decode("utf-8-sig")
    original_ship=pc("GpuShip.cs")
    original_preview=pc("GpuW3HomeReal333.cs")
    original_home=pc("GpuNewHome290.cs")
    original_toon=pc("GpuToon60.cs")
    original_renderer=pc("GpuRenderer.cs")
    native=(ROOT/"ASTEROIDYiOS/W3HomePlanet290.metal").read_text()
    preview=(ROOT/"ASTEROIDYiOS/W3HomePlanetMetal568.swift").read_text()
    assert "keyPosition={-.6f,.8f,1.4f,0}" in original_ship
    assert "shipLight(0x4000,0x1203,keyPosition)" in original_ship
    assert "void FighterLight(bool tunnel)" in original_ship
    assert "FighterLight(false);UpdateBasaltSun111(time);" in original_preview
    assert "BeginToon60(true,true);" in original_home
    assert "BeginToon60(true,false);" in original_home
    assert "if(smooth65)band=0.25+0.78*d" in original_toon
    assert "float3 l=normalize(float3(-0.6f,0.8f,1.4f));" in native
    assert "float band=0.25f+0.78f*d;" in native
    assert "glowMask*u.glowPower" in native
    assert "public float LavaLightBrightness287=1.8f;" in original_renderer
    assert "var glowPower:Float=1.8" in preview
    assert "float3 n=normalize(in.normal);" in native
    assert "float3 view=normalize(" in native
    assert "if(u.material==0u)" in native
    assert "uniform.material=1" in preview
    print("PASS: original v568 W3 FighterLight eye-space key (-0.6,0.8,1.4,0)")
    print("PASS: smooth Toon60 0.25+0.78*d, PC home lava default 1.8, two materials")
    print("LIMIT: fill light, complete shader and visual parity remain unverified")
finally:
    for z in streams:
        z.close()
