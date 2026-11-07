#!/usr/bin/env python3
"""Regress only the actual playable Carbonis renderer camera VP."""
from pathlib import Path
root=Path(__file__).resolve().parents[1]
r=(root/"ASTEROIDYiOS/Sector01CarbonisPreview568.swift").read_text()
model=(root/"ASTEROIDYiOS/MissionViewportFraming568.swift").read_text()
assert "let focal=SphereProjection556.sourceVerticalFocal" in r
assert r.count("MissionViewportFraming568.focals(")==1
block=r.split("static func viewProjection(",1)[1].split(
    "static func craftModel(",1)[0]
assert "MissionViewportFraming568.focals(" in block
assert "SIMD4<Float>(fitted.horizontal,0,0,0)" in block
assert "SIMD4<Float>(0,fitted.vertical,0,0)" in block
assert "Self.viewProjection($0.game.flight.camera,aspect:aspect)" in r
assert "var capMVP=vp.map{$0*atmosphereModel}" in r
assert "uniforms=Uniforms(mvp:vp.map{$0*terrainModel}" in r
assert "missionTerrainScale523" in r
assert "previewMVP(_ aspect" in r
assert r.split("static func previewMVP(",1)[1].split(
    "static func sourceRockModel(",1)[0].count("MissionViewportFraming568")==0
assert "sourceWidth:Float=1280" in model
assert "sourceHeight:Float=720" in model
assert "let scale=min(1,a/sourceAspect)" in model
print("PASS source 16:9 aspect-aware iPad projection shared by planet and Atmosphere47")
print("PASS unchanged iPhone>=16:9 source vertical FOV, game geometry, atlas preview")
