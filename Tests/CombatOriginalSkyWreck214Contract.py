#!/usr/bin/env python3
"""Source-specific C279 combat background regression, PC v568 oracle.
Windows/src/GpuSphere67.cs:385-425, GpuIntro41.cs:122-127,
333-415, 451-456; GpuAmbient37.cs SpaceHash207/SpaceRand207.
"""
from pathlib import Path
root=Path(__file__).resolve().parents[1]
def read(p):return (root/p).read_text(encoding='utf-8')
sector=read("ASTEROIDYiOS/Sector01CarbonisPreview568.swift")
sky=read("ASTEROIDYiOS/SourceCombatSky568.swift")
shared=read("ASTEROIDYiOS/SourceSkyAssetFactory568.swift")
wreck=read("ASTEROIDYiOS/SourceCombatWreck214.swift")
geometry=read("ASTEROIDYiOS/ResearchWreckGeometry214.swift")
shader=read("ASTEROIDYiOS/Sector01Carbonis568.metal")
intro=read("ASTEROIDYiOS/DeepSkyPlanets55.swift")
for token in (
    'SourceCombatSky568(device:device)',
    'SourceCombatWreck214(device:device,sector:1)',
    'if let session=gameSession,let sourceVP=vp {',
    'sourceSky568?.draw(',
    'sourceWreck214?.draw(',
    'planetAtmospherePipeline',
    'encoder.drawIndexedPrimitives(type:.triangle,indexCount:803712',
    'if let session=gameSession,let cameraMatrix=vp {',
):
    assert token in sector,token
# Original GpuSphere67 source draw ordering: sky -> actual C279 -> wreck
# -> rocks/shots/ship; never render wreck as gameplay collider.
assert sector.index('sourceSky568?.draw(')<sector.index(
    'encoder.drawIndexedPrimitives(type:.triangle,indexCount:803712')
assert sector.index('encoder.drawIndexedPrimitives(type:.triangle,indexCount:803712')<sector.index(
    'sourceWreck214?.draw(')<sector.index('for rock in activeRocks')
assert 'SourceCombatSky568(device:device)' in sector
assert 'sourceSky568=try gameSession != nil' in sector
assert 'sourceWreck214=try gameSession != nil' in sector
painter=[
    'vertexCount:24*6',
    'for style in 0..<DeepSkyPlanets55.count',
    'if let blackProjection=BlackHoleSky55.project(',
    'vertexStart:24*6,vertexCount:12*6',
    'encoder.setRenderPipelineState(skyPointPipeline)',
    'if rays,let sun=SphereSolarOverlay556.project(',
]
pos=[sky.index(x) for x in painter]
assert pos==sorted(pos),painter
assert 'let c=camera' in sky
assert 'let basis=SphereCameraView556(camera:camera)' in sky
assert 'let sourceCloudTexture=nebula ? ensureCloudTextures55(camera:c)' in sky
assert 'glow:glow' in sky
assert 'SourceSkyAssetFactory568.sphereSky207()' in sky
assert 'SphereSky207.count*2' in shared
assert 'SphereNebula556.orbitLayerCount*6' in sky
assert 'style:0,base:SphereVector3(x:0.94,y:0.02,z:-0.34)' in intro
assert 'style:1,base:SphereVector3(x:0.18,y:-0.62,z:-0.76)' in intro
assert 'style:2,base:SphereVector3(x:-0.78,y:0.42,z:-0.46)' in intro
# Wreck214 original is a WORLD model hundreds of units distant,
# anchored to the ringed planet sky direction (-.7,.22,-.68).
for token in (
    'V(x:-0.7,y:0.22,z:-0.68).normalized',
    'ringSky221*(900*inv)',
    'basis.right*(80*inv)',
    'basis.up*(52*inv)',
    'if ringDepth<=0.4 {return}',
    'sx < -150 || sx > 1430 || sy < -110 || sy > 830',
    '* frame * Self.rotateZ(-11) * Self.rotateY(24)',
    '* Self.rotateX(26) * scale',
    'let size=2.20*inv',
    'ResearchWreckGeometry214.make(sector:sector)',
    'combatWreckTriangleVertex214',
    'combatWreckLineVertex214',
):
    assert token in wreck,token
for token in (
    'let debris=112',
    'drawSourceWreck214(seed:sector+214)',
    'box(19.2,cos(angle)*3.9,sin(angle)*3.5,',
    'panelGrid(-46,0,0,1.8,17.5,13,1,5',
    'spaceHash207',
    'spaceRand207',
    'warningLamp(-28.5,4.2,5,orange:false,phase:0)',
    'warningLamp(9,-4.1,8.4,orange:true,phase:4.9)',
):
    assert token in geometry,token
assert 'float pulse=0.5f+0.5f*sin(u.sunAndTime.w*4.8f+in.phase);' in shader
assert 'u.mvp*float4(' in shader
print("PASS original GpuSphere67 deep-space painter order/3 distant planets")
print("PASS authentic level-1 research wreck position/model/112 fragments")
print("LIMIT: fixed-pipeline lighting equivalence and physical GPU visuals not proven")
