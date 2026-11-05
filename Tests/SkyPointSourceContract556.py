#!/usr/bin/env python3
"""Source contract for original ASTEROIDY v556 GpuAmbient37 StarTexture and
GpuIntro41 IntroHalo port. STATIC ONLY: no Apple Metal compiler or GPU.
"""
from pathlib import Path

root=Path(__file__).resolve().parents[1]
swift=(root/"ASTEROIDYiOS"/"MetalRenderer.swift").read_text()
metal=(root/"ASTEROIDYiOS"/"Ship.metal").read_text()
source=(root/"ASTEROIDYiOS"/"Sphere67.swift").read_text()

def ck(ok,why):
    if not ok:
        raise AssertionError(why)

# The only source of sky coordinates/tints is genuine C# GpuIntro41.
for t in (
    "static let count = 1500",
    "let warm=spaceRand207(41,index,71)>0.9",
    "alpha:warm ? 235/255 : 220/255",
    "pixelSize:brightness>0.98 ? 2.8",
    "static let haloTextureSize = 64",
    "let dx=(Double(x)-31.5)/31.5",
    "let dy=(Double(y)-31.5)/31.5",
    "let value=exp(-radius*radius*4)*edge*edge*255",
    "texels[i]=a", "texels[i+1]=a",
    "texels[i+2]=a", "texels[i+3]=a",
    "star.pixelSize*4",
    "star.pixelSize==2.8 ? 42 : 20",
):
    ck(t in source,"Source GpuAmbient37/GpuIntro41 data changed: "+t)

# One actual 64x64 PArgb source glow texture shared by all source stars.
ck("private let sphereHaloTexture: MTLTexture" in swift,
   "Missing real GPU StarTexture")
ck("sphereHaloTexture=try Self.makeSphereHaloTexture(device)" in swift,
   "Source halo GPU texture is not created")
ck("pixelFormat:.bgra8Unorm,width:n,height:n,mipmapped:false" in swift,
   "Source StarTexture pixel format or size changed")
ck("texels.withUnsafeBytes" in swift and "bytesPerRow:n*4" in swift,
   "Original 64x64 BGRA texels not uploaded")
ck("encoder.setFragmentTexture(sphereHaloTexture,index:0)" in swift,
   "StarTexture not bound in sky pass")
ck("texture2d<float> sourceHalo [[texture(0)]]" in metal,
   "Source texture not sampled in MSL")
ck("filter::linear" in metal and "return in.color*mask;" in metal,
   "Texture color/alpha not multiplied as original PArgb")
ck("out.color = float4(star.color.rgb*star.color.a,star.color.a)" in metal,
   "Gpu2DRenderer.Vertex2D premultiplication removed")
for t in (
    "blend.isBlendingEnabled = true",
    "blend.sourceRGBBlendFactor = .one",
    "blend.destinationRGBBlendFactor = .oneMinusSourceAlpha",
    "blend.sourceAlphaBlendFactor = .one",
    "blend.destinationAlphaBlendFactor = .oneMinusSourceAlpha",
    "skyDS.isDepthWriteEnabled = false",
    "skyDS.depthCompareFunction = .always",
    "encoder.setDepthStencilState(depthState)",
    "encoder.setRenderPipelineState(pipeline)",
):
    ck(t in swift,"Source premultiplied blend/depth contract missing: "+t)

sky=swift.split("private static func sphereSky207()",1)[1].split(
    "private static func translation(",1)[0]
for t in (
    "vertices.reserveCapacity(SphereSky207.count*2)",
    "indices.reserveCapacity(SphereSky207.count*2)",
    "indices.append(base)",
    "SphereSky207.hasBrightHalo(star)",
    "SphereSky207.brightHaloDiameterPixels(star)",
    "125/255",
    "SphereSky207.baseDiameterPixels(star)",
    "star.alpha",
):
    ck(t in sky,"Source IntroHalo glow/base layer missing: "+t)
ck(sky.index("appendHalo(SphereSky207.brightHaloDiameterPixels") <
   sky.index("appendHalo(SphereSky207.baseDiameterPixels"),
   "GpuIntro41 draws bright glow BEFORE base, not after")
ck("drawMesh(sphereSkyMesh" not in swift and
   "type:.point,vertexStart:0,vertexCount:sphereSkyMesh.count" in swift,
   "Star quads not represented by one batched point draw")
ck("SphereSky207.drawableScale(" in swift and
   "star.material.x * scene.lighting.x" in metal,
   "Source 720px reference to drawable size mapping missing")
ck("SkyPointFragmentInput in [[stage_in]]" in metal and
   "[[point_coord]]" in metal,"MSL point sprite fragment signature missing")
section=metal.split("struct SkyPointFragmentInput",1)[1].split("};",1)[0]
ck("[[point_size]]" not in section,
   "MSL fragment stage-in must not have vertex-only point_size")
for entry in ("sceneVertex","sceneFragment","skyPointVertex","skyPointFragment"):
    ck(f'try requireShader("{entry}")' in swift,
       "Metal function missing explicit init validation: "+entry)
ck("drawMesh(starMesh" in swift and "private static func stars()" in swift,
   "Legacy flat arena star field removed")
print("PASS: original v556 GpuAmbient37 64x64 BGRA StarTexture and IntroHalo")
print("      bright/base 10/21/2*size radii, premultiplied source blending,")
print("      alpha/depth isolation, one batched point draw, flat arena retained")
print("LIMITATION: static + Swift/Linux tests, Apple GPU not verified")
