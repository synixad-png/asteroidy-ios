#!/usr/bin/env python3
"""Protect the real GpuShip.cs v491 two-engine 3D flame in iOS Metal.

Sources of truth:
- Windows/src/GpuShip.cs:19–63 additive plasma triangle equations.
- Windows/src/Vanguard431.cs:15–17 two engine centres from 4311.
- Shared/assets/vanguard431/vanguard431.mesh.gz (IEEE754)
- Windows/src/GpuIntro41.cs:493 calls DrawFighterMesh(time,1,0,false).
This test does NOT prove realtime GPU appearance or original PBR.
"""
from pathlib import Path
root=Path(__file__).resolve().parents[1]
swift=(root/'ASTEROIDYiOS/IntroEnginePlasma491.swift').read_text()
metal=(root/'ASTEROIDYiOS/Ship.metal').read_text()
renderer=(root/'ASTEROIDYiOS/MetalRenderer.swift').read_text()
def check(ok,msg):
    if not ok:raise AssertionError(msg)

for token in (
    'x:-0.44299396872520447,y:-1.5887130498886108',
    'z:-0.1674797236919403',
    'x: 0.44578471779823303,y:-1.5894304513931274',
    'z:-0.18300314247608185',
    'static let visualSize:Float=1.06',
    'static let layers=3',
    'static let planes=3',
    'static let segments=16',
    'static let verticesPerSlice=6',
    'let plume:Float=0.17+thrust*1.47',
    'let off=sin(u*11-time*11+Float(plane)*1.9+src.x*2)',
    'let spread=pow(max(Float(0.035),1-u),0.58)',
    'let fade=alpha*(1-u*u)',
    'position:V(x:src.x+off+sign*dx*width,',
    'y:src.y-plume*u,',
    'z:src.z+sign*dz*width)',
    'return Vertex(',
):
    check(token in swift,'Source CPU oracle changed: '+token)

for token in (
    'vertex FighterPlasmaRaster491 fighterPlasmaVertex491(',
    'fragment float4 fighterPlasmaFragment491(',
    'uint engineIndex=vertexID/(3u*3u*16u*6u);',
    'uint layer=(vertexID/(3u*16u*6u))%3u;',
    'uint plane=(vertexID/(16u*6u))%3u;',
    'uint i=(vertexID/6u)%16u;',
    'uint corner=vertexID%6u;',
    'bool atStart=(corner==0u||corner==1u||corner==4u);',
    'bool positive=(corner==0u||corner==2u||corner==3u);',
    'float plume=0.17f+power*1.47f;',
    'float off=sin(u*11.0f-t*11.0f+float(plane)*1.9f+x*2.0f)',
    'float spread=pow(max(0.035f,1.0f-u),0.58f)',
    'float fade=alpha*(1.0f-u*u)',
    'float3 pos=float3(x+off+side*dx*width,',
    'ey-plume*u,z+side*dz*width);',
    'out.color=float4(1.0f,g,b,fade);',
):
    check(token in metal,'Source GPU procedural exhaust diverged: '+token)

for token in (
    'let fighterPlasmaPipeline491: MTLRenderPipelineState',
    'let fighterPlasmaVertex=try requireShader("fighterPlasmaVertex491")',
    'let fighterPlasmaFragment=try requireShader("fighterPlasmaFragment491")',
    'plasmaBlend.sourceRGBBlendFactor = .sourceAlpha',
    'plasmaBlend.destinationRGBBlendFactor = .one',
    'plasmaBlend.sourceAlphaBlendFactor = .sourceAlpha',
    'plasmaBlend.destinationAlphaBlendFactor = .one',
    'fighterPlasmaPipeline491=try device.makeRenderPipelineState(',
    'encoder.setRenderPipelineState(fighterPlasmaPipeline491)',
    'encoder.setDepthStencilState(atmosphereDepthState)',
    'vertexCount:IntroEnginePlasma491.vertexCount)',
    'IntroEnginePlasma491.engineCenters',
    'IntroEnginePlasma491.visualSize',
):
    check(token in renderer,'Source additive plasma GPU pipeline missing: '+token)

intro=renderer.split(
    '        if input.introPreview41 {\n            // The source Windows GpuIntro41.CinematicIntro41',1)[1].split(
    '\n        if input.planetPreview {\n            // Original GpuIntro41.DrawDeepSpace55',1)[0]
order=[
    'drawMesh(mesh,planetModel)',
    'drawMesh(shipMesh,craft)',
    'encoder.setRenderPipelineState(fighterPlasmaPipeline491)',
    'encoder.setRenderPipelineState(atmospherePipeline)',
    'encoder.endEncoding()',
]
positions=[intro.index(t) for t in order]
check(positions==sorted(positions) and len(set(positions))==len(positions),
      'Original GpuIntro41 painter order: planet -> ship -> engine flames -> atmosphere')
# Several original IntroSky overlays also draw triangles BEFORE the
# fighter. The plasma draw itself must occur AFTER switching to the
# plasma pipeline but BEFORE selecting the atmosphere pipeline.
flame=intro[intro.index(
    'encoder.setRenderPipelineState(fighterPlasmaPipeline491)'):]
check(flame.index('encoder.drawPrimitives(type:.triangle,vertexStart:0,') <
      flame.index('encoder.setRenderPipelineState(atmospherePipeline)'),
      'GpuShip v491 plasma draw missing or executed after atmospheric cap')
check('frame:SIMD4<Float>(introTime41,1,' in intro,
      'Cinematic must use original DrawFighterMesh(time,power=1) source thrust')
check('Self.scale(inv)' in intro and 'let plasmaModel=' in intro,
      'GPU flame has source native engine units, not scaled twice by GLB')
check('planetBufferSlots.reserveWrite()' in renderer,
      'Original sphere GLB morph ring must remain unchanged')
check('drawMesh(shipMesh,shipModel)' in renderer,
      'Original independent sphere combat ship must remain unchanged')
print('PASS: original Windows v491 dual-engine 3D plasma shader,')
print('      actual 4311 nozzle positions, 1728 GPU vertex IDs, original')
print('      additive blend/depth, painter order, and unchanged combat')
print('LIMIT: source contract, not native Xcode/Apple GPU visual proof')
