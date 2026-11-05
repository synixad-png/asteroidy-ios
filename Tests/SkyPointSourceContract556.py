#!/usr/bin/env python3
"""Task 2 source-contract guards for the iOS sky POINT pipeline.

These are static wiring assertions, NOT Apple Metal compilation and NOT
visual or image-fidelity tests. Original GpuIntro41 source provides
1500 positions, pixel sizes and RGBA values; the 2D IntroHalo texture
has not been ported and must not be claimed as complete.
"""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
swift = (ROOT / "ASTEROIDYiOS" / "MetalRenderer.swift").read_text()
metal = (ROOT / "ASTEROIDYiOS" / "Ship.metal").read_text()
source = (ROOT / "ASTEROIDYiOS" / "Sphere67.swift").read_text()

def check(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)

# This is not a standalone imagined palette: preserve the original
# source star generator already verified by SphereCameraView556Tests.
check("static let count = 1500" in source, "Source GpuIntro41 star count changed")
check("let warm=spaceRand207(41,index,71)>0.9" in source,
      "Original warm/cold color distribution changed")
check("alpha:warm ? 235/255 : 220/255" in source,
      "Source star alpha was discarded")
check("pixelSize:brightness>0.98 ? 2.8" in source,
      "Original screen pixel sizes changed")

# One source-space point -> one vertex. No more per-star 3D triangles.
section = swift.split("private static func sphereSky207()", 1)[1].split(
    "private static func translation(", 1)[0]
check("vertices.reserveCapacity(SphereSky207.count)" in section,
      "Sky reverted to 3x-sized triangle vertices")
check("indices.reserveCapacity(SphereSky207.count)" in section,
      "Sky index count mismatch")
check("indices.append(UInt32(i))" in section,
      "Sky no longer emits one index per source star")
check("star.alpha" in section and "star.pixelSize" in section,
      "Source star alpha or pixel size not passed to GPU")
check("star.red,star.green,star.blue,star.alpha" in section,
      "Original RGBA not forwarded to Metal")
check("drawMesh(sphereSkyMesh" not in swift,
      "Opaque triangle sky draw returned")
check("vertexCount:sphereSkyMesh.count" in swift,
      "Sky no longer draws exactly its 1500 vertices")
check("type:.point" in swift,
      "Sky pipeline no longer uses point primitives")
check("encoder.setRenderPipelineState(skyPointPipeline)" in swift,
      "Missing dedicated blended sky pipeline")
check("encoder.setRenderPipelineState(pipeline)" in swift,
      "Main PBR pipeline not restored after sky")

# Alpha compositing and depth-write isolation prevent sky stars drawing
# over planet geometry or modifying the flat arena.
for code in (
    "blend.isBlendingEnabled = true",
    "blend.sourceRGBBlendFactor = .sourceAlpha",
    "blend.destinationRGBBlendFactor = .oneMinusSourceAlpha",
    "skyDS.isDepthWriteEnabled = false",
    "skyDS.depthCompareFunction = .always",
    "encoder.setDepthStencilState(depthState)",
    "if input.planetPreview {",
):
    check(code in swift, "Metal sky pipeline contract missing: " + code)
check("[[point_size]]" in metal and "[[point_coord]]" in metal,
      "Metal point sprite shader outputs or inputs missing")
check("vertex SkyPointOutput skyPointVertex(" in metal,
      "Source-sized sky point vertex entrypoint missing")
check("fragment float4 skyPointFragment(" in metal,
      "Circular source RGBA sky fragment entrypoint missing")
check("struct SkyPointFragmentInput" in metal and
      "SkyPointFragmentInput in [[stage_in]]" in metal,
      "Fragment stage-in must not carry vertex-only point_size builtin")
fragment_input=metal.split("struct SkyPointFragmentInput",1)[1].split("};",1)[0]
check("[[point_size]]" not in fragment_input,
      "Metal [[point_size]] is invalid as a fragment stage-in field")
check("max(1.0f, star.material.x)" in metal,
      "Source pixel size not respected")
check("in.color.a * coverage" in metal,
      "Source star alpha discarded in blending")
check("drawMesh(starMesh" in swift,
      "Legacy 130-star flat arena removed")
check("private static func stars()" in swift,
      "Legacy 130-star flat generator removed")
print("PASS: source GpuIntro41 1500 RGBA point sprites, Metal alpha blend,")
print("      depth-write isolation, one draw and untouched flat star field")
print("LIMITATION: static contract, not Xcode/Metal compilation or image test")
