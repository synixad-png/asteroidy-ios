#!/usr/bin/env python3
"""Protect genuine 3D DrawAtmosphere47 and its painter/depth semantics.

The source is Windows/src/GpuPlanet.cs:9-36 and PlanetBiomes.cs:12
(level 5 Boreas glow 0x95DBFF), with Windows GpuIntro41.cs:494 placing
the atmosphere AFTER the fighter. A source contract does not prove
native Apple Metal compilation or physical iPhone/iPad visuals.
"""
from pathlib import Path

root=Path(__file__).resolve().parents[1]
source=(root/'ASTEROIDYiOS/IntroAtmosphere47.swift').read_text()
renderer=(root/'ASTEROIDYiOS/MetalRenderer.swift').read_text()
shader=(root/'ASTEROIDYiOS/Ship.metal').read_text()
project=(root/'project.yml').read_text()

def check(ok,msg):
    if not ok:raise AssertionError(msg)

for token in (
    'static let rings = 24',
    'static let segments = 96',
    'static let outerRadius: Float = 1.34',
    'static let red: Float = 149.0/255.0',
    'static let green: Float = 219.0/255.0',
    'static let blue: Float = 255.0/255.0',
    'let limb = (r-1.055)/0.125',
    'let shell: Float = 0.058+0.33*exp(-limb*limb)',
    'let edge = max(0,min(1,(outerRadius-r)/0.18))',
    'return shell*edge*edge*(3-2*edge)',
    'let depth = sqrt(max(0,outerRadius*outerRadius-r*r))',
    'let up=abs(z.y)<0.95 ? V(x:0,y:1,z:0) : V(x:1,y:0,z:0)',
    'let x=V.cross(up,z).normalized',
    'return (x,V.cross(z,x).normalized,z)',
    'vertices.reserveCapacity(rings*segments*6)',
    'indices.reserveCapacity(rings*segments*6)',
    'append(r,a);append(s,a);append(s,next)',
    'append(r,a);append(s,next);append(r,next)',
):
    check(token in source,'Original atmosphere formula changed: '+token)

for token in (
    'let atmospherePipeline: MTLRenderPipelineState',
    'let atmosphereDepthState: MTLDepthStencilState',
    'private let atmosphereMesh: GPUModel',
    'atmosphereBlend.sourceRGBBlendFactor = .sourceAlpha',
    'atmosphereBlend.destinationRGBBlendFactor = .oneMinusSourceAlpha',
    'atmosphereDesc.vertexFunction=sceneVertex',
    'atmosphereDesc.fragmentFunction=sceneFragment',
    'atmoDepth.depthCompareFunction = .less',
    'atmoDepth.isDepthWriteEnabled = false',
    'atmosphereMesh=try Self.makeMesh(',
):
    check(token in renderer,'Original 3D atmosphere GPU state missing: '+token)

cinematic=renderer.split(
    '        if input.introPreview41 {\n            // The source Windows GpuIntro41.CinematicIntro41',1)[1].split(
    '\n        if input.planetPreview {\n            // Original GpuIntro41.DrawDeepSpace55',1)[0]
for token in (
    'let atmoAxes=IntroAtmosphere47.basis(',
    'center:IntroOrbit41.planetCenter,',
    'eye:IntroOrbit41.frame(introTime41).eye)',
    'let atmoScale=IntroOrbit41.introPlanetScale',
    'encoder.setRenderPipelineState(atmospherePipeline)',
    'encoder.setDepthStencilState(atmosphereDepthState)',
    'drawMesh(atmosphereMesh,atmoModel,unlit:1)',
):
    check(token in cinematic,'IntroAtmosphere47 not linked into the real Metal scene: '+token)
stages=['drawMesh(mesh,planetModel)',
        'drawMesh(shipMesh,craft)',
        'encoder.setRenderPipelineState(atmospherePipeline)',
        'drawMesh(atmosphereMesh,atmoModel,unlit:1)',
        'encoder.endEncoding()']
positions=[cinematic.index(t) for t in stages]
check(positions==sorted(positions) and len(set(positions))==len(positions),
      'Source GpuIntro41 must draw atmosphere after planet and craft, before presentation')
# Shared no-write depth state is also used by the NEW additive engine
# flames before the atmosphere. Its first occurrence is therefore
# legitimately before the atmosphere pipeline. The atmosphere-specific
# depth binding must still come AFTER selecting atmospherePipeline.
atmosphere_stage=cinematic[cinematic.index(
    'encoder.setRenderPipelineState(atmospherePipeline)'):]
check(atmosphere_stage.index('encoder.setDepthStencilState(atmosphereDepthState)') <
      atmosphere_stage.index('drawMesh(atmosphereMesh,atmoModel,unlit:1)'),
      'Atmosphere must depth-test without writing AFTER plasma rendering')
check('if (in.unlit > 0.5) return in.color;' in shader,
      'Atmosphere must preserve original unlit source RGBA, not opaque PBR')
sphere=renderer.split(
    '\n        if input.planetPreview {\n            // Original GpuIntro41.DrawDeepSpace55',1)[1]
check('uploadBoreasMorphIfNeeded(seconds:planetAnimationTime)' in sphere,
      'Boreas combat morph must remain untouched')
check("TARGETED_DEVICE_FAMILY: '1,2'" in project,
      'Physical iPhone and iPad support must remain')
print('PASS: GpuPlanet.cs translucent 3D atmosphere with original')
print('      level-5 tint, radial haze, depth testing and alpha blend;')
print('      source painter order planet -> Vanguard -> atmosphere')
print('LIMIT: source contract; not Metal GPU execution or physical device test')
