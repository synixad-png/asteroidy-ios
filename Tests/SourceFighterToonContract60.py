#!/usr/bin/env python3
"""Check actual Vanguard default draw shader against source C#.

Windows/src/GpuShip.cs:10-16 sets FighterLight key(-.6,.8,1.4,w=0).
Vanguard431 material slot 0 is bound through BeginToon60(true,true).
Windows/src/GpuToon60.cs:29,64,279 uses ToonEnabled60=true by
default, .25/.33/.40 three-step diffuse and .10 view-dependent rim.
Do NOT misrepresent fixed-function two-light GL fallback as the
active default source toon program. Full UV/texture parity is separate.
"""
from pathlib import Path

root=Path(__file__).resolve().parents[1]
cpu=(root/'ASTEROIDYiOS/SourceFighterToon60.swift').read_text()
gpu=(root/'ASTEROIDYiOS/Ship.metal').read_text()
renderer=(root/'ASTEROIDYiOS/MetalRenderer.swift').read_text()
app=(root/'ASTEROIDYiOS/App.swift').read_text()
def ck(ok,msg):
    if not ok:raise AssertionError(msg)

for token in (
    'keyDirection = V(x:-0.6,y:0.8,z:1.4).normalized',
    '0.25',
    '0.33*smoothstep(0.30,0.32,d)',
    '0.40*smoothstep(0.70,0.72,d)',
    '0.10*smoothstep(0.72,0.86,angle)',
    'smoothstep(0.10,0.30,d)',
    'let view=(positionEye * -1).normalized',
    'static func shade(',
):
    ck(token in cpu,'GpuToon60 source CPU oracle changed: '+token)

source_shader=gpu.split('fragment float4 sourceFighterToonFragment60(',1)[1]
for token in (
    'RasterOutput in [[stage_in]]',
    'constant float4x4 &cameraView [[buffer(0)]]',
    '(cameraView*float4(in.normal,0.0f)).xyz',
    'cameraView*float4(in.worldPosition,1.0f)',
    'normalize(float3(-0.6f,0.8f,1.4f))',
    '0.25f+',
    '0.33f*smoothstep(0.30f,0.32f,d)',
    '0.40f*smoothstep(0.70f,0.72f,d)',
    'float3 viewDir=normalize(-eyePosition)',
    'float rim=0.10f*smoothstep(0.72f,0.86f,edge)*',
    'smoothstep(0.10f,0.30f,d)',
    'return float4(clamp(in.color.rgb*(band+rim),0.0f,1.0f),',
):
    ck(token in source_shader,'GpuToon60 source Metal shader missing: '+token)

for token in (
    'let sourceFighterToonPipeline60: MTLRenderPipelineState',
    'try requireShader("sourceFighterToonFragment60")',
    'fighterToonDesc.vertexFunction=sceneVertex',
    'fighterToonDesc.fragmentFunction=fighterToonFragment',
    'sourceFighterToonPipeline60=try device.makeRenderPipelineState(',
):
    ck(token in renderer,'GpuToon60 separate Metal pipeline missing: '+token)
cinematic=renderer.split(
    '        if input.introPreview41 {\n            // The source Windows GpuIntro41.CinematicIntro41',1)[1].split(
    '\n        if input.planetPreview {\n            // Original GpuIntro41.DrawDeepSpace55',1)[0]
stages=(
    'drawMesh(mesh,planetModel)',
    'encoder.setRenderPipelineState(sourceFighterToonPipeline60)',
    'encoder.setFragmentBytes(&fighterEyeView,',
    'drawMesh(shipMesh,craft)',
    'encoder.setRenderPipelineState(fighterPlasmaPipeline491)',
    'encoder.setRenderPipelineState(atmospherePipeline)',
)
indices=[cinematic.index(t) for t in stages]
ck(indices==sorted(indices) and len(set(indices))==len(indices),
   'Original fighter-only toon lighting must wrap ship draw, not planet/plasma/atmosphere')
# This scene legitimately resets the opaque pipeline after IntroSky,
# BEFORE rendering the planet. The *fighter-local* reset must also
# happen after the Vanguard draw and before the separate plasma PSO.
post_ship=cinematic[cinematic.index('drawMesh(shipMesh,craft)'):]
ck(post_ship.index('encoder.setRenderPipelineState(pipeline)') <
   post_ship.index('encoder.setRenderPipelineState(fighterPlasmaPipeline491)'),
   'Default PBR pipeline must be restored before painting the plasma')
ck('var fighterEyeView=cameraFrame.view' in cinematic and
   'length:MemoryLayout<simd_float4x4>.stride,index:0' in cinematic,
   'GpuToon60 real eye-space FighterLight direction must use IntroScene41 view')
ck('drawMesh(shipMesh,shipModel)' in renderer and
   'drawMesh(activeMesh, Self.scale(1.0))' in renderer and
   'drawMesh(mesh,planetModel)' in cinematic,
   'Existing sphere combat and original planet pipeline regressed')
ck('@Published var introPreview41 = true' in app,
   'Source cinematic must remain reachable')
print('PASS: authentic GpuToon60 toon-light bands and camera-based rim')
print('      with real key direction on Vanguard only; sphere PBR untouched')
print('LIMIT: original UV/BaseColor was omitted by AS3D v1 exporter and')
print('       its baked vertex colors are not pixel-identical to PC source')
