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
shader=(r/"ASTEROIDYiOS/Ship.metal").read_text()
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
    "nebulaBlend.sourceRGBBlendFactor = .one",
    "nebulaBlend.destinationRGBBlendFactor = .oneMinusSourceAlpha",
    "nebulaOverlayPipeline=try device.makeRenderPipelineState(",
    "d.textureType = .type2DArray",
    "d.arrayLength = SphereNebula556.orbitThemeCount",
    "bytesPerRow:n*4,bytesPerImage:n*n*4",
    "let cloudData=Self.nebulaSource556()",
    "nebulaOverlayMesh=try Self.makeMesh(device,cloudData.0,cloudData.1)",
    "let created=try Self.makeNebulaTextures556(device)",
    "vertices.reserveCapacity(SphereNebula556.orbitLayerCount*6)",
    "encoder.setVertexBuffer(",
    "nebulaOverlayMesh.vertices,offset:0,index:0)",
    "encoder.setFragmentTexture(clouds,index:0)",
    "vertexCount:24*6",
    "vertexStart:24*6,vertexCount:12*6",
    "encoder.setDepthStencilState(depthState)",
    "encoder.setRenderPipelineState(pipeline)",
):
    check(t in render,"C# nebula Metal pipeline wiring missing: "+t)
check(render.index("encoder.setRenderPipelineState(nebulaOverlayPipeline)") <
      render.index("encoder.setRenderPipelineState(skyPointPipeline)") <
      render.index("encoder.setRenderPipelineState(solarOverlayPipeline)"),
      "IntroSky must draw source clouds before stars and solar rays")
check(render.count("encoder.setRenderPipelineState(nebulaOverlayPipeline)")==2,
      "Source draws 24 far clouds before deep objects and 12 near clouds afterward")
check(render.index("vertexCount:24*6") <
      render.index("encoder.setRenderPipelineState(blackHolePipeline)") <
      render.index("vertexStart:24*6,vertexCount:12*6") <
      render.index("encoder.setRenderPipelineState(skyPointPipeline)"),
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
