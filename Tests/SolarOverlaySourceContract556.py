#!/usr/bin/env python3
"""Static safety regression for original ASTEROIDY v556 solar overlay.

Checks exact draw-path bindings; genuine pixel geometry is tested separately
by Tests/SphereSolarOverlay556Tests.swift. This is NOT Apple Metal compile/GPU.
"""
from pathlib import Path
r=Path(__file__).resolve().parents[1]
swift=(r/"ASTEROIDYiOS"/"MetalRenderer.swift").read_text()
source=(r/"ASTEROIDYiOS"/"Sphere67.swift").read_text()
metal=(r/"ASTEROIDYiOS"/"Ship.metal").read_text()
factory=(r/"ASTEROIDYiOS"/"SourceSkyAssetFactory568.swift").read_text()
blend=(r/"ASTEROIDYiOS"/"SourceSkyPremultipliedBlend.swift").read_text()
for factor in (
    "attachment.pixelFormat = .bgra8Unorm",
    "attachment.isBlendingEnabled=true",
    "attachment.sourceRGBBlendFactor = .one",
    "attachment.destinationRGBBlendFactor = .oneMinusSourceAlpha",
    "attachment.sourceAlphaBlendFactor = .one",
    "attachment.destinationAlphaBlendFactor = .oneMinusSourceAlpha",
):
    assert factor in blend, "Original GpuIntro41 source PArgb blend changed: "+factor

def check(cond,msg):
    if not cond: raise AssertionError(msg)

for token in (
    "static let rayCount = 5",
    "static let columns = 6",
    "static let rows = 4",
    "static let haloVertexCount = 3*6",
    "static let rayVertexCount = rayCount*rows*columns*6",
    "static let totalVertices = haloVertexCount+rayVertexCount",
    "static let rayDistances:[Float] = [0,0.12,0.35,0.72,1]",
    "static let rayStrengths:[Float] = [0,1,0.72,0.31,0]",
    "static let sourceDistance:Float = 900",
    "x > -400 && x < 1680 && y > -400 && y < 1120",
    "Float(Int(18*rayStrengths[row]*fade))",
    "appendHalo(&out,radius:130,red:255,green:199,blue:127,alpha:170)",
    "appendHalo(&out,radius:55,red:255,green:217,blue:164,alpha:220)",
    "appendHalo(&out,radius:15,red:255,green:245,blue:207,alpha:255)",
    "let angle:Float=2.5+(Float(i)-2)*0.17",
    "rayVertex(angle:angle,row:row,column:col)",
    "rayVertex(angle:angle,row:row+1,column:col+1)",
):
    check(token in source, "Original GpuIntro41/GpuCosmos39 source changed: "+token)

for token in (
    "private let solarOverlayMesh: GPUModel",
    "let overlayData=SourceSkyAssetFactory568.solarOverlaySource556()",
    "solarOverlayMesh=try Self.makeMesh(device,overlayData.0,overlayData.1)",
    "let solarVertex=try requireShader(\"solarOverlayVertex\")",
    "let solarFragment=try requireShader(\"solarOverlayFragment\")",
    "solarDescriptor.depthAttachmentPixelFormat = .depth32Float",
    "try SourceSkyPremultipliedBlend.configure(solarDescriptor)",
    "solarOverlayPipeline=try device.makeRenderPipelineState(",
    "if let sun=SphereSolarOverlay556.project(",
    "camera:sphereFlight.camera",
    "var solarUniform=SIMD4<Float>(",
    "encoder.setRenderPipelineState(solarOverlayPipeline)",
    "encoder.setFragmentTexture(sphereHaloTexture,index:0)",
    "vertexCount:solarOverlayMesh.count",
    "encoder.setDepthStencilState(depthState)",
    "encoder.setRenderPipelineState(pipeline)",
):
    check(token in swift, "Metal GpuCosmos39 solar ray pipeline regression: "+token)
check(swift.index("encoder.setRenderPipelineState(skyPointPipeline)") <
      swift.index("encoder.setRenderPipelineState(solarOverlayPipeline)") <
      swift.index("let activeMesh = GPUModel("),
      "GpuIntro41 solar overlay must draw after star field and before planet")
check("type:.triangle,vertexStart:0" in swift,
      "Solar rays should use 738 triangles vertices, not 5 draw calls")

for token in (
    "struct SolarOverlayUniforms { float4 centerScale; };",
    "vertex SolarOverlayRaster solarOverlayVertex(",
    "fragment float4 solarOverlayFragment(",
    "float2 uv;",
    "out.textured=v.material.x;",
    "out.color=float4(v.color.rgb*v.color.a,v.color.a);",
    "float4(v.color.rgb*v.color.a,v.color.a)",
    "return in.color*sourceHalo.sample(originalHalo,in.uv);",
    "filter::linear",
):
    check(token in metal,"Original Gpu2DRenderer premultiplied overlay shader regression: "+token)
for token in (
    "let source=SphereSolarOverlay556.vertices()",
    "vertices.reserveCapacity(source.count)",
    "material:SIMD4<Float>(v.textured ? 1:0,1,0,0)",
):
    check(token in factory, "Shared original solar GPU vertex factory drift: "+token)
check("GlowEnabled" in source, "Source default glow context lost")
check("drawMesh(starMesh" in swift, "Flat arena graphics accidentally removed")
print("PASS: original GpuIntro41 + GpuCosmos39 738 static solar overlays")
print("      camera-projected 1280x720, exact 3 halos, 5 SoftRay fans,")
print("      one shared 64x64 StarTexture and source premultiplied blending")
print("LIMITATION: static contract only; no Apple Metal GPU compilation")
