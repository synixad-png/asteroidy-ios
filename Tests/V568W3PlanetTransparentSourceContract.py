#!/usr/bin/env python3
"""Exact-source regression: GPU HOME globe has a transparent viewport.

Audited SHA-256 from unmodified user ASTEROIDY v568 archive:
 Windows/src/GpuW3HomeReal333.cs
  839f1bd3ac42632d72208671ae336859144e0ef0564365dedb241d68e3d5a065
 Windows/src/RendererW3Home328.cs
  a696603703583df5e4363106389833d6fd9aaa59fd6b73fa5e1aec3f71f4a966

The renderer's DrawHomePlanetBackdrop333 helper is a GDI-only fallback.
The actual source c.IsGpu branch uses ONLY HomePlanetPreview333, which
clears DEPTH and renders DrawNewHome290 on the existing image backdrop.
No simulator screenshot or physical GPU parity is claimed here.
"""
from pathlib import Path
root=Path(__file__).resolve().parents[1]
menu=(root/"ASTEROIDYiOS/W3MainMenu568.swift").read_text()
metal=(root/"ASTEROIDYiOS/W3HomePlanetMetal568.swift").read_text()
shader=(root/"ASTEROIDYiOS/W3HomePlanet290.metal").read_text()
assert "SourceW3Images568.pair" in menu, "shared original W3 image missing"
assert "Image(uiImage:images.background)" in menu, "original W3 backdrop missing"
a=menu.split("private func radar(compact:Bool)",1)[1].split(
    "private var telemetry: some View",1)[0]
assert a.count("W3HomePlanetMetal568(yaw:planetYaw,pitch:planetPitch)")==1
assert ".frame(width:diameter,height:diameter)" in a
assert ".gesture(DragGesture(minimumDistance:0)" in a
assert "planetYaw=planetDragYaw+dx*0.006" in a
assert "planetPitch=min(1.05,max(-1.05," in a
for unwanted in (
    "RoundedRectangle(", "Ellipse(", "Rectangle(", ".stroke(",
    ".fill(", "Text(", "ForEach(", "RADAR / SYSTEM NAWIGACJI",
    "ORYGINALNA PLANETA NEWHOME290 / 3D METAL",
    "W3 v568", "Circle().fill(", "LinearGradient(",
):
    assert unwanted not in a,"GPU planet viewport has invented art: "+unwanted
assert "view.isOpaque=false" in metal
assert "view.layer.isOpaque=false" in metal
assert "view.backgroundColor = .clear" in metal
assert "view.layer.backgroundColor = UIColor.clear.cgColor" in metal
assert "view.clearColor=MTLClearColor(red:0,green:0,blue:0,alpha:0)" in metal
assert "pass.colorAttachments[0].loadAction = .clear" in metal
assert "pass.colorAttachments[0].clearColor =" in metal
assert "MTLClearColor(red:0,green:0,blue:0,alpha:0)" in metal
assert "encoder.drawPrimitives(type:.triangle,vertexStart:0,vertexCount:514_176)" in metal
assert "encoder.drawPrimitives(type:.triangle,vertexStart:514_176,vertexCount:2_448)" in metal
assert "float4(clamp(ink,0.0f,1.0f),clamp(base.a,0.0f,1.0f))" in shader
print("PASS original v568 GPU HOME globe only, transparent background, preserved rotation and mesh")
print("PASS GDI fallback rings never leak into native Metal W3 screen")
