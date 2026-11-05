#!/usr/bin/env python3
"""Actual 4311 source UV/material pipeline, independent of old AS3D.

This test intentionally requires source mesh + baseColor to be a PAIR;
it does not pretend binary assets are already stored in GitHub.
These bytes are delivered separately, sourced from user's PC v568 ZIP.
"""
from pathlib import Path
r=Path(__file__).resolve().parents[1]
reader=(r/'ASTEROIDYiOS/SourceVanguardMesh431.swift').read_text()
renderer=(r/'ASTEROIDYiOS/MetalRenderer.swift').read_text()
shader=(r/'ASTEROIDYiOS/Ship.metal').read_text()
project=(r/'project.yml').read_text()

def check(test,msg):
    if not test: raise AssertionError(msg)

for token in (
    'static let magic: Int = 4311',
    'static let floatsPerVertex: Int = 12',
    'static let bytesPerVertex: Int = 48',
    'let vertices: Data',
    'let vertexCount: Int',
    'guard Int(try word()) == Self.magic',
    'guard Int(try word()) == 2',
    'floatCount%Self.floatsPerVertex==0',
    'let packed=Data(data[offset..<(offset+byteCount)])',
    'guard offset <= data.count-remaining &&',
):
    check(token in reader,'Actual PC Vanguard431 packet parser changed: '+token)
for token in (
    'vertex FighterSourceRaster431 sourceVanguardVertex431(',
    'constant float *packed [[buffer(0)]]',
    'uint i=vertexID*12u;',
    'float2(packed[i+10u],packed[i+11u])',
    'float3 n=float3(packed[i+3u],packed[i+4u],packed[i+5u])',
    'fragment float4 sourceVanguardTexturedToonFragment431(',
    'texture2d<float> originalBaseColor [[texture(0)]]',
    'originalBaseColor.sample(sourceUV,in.uv)',
    'float4 base=in.color*originalBaseColor.sample(sourceUV,in.uv);',
    '0.33f*smoothstep(0.30f,0.32f,d)',
    '0.40f*smoothstep(0.70f,0.72f,d)',
    'float rim=0.10f*smoothstep(0.72f,0.86f,edge)*',
):
    check(token in shader,'Original PC Vanguard431 GPU UV shader changed: '+token)
for token in (
    'let sourceFighterTexturedPipeline431: MTLRenderPipelineState',
    'private let sourceVanguard431: (buffer:MTLBuffer,count:Int,skin:MTLTexture)?',
    'try requireShader("sourceVanguardVertex431")',
    '"sourceVanguardTexturedToonFragment431"',
    'sourceFighterTexturedPipeline431=try device.makeRenderPipelineState(',
    'forResource:"Vanguard431Source",withExtension:"mesh"',
    'forResource:"Vanguard431Base",withExtension:"jpg"',
    'let native=try SourceVanguardMesh431(',
    'device.makeBuffer(bytes:$0,length:native.vertices.count,',
    'MTKTextureLoader(device:device).newTexture(',
    '.SRGB:true,',
    '.generateMipmaps:true,',
    '.origin:MTKTextureLoader.Origin.topLeft',
    'if let native=sourceVanguard431 {',
    'encoder.setRenderPipelineState(',
    'sourceFighterTexturedPipeline431)',
    'encoder.setFragmentTexture(native.skin,index:0)',
    'vertexCount:native.count)',
    'sourceVanguard431=nil',
):
    check(token in renderer,'Original Vanguard UV/texture material not connected: '+token)
cinematic=renderer.split(
    '        if input.introPreview41 {\n            // The source Windows GpuIntro41.CinematicIntro41',1)[1].split(
    '\n        if input.planetPreview {\n            // Original GpuIntro41.DrawDeepSpace55',1)[0]
check('if let native=sourceVanguard431 {' in cinematic,
      'Source UV mesh should be used in actual cinematic only when both resources exist')
check('drawMesh(shipMesh,craft)' in cinematic and
      'encoder.setRenderPipelineState(sourceFighterToonPipeline60)' in cinematic,
      'Original verified AS3D/toon fallback must remain accessible')
check('Self.scale(inv)' in cinematic and
      'vertexCount:native.count)' in cinematic,
      'Original PC vertices must use only normalized world units, not AS3D rescaling')
check('drawMesh(shipMesh,shipModel)' in renderer,
      'Working previous sphere combat ship modified')
check("TARGETED_DEVICE_FAMILY: '1,2'" in project,
      'iPad support disappeared')
print('PASS: source 4311 mesh normals and UV+original JPEG shader,')
print('      exact source 3-band toon, paired assets and v556 fallback')
print('LIMIT: binary assets not in GitHub yet; regular IPA remains')
print('       on old AS3D path until .mesh/.jpg are included')
