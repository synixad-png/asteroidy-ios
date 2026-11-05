#!/usr/bin/env python3
"""Static source-to-Metal binding for the real v556 GpuIntro41 frustum.

Verifies that the pure Swift projection parameters used by the Metal
renderer carry both original clip planes, after the same normalization
as the source camera and mesh. This is NOT an Apple GPU test.
"""
from pathlib import Path

root = Path(__file__).resolve().parents[1]
sphere = (root / "ASTEROIDYiOS/Sphere67.swift").read_text()
renderer = (root / "ASTEROIDYiOS/MetalRenderer.swift").read_text()

def check(predicate, explanation):
    if not predicate:
        raise AssertionError(explanation)

source = sphere.split("enum SphereProjection556 {",1)[1].split(
    "struct SphereCameraView556 {",1)[0]
for item in (
    "static let sourceHalfHeight: Float = 0.2",
    "static let sourceNear: Float = 0.4",
    "static let sourceFar: Float = 1600",
    "static let sourceVerticalFocal: Float = sourceNear/sourceHalfHeight",
    "sourceNear / SphereCameraView556.originalPlanetOuterRadius",
    "sourceFar / SphereCameraView556.originalPlanetOuterRadius",
    "static func clipPlanes(spherical: Bool)",
    "spherical ? (normalizedNear, normalizedFar) : (0.1, 20)",
):
    check(item in source, "v556 GpuIntro41 original sphere projection changed: " + item)

camera = sphere.split("struct SphereCameraView556 {",1)[1].split(
    "struct SphereSkyStar207 {",1)[0]
check("originalPlanetOuterRadius: Float = 100 * 1.4419674" in camera,
      "Sphere normalization radius differs from source GpuPlanetGltf463")
check("originalCameraRadius: Float = 310" in camera,
      "GpuSphere67 source orbit radius changed")
check("originalCameraRadius / originalPlanetOuterRadius" in camera,
      "Camera and perspective are not sharing the original normalization")

perspective = renderer.split("private static func perspective(",1)[1].split(
    "private static func sphereView(",1)[0]
check("SphereProjection556.clipPlanes(spherical:spherical)" in perspective,
      "Metal perspective ignores the source-normalized near/far planes")
check("let near = clip.near, far = clip.far" in perspective,
      "Metal depth matrix no longer uses original source clip boundaries")
check("far/(near-far)" in perspective and
      "near*far/(near-far)" in perspective,
      "Metal perspective depth matrix coefficients changed")
check("SphereProjection556.sourceVerticalFocal" in perspective,
      "Original 53.13-degree sphere FOV was lost")
check("let near: Float = 0.1, far: Float = 20" not in perspective,
      "Old flat camera depth planes accidentally applied to sphere")
check("aspect,spherical:input.planetPreview || input.introPreview41" in renderer,
      "The actual three-way intro/sphere/flat selection no longer reaches Metal")
check("cameraFrame=Self.introView41(introTime41)" in renderer and
      "cameraFrame=Self.sphereView(sphereFlight.camera)" in renderer and
      "cameraFrame=(view:Self.translation(0,0,-4)" in renderer,
      "The three independent original camera paths no longer reach Metal")
print("PASS: v556 GpuIntro41 frustum 0.4..1600, unit-radius clip conversion,")
print("      original 53.13-degree sphere FOV, independent 0.1..20 flat arena,")
print("      source camera-to-Boreas normalization and Metal depth binding")
print("LIMITATION: static source verification; Apple GPU not executed")
