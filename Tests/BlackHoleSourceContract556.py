#!/usr/bin/env python3
"""STATIC source-contract check for C# GpuIntro41 v556 black hole.

The original paints:
- exactly 3 StarTexture glows (if GlowEnabled)
- exactly 4 spinning rays using StarTexture
- rear accretion disk, event horizon CORE, front accretion disk
in that painter order. The original disk textures are generated
from 640x640 per-pixel source algorithms. This script does not
compile Metal or claim visual equality on an Apple GPU.
"""
from pathlib import Path
r=Path(__file__).resolve().parents[1]
model=(r/"ASTEROIDYiOS/BlackHoleSky55.swift").read_text()
metal=(r/"ASTEROIDYiOS/Ship.metal").read_text()
render=(r/"ASTEROIDYiOS/MetalRenderer.swift").read_text()
def check(condition,msg):
    if not condition: raise AssertionError(msg)
for token in (
    "static let imageSize=640",
    "static let sourceRadius:Float=258",
    "static let maxScale:Float=3.10",
    "static func diskPixel(x:Int,y:Int,front:Bool)",
    "static func corePixel(x:Int,y:Int)",
    "static func textureBGRA(slice:Int)",
    "let ca:Float=0.9063078,sa:Float=0.4226183",
    "let layerMask=front",
    "let rearGap=front ? Float(1) : smooth((r-76)/10)",
    "let core=1-smooth((r-69)/4)",
    "let rim=gaussian((r-80)/6)",
    "let rimBlue=gaussian((r-86)/10)",
    "slice==1",
    "front:slice==2",
    "static func animatedDirection(time:Float)",
    "let t=time*0.05+2.4",
    "guard x > -260 && x < 1540 && y > -180 && y < 920",
    "scale:min(maxScale,originalSkyDistance/depth)",
    "halo(sourceRadius*2.0,42,120,186,255)",
    "halo(sourceRadius*1.54,62,255,164,84)",
    "halo(sourceRadius*1.10,28,255,242,225)",
    "ray(spin,sourceRadius*2.10*scale*pulse",
    "let secondRayLength=sourceRadius*1.74*scale*(0.95+0.05*cos(time*0.8))",
    "ray(spin+1.5708,secondRayLength",
    "ray(spin+0.66,sourceRadius*1.48*scale",
    "ray(spin+2.20,sourceRadius*1.34*scale",
    "for layer in 0..<3",
    "isTexture:true,layer:layer",
):
    check(token in model,"Original BuildBlackHole/DrawSkyBlackHole source changed: "+token)
for token in (
    "private let blackHoleTextures: MTLTexture",
    "let blackHoleVertex=try requireShader(\"blackHoleVertex55\")",
    "let blackHoleFragment=try requireShader(\"blackHoleFragment55\")",
    "blackHolePipeline=try device.makeRenderPipelineState(",
    "desc.textureType = .type2DArray",
    "desc.arrayLength = 3",
    "pixelFormat:.bgra8Unorm,width:n,height:n,mipmapped:false",
    "let image=BlackHoleSky55.textureBGRA(slice:slice)",
    "bytesPerRow:n*4",
    "blackHoleTextures=try Self.makeBlackHoleTextures55(device)",
    "BlackHoleSky55.project(",
    "let layers=BlackHoleSky55.overlays(",
    "properties.reserveCapacity(1+layers.count*3)",
    "encoder.setRenderPipelineState(blackHolePipeline)",
    "encoder.setFragmentTexture(blackHoleTextures,index:0)",
    "encoder.setFragmentTexture(sphereHaloTexture,index:1)",
    "vertexCount:layers.count*6",
    "encoder.setRenderPipelineState(nebulaOverlayPipeline)",
    "vertexStart:24*6,vertexCount:12*6",
):
    check(token in render,"Original black-hole Metal draw contract missing: "+token)
check(render.index("vertexCount:24*6") <
      render.index("encoder.setRenderPipelineState(blackHolePipeline)") <
      render.index("vertexStart:24*6,vertexCount:12*6") <
      render.index("encoder.setRenderPipelineState(skyPointPipeline)"),
      "Black hole painter order must be far clouds then rear/core/front, then near clouds")
for token in (
    "vertex BlackHoleRaster55 blackHoleVertex55(",
    "fragment float4 blackHoleFragment55(",
    "texture2d_array<float> diskCoreFront [[texture(0)]]",
    "texture2d<float> originalHalo [[texture(1)]]",
    "float4 frame=data[0]",
    "float4 shape=data[1+layer*3]",
    "float4 color=data[2+layer*3]",
    "float slice=data[3+layer*3].x",
    "diskCoreFront.sample(originalSampler,in.uv,",
    "originalHalo.sample(originalSampler,in.uv)",
    "return sampled*in.color;",
):
    check(token in metal,"BlackHole55 Metal shader contract missing: "+token)
print("PASS: original v556 3x640 PArgb source back/core/front black-hole")
print("      3 glows + 4 rotating rays + 3 layered disks, shared textures,")
print("      premultiplied alpha and corrected deep-space painter order")
print("LIMITATION: static contract, not Apple Metal/GPU compilation")
