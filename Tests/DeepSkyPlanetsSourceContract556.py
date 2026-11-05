#!/usr/bin/env python3
"""Static real-source wiring audit for GpuIntro41 BuildDeepPlanet55.

This checks original style profiles, source body formulas and the
reused premultiplied Metal quad rendering pipeline. It does not
pretend to emulate bit-identical Windows GDI+ antialiasing, compile
Apple Metal, or test an iPhone.
"""
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
source=(ROOT/"ASTEROIDYiOS"/"DeepSkyPlanets55.swift").read_text()
renderer=(ROOT/"ASTEROIDYiOS"/"MetalRenderer.swift").read_text()
shader=(ROOT/"ASTEROIDYiOS"/"Ship.metal").read_text()
def ck(value,message):
    if not value: raise AssertionError(message)

for term in (
    "static let textureWidth=320",
    "static let textureHeight=220",
    "static let count=3",
    "x:p.base.x+sin(t)*p.amplitudeX",
    "cos(t*0.83+p.phase*0.6)*p.amplitudeY",
    "sin(t*0.57+p.phase*0.3)*p.amplitudeX*0.4",
    "halfWidth:148,halfHeight:96,maxScale:2.05",
    "halfWidth:176,halfHeight:116,maxScale:2.25",
    "halfWidth:166,halfHeight:108,maxScale:2.18",
    "glow:(255,208,140,28)",
    "glow:(120,196,255,44)",
    "glow:(255,142,116,34)",
    "let screenX=640+SphereVector3.dot(frame.right,world)*720",
    "guard screenX > -260 && screenX < 1540",
    "screenY > -170 && screenY < 900",
    "scale:min(profile(style).maxScale,900/depth)",
    "let nx=(Float(x)-160)/88",
    "let ny=(Float(y)-110)/88",
    "let opacity=Float(min(255,Int((1-rad)*3900)))/255",
    "let lightDot=(-nx*cfg.light.0-ny*cfg.light.1+z*cfg.light.2)",
    "let lit:Float=0.10+0.90*max(0,lightDot)",
    "let storm:Float=0.06*sin(nx*12-ny*8)",
    "let dust:Float=0.80+0.10*sin((nx-ny)*cfg.freq)",
    "radius*0.54*scale",
    "textureSlice:-1",
    "textureSlice:style",
    "textureBGRA(style:Int)",
    "func strokeCoverage(",
    "static func arcIncluded(",
):
    # In the source DrawSkyPlanet uses max(width,height)*.54f*scale
    # rather than a standalone radius variable. Test that separately.
    if term=="radius*0.54*scale":
        continue
    ck(term in source,"Original GpuIntro41 planet source changed: "+term)
ck("max(p.halfWidth,p.halfHeight)*0.54*scale" in source,
   "Original DrawSkyPlanet55 glow radius missing")
ck("Bitmap.SetPixel" in source and "GDI+ edge pixels are APPROXIMATIONS" in source,
   "GDI pen antialias cannot be asserted bit-identical")
ck("DrawEllipse" in source and "DrawArc" in source,
   "Source order behind body/front rings+glints missing")

for term in (
    "private var deepPlanetTextures: MTLTexture?",
    "let created=try Self.makeDeepPlanetTextures55(device)",
    "makeDeepPlanetTextures55(_ device:MTLDevice)",
    "d.textureType = .type2DArray",
    "d.arrayLength = DeepSkyPlanets55.count",
    "pixelFormat:.bgra8Unorm,width:w,height:h,mipmapped:false",
    "private static func uploadDeepPlanetSlice55(",
    "private var deepPlanetSliceCache55 = SkyTextureSliceCache55(count: DeepSkyPlanets55.count)",
    "if deepPlanetSliceCache55.needsUpload(style:style)",
    "deepPlanetSliceCache55.markUploaded(style:style)",
    "guard let planets=ensureDeepPlanetTextures55(style:style)",
    "let img=DeepSkyPlanets55.textureBGRA(style:style)",
    "bytesPerRow:w*4",
    "for style in 0..<DeepSkyPlanets55.count",
    "guard let projected=DeepSkyPlanets55.project(",
    "let layers=DeepSkyPlanets55.overlays(",
    "encoder.setFragmentTexture(planets,index:0)",
    "encoder.setFragmentTexture(sphereHaloTexture,index:1)",
    "encoder.drawPrimitives(type:.triangle,",
    "vertexStart:0,vertexCount:layers.count*6",
    "encoder.setRenderPipelineState(blackHolePipeline)",
    "encoder.setFragmentTexture(blackTextures,index:0)",
):
    ck(term in renderer,"Three source DeepPlanet55 textures/draw missing: "+term)
ck("vertex BlackHoleRaster55 blackHoleVertex55(" in shader and
   "fragment float4 blackHoleFragment55(" in shader,
   "Reuse existing premultiplied generic 2D shader, no duplicate pipeline")
far=renderer.index("vertexCount:24*6")
planets=renderer.index("for style in 0..<DeepSkyPlanets55.count",
                       renderer.index("vertexCount:24*6"))
hole=renderer.index("if let blackProjection=BlackHoleSky55.project")
near=renderer.index("vertexStart:24*6,vertexCount:12*6")
ck(far<planets<hole<near,
   "Original source painter order 24 far clouds→planets0,1,2→blackhole→12 near")
ck("blackBlend.sourceRGBBlendFactor = .one" in renderer and
   "blackBlend.destinationRGBBlendFactor = .oneMinusSourceAlpha" in renderer,
   "Source PArgb blending removed")
print("PASS: GpuIntro41 source 3x320x220 planet themes & real RGB formulas,")
print("      3 AnimatedSkyDirection profiles, glow→textured quad order,")
print("      one 3-slice array, individual visible-style uploads, reused Metal quad")
print("LIMITATION: GDI+ strokes approximated, native Apple Metal GPU unverified")
