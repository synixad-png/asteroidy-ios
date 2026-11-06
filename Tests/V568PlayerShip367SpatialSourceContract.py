#!/usr/bin/env python3
"""Check v568 original PlayerShip367 placement geometry against source C#.

This deliberately does not claim pixel-perfect PC/Metal parity. It pins the
actual v568 source coordinate conventions, default 100% mission scale and
original scaled GPU vertex bounds, leaving user mission-scale settings
(70..150%) for a future faithful UI port.
"""
from pathlib import Path
import importlib.util
import math
import re
import struct
ROOT=Path(__file__).resolve().parents[1]

def module(name,relative):
    s=importlib.util.spec_from_file_location(name,ROOT/relative)
    mod=importlib.util.module_from_spec(s)
    s.loader.exec_module(mod)
    return mod

stage=module("v568_stage_bounds","Tools/stage_v568_resources.py")
ship=module("v568_ship_bounds","Tools/convert_v568_player_ship367.py")
swift=(ROOT/"ASTEROIDYiOS/Sphere67.swift").read_text(encoding="utf-8")
metal=(ROOT/"ASTEROIDYiOS/MetalRenderer.swift").read_text(encoding="utf-8")
archives=[]
try:
    archives,entries,hashes,total=stage.verify_archive_set(ROOT)
    def original(name):
        z,info=entries["PortingReferenceCode/v568/Windows/src/"+name]
        return z.read(info).decode("utf-8-sig")
    pc=original("GpuSphere67.cs")
    pc_ship=original("PlayerShip363.cs")
    assert "Game.ShipContactRadius*Scale67*.65f" in pc
    assert "shipScale(MissionShipScale472,MissionShipScale472,MissionShipScale472)" in pc
    assert "float MissionShipScale472=1f" in original("GpuRenderer.cs") if (
        "PortingReferenceCode/v568/Windows/src/GpuRenderer.cs" in entries
    ) else "MissionShipScale472" in pc
    assert "const float StandardSize369=.714f" in pc_ship
    assert "float[] vertices" in pc_ship and "engines" in pc_ship
    assert "static let sourceCraftRadius: Float =" in swift
    assert "sourceShipContactRadius * 0.65" in swift
    assert "size*Self.normalizedScalePerArcUnit" in swift
    assert "let craft=Self.sphereStamp(" in metal
    assert "size:SphereSurfaceStamp556.sourceCraftRadius" in metal
    assert "Self.rotateYDegrees(sphereFlight.flight.visualBank)" in metal
    assert "Self.rotateXDegrees(sphereFlight.flight.visualPitch)" in metal
    assert "let shipModel=craft *" in metal
    assert "mvp:vp*shipModel,model:shipModel" in metal
    assert "PlayerShip363 has already applied StandardSize369=.714" in metal
    z,info=entries["PortingResources/v568/Shared/assets/player_ship367.mesh.gz"]
    gpu,face,metadata=ship.convert(z.read(info))
    mins=[float("inf")]*3
    maxs=[-float("inf")]*3
    for i in range(0,len(gpu),48):
        xyz=struct.unpack_from("<3f",gpu,i)
        for axis in range(3):
            mins[axis]=min(mins[axis],xyz[axis])
            maxs[axis]=max(maxs[axis],xyz[axis])
    reference=(
        (-1.9043600559,-2.8559317589,-0.7921019197),
        (1.9041782618,2.8555860519,0.7918837070)
    )
    for result,expected in zip((mins,maxs),reference):
        assert all(math.isclose(a,b,abs_tol=0.00001) for a,b in zip(result,expected)),(result,expected)
    assert metadata["vertexCount"]==599997
    assert metadata["sizeScale"]==0.714
    print("PASS: original v568 PlayerShip367 3D vertex bounds, axes, "
          "original 100%-baseline craft transform, 0.714 preprocessing")
    print("LIMIT: the 70–150% user mission-scale setting and visual "
          "pixel parity are not yet ported or tested")
finally:
    for z in archives:z.close()
