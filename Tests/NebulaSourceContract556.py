#!/usr/bin/env python3
"""Task2 static source wiring check for ORIGINAL GpuCosmos39 256px clouds.

This checks the Swift source and Metal shader contracts; Swift/Linux
source formulas are exercised by SphereNebula556Tests.swift. Neither
is a real Apple Metal compiler nor proof of appearance on iPhone.
"""
from pathlib import Path
r=Path(__file__).resolve().parents[1]
model=(r/"ASTEROIDYiOS/Sphere67.swift").read_text()
render=(r/"ASTEROIDYiOS/MetalRenderer.swift").read_text()
factory=(r/"ASTEROIDYiOS/SourceSkyAssetFactory568.swift").read_text()
blend=(r/"ASTEROIDYiOS/SourceSkyPremultipliedBlend.swift").read_text()
shader=(r/"ASTEROIDYiOS/Ship.metal").read_text()
for factor in (
    "attachment.isBlendingEnabled=true",
    "attachment.sourceRGBBlendFactor = .one",
    "attachment.destinationRGBBlendFactor = .oneMinusSourceAlpha",
    "attachment.sourceAlphaBlendFactor = .one",
    "attachment.destinationAlphaBlendFactor = .oneMinusSourceAlpha",
):
    assert factor in blend, "Original GpuIntro41 source PArgb blend changed: "+factor

def check(c,message):
    if not c:
        raise AssertionError(message)

for t in (
    "static let imageSize = 256",
    "static let orbitLayerCount = 36",
    "static let orbitThemeCount = 2",
    "x) &* 374761393", "y) &* 668265263",
    "seed) &* 144269",
    "n=(n ^ (n >> 13)) &* 1274126177",
    "frequency *= 2.05", "weight *= 0.48",
    "let warp=noise(nx*3,ny*3,theme+5)*2-1",
    "let alpha=max(0,min(190,Int(edge*ribbon*cloud*220)))",
    "UInt8(blue*alpha/255)",
    "static func textureBGRA(theme:Int)",
    "if index<24",
    "theme:index%2", "alpha:37/255,near:false",
    "let i=index-24", "theme:i%2",
    "alpha:140/255,near:true",
    "let size=min(650,720*190/depth)",
    "let size=720*220/depth",
):
    check(t in model,"C# GpuCosmos39/IntroSky source contract: "+t)

for t in (
    "private let nebulaOverlayMesh: GPUModel",
    "private var nebulaTexture: MTLTexture?",
    "let nebulaVertex=try requireShader(\"nebulaOverlayVertex\")",
    "let nebulaFragment=try requireShader(\"nebulaOverlayFragment\")",
    "nebulaDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm",
    "try SourceSkyPremultipliedBlend.configure(nebulaDescriptor)",
    "nebulaOverlayPipeline=try device.makeRenderPipelineState(",
    "let cloudData=SourceSkyAssetFactory568.nebulaSource556()",
    "nebulaOverlayMesh=try Self.makeMesh(device,cloudData.0,cloudData.1)",
    "let created=try SourceSkyAssetFactory568.makeNebulaTextures556(device)",
    "private var nebulaSliceCache55 = SkyTextureSliceCache55(count: SphereNebula556.orbitThemeCount)",
    "let visibleThemes=Set(Self.sourceCloudLayers55.compactMap",
    "guard nebulaLoadGate.shouldAllocate(visible:!visibleThemes.isEmpty)",
    "where visibleThemes.contains(theme)",
    "nebulaSliceCache55.needsUpload(style:theme)",
    "nebulaSliceCache55.markUploaded(style:theme)",
    "SourceSkyAssetFactory568.uploadNebulaSlice556(texture,theme:theme)",
    "encoder.setVertexBuffer(",
    "nebulaOverlayMesh.vertices,offset:0,index:0)",
    "encoder.setFragmentTexture(clouds,index:0)",
    "vertexCount:24*6",
    "vertexStart:24*6,vertexCount:12*6",
    "encoder.setDepthStencilState(depthState)",
    "encoder.setRenderPipelineState(pipeline)",
):
    check(t in render,"C# nebula Metal pipeline wiring missing: "+t)
for token in (
    "static func makeNebulaTextures556(_ device:MTLDevice)",
    "d.textureType = .type2DArray",
    "d.arrayLength = SphereNebula556.orbitThemeCount",
    "bytesPerRow:n*4,bytesPerImage:n*n*4",
    "static func uploadNebulaSlice556(",
    "let texels=SphereNebula556.textureBGRA(theme:theme)",
    "vertices.reserveCapacity(SphereNebula556.orbitLayerCount*6)",
):
    check(token in factory,"Shared source nebula texture builder changed: "+token)
# The source sphere pipeline must preserve its own painter order.
# The separate orbital IntroScene41 scene deliberately draws its stars
# earlier; checking the first skyPoint occurrence across both scenes
# would be a false cross-scene regression.
sphere_render=render.split(
    "if input.planetPreview {\n            // Original GpuIntro41.DrawDeepSpace55",1)[1]
check(sphere_render.index("encoder.setRenderPipelineState(nebulaOverlayPipeline)") <
      sphere_render.index("encoder.setRenderPipelineState(skyPointPipeline)") <
      sphere_render.index("encoder.setRenderPipelineState(solarOverlayPipeline)"),
      "IntroSky must draw source clouds before stars and solar rays")
check(sphere_render.count("encoder.setRenderPipelineState(nebulaOverlayPipeline)")==2,
      "Source draws 24 far clouds before deep objects and 12 near clouds afterward")
check(sphere_render.index("vertexCount:24*6") <
      sphere_render.index("encoder.setRenderPipelineState(blackHolePipeline)") <
      sphere_render.index("vertexStart:24*6,vertexCount:12*6") <
      sphere_render.index("encoder.setRenderPipelineState(skyPointPipeline)"),
      "Original DrawDeepSpace55 / IntroSky far-deep-near-stars order must survive")
check("if input.planetPreview {" in render,
      "Cloud pipeline must not change independent flat sandbox")

for t in (
    "vertex NebulaOverlayRaster nebulaOverlayVertex(",
    "fragment float4 nebulaOverlayFragment(",
    "texture2d_array<float> sourceClouds [[texture(0)]]",
    "float depth=-dot(camera.back.xyz,d)",
    "float sourceX=dot(camera.right.xyz,d)*720.0f/max(0.01f,depth)",
    "float sourceY=-dot(camera.up.xyz,d)*720.0f/max(0.01f,depth)",
    "float size=nearLayer",
    "720.0f*220.0f/depth",
    "min(650.0f,720.0f*190.0f/depth)",
    "filter::linear",
    "uint slice=uint(in.theme+0.5f)",
    "return in.color * sourceClouds.sample(sourceSampler,in.uv,slice);",
):
    check(t in shader,"GpuCosmos39 cloud Metal shader contract: "+t)
print("PASS: v556 GpuCosmos39 two 256px PArgb textures,")
print("      source GpuIntro41 24+12 layers, GPU SkyProject55,")
print("      two correctly ordered draws, one shared 2D array, premultiplied alpha")
print("LIMITATION: static contract only, native Apple GPU unverified")
