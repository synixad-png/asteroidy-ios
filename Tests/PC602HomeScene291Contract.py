#!/usr/bin/env python3
"""Source-only, non-GPU PC602 HomeScene291/W3 regression checks.

The golden constants come from the user's SHA-locked PC602 ZIP:
 Windows/src/NewHome290.cs
 Windows/src/GpuNewHome290.cs
 Windows/src/HomeFlight291.cs
 Windows/src/GpuToon60.cs
 Windows/src/OrbitWorld51.cs
Do not interpret textual checks as evidence of actual iPhone GPU pixels.
"""
from pathlib import Path

root=Path(__file__).resolve().parents[1]
def read(name):
    return (root/"ASTEROIDYiOS"/name).read_text()

shared=read("SourceNewHome290MetalAssets.swift")
preview=read("W3HomePlanetMetal568.swift")
shader=read("W3HomePlanet290.metal")
header=read("SourceHome290Vertex.metalh")
world=read("PC602HomeScene291.swift")
world_shader=read("PC602HomeScene291.metal")
beacons=read("PC602HomeBeacons291.swift")
belt=read("PC602OrbitBelt51.swift")
belt_shader=read("PC602OrbitBelt51.metal")
app=read("App.swift")

# Exactly ONE immutable Metal resource cache for these TWO consumers.
assert "private static var cached:[ObjectIdentifier:SourceNewHome290MetalAssets]" in shared
assert "static let defaultDevice:MTLDevice? = MTLCreateSystemDefaultDevice()" in shared
assert "MTKView(frame:.zero,device:SourceNewHome290MetalAssets.defaultDevice)" in preview
assert "MTKView(frame:.zero,device:SourceNewHome290MetalAssets.defaultDevice)" in world
assert "MTLCreateSystemDefaultDevice()" not in preview
assert "MTLCreateSystemDefaultDevice()" not in world

assert "SourceNewHome290MetalAssets.shared(device:device)" in preview
assert "SourceNewHome290MetalAssets.shared(device:device)" in world
assert "device.makeBuffer(bytes:$0,length:mesh.count,options:[])" in shared
assert "MTKTextureLoader(device:device)" in shared
assert "MTKTextureLoader(device:device)" not in preview
assert "device.makeBuffer(bytes:$0,length:bytes.count,options:[])" not in preview
for src in ("e93a0bbafc9bb50a25726a828ada81f36675bf88d802c5a8f985b89b6dc96c1b",
            "4987f35cd6f021fd98794f406c641f4853c538a82b10625e6b79e860c8a787c0",
            "6f1debd175f52b7ce1fbc687e9977597335ee432858d7d6d6e47cf66b5f9aa39"):
    assert src in shared
assert "static let terrainVertices=514176" in shared
assert "static let armorVertices=2448" in shared
assert "static let vertexStride=48" in shared

# Same original 12-float GLB decoder; neither variant invents another mesh.
assert "device const float *mesh" in header
assert "const uint i=id*12u;" in header
assert 'sourceHome290Vertex(id,mesh,u)' in shader
assert 'sourceHome290Vertex(id,mesh,u)' in world_shader
assert 'sourceHome290Vertex' not in world
assert 'W3HomePlanetMetal568' not in world

# W3 remains transparent and source-compatible (not the new orbital view).
assert "view.isOpaque=false" in preview
assert "MTLClearColor(red:0,green:0,blue:0,alpha:0)" in preview
assert "float band=0.25f+0.78f*d;" in shader

# Original real 100x NewHome290, 400m world eye, .4/1600 perspective.
assert "simd_float4x4(diagonal:SIMD4(100,100,100,1))" in world
assert "PC602HomeWorldView291(" in world
assert "camera:flight.flight.camera" in world
assert "let modelView=viewMatrix*model" in world
assert "mvp:projection*modelView,model:modelView" in world
assert "float band=0.25f+0.33f*smoothstep(0.30f,0.32f,d)" in world_shader
assert "smoothstep(0.24f,0.58f,heat)" in world_shader
assert "float3(1.0f,0.30f,0.07f)*core*0.68f" in world_shader
assert "if(u.material==0u)" in world_shader
assert "sourceKeyEye:SIMD4(-0.6,0.8,1.4,0)" in world
assert "float3 l=normalize(light.sourceKeyEye.xyz);" in world_shader
assert "float3 view=normalize(-in.viewPosition);" in world_shader
assert "encoder.setCullMode(.none)" in world
assert "vertexCount:SourceNewHome290MetalAssets.terrainVertices" in world
assert "vertexCount:SourceNewHome290MetalAssets.armorVertices" in world

# The authored 26 line rings are world-geometry with depth-test and no writes.
assert "static let levels=26" in beacons
assert "static let ringSegments=40" in beacons
assert "height+0.5" in beacons
assert "selectedMarker ? 8 : 3.4" in beacons
assert "device.makeBuffer(bytes:$0,length:raw.count,options:[])" in world
assert "beaconCacheKey" in world
assert "encoder.drawPrimitives(type:.line" in world
assert "beaconDescriptor.isDepthWriteEnabled=false" in world
assert "markers.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha" in world
assert "markers.colorAttachments[0].destinationRGBBlendFactor = .one" in world

# PC602 source belt must be the actual 820 authored crater meshes.
# Do not reintroduce lower-poly spheres, bespoke Swift randomness or frame
# allocations. Original GpuIntro41's individual visibility is preserved,
# while consecutive visible ranges may be coalesced to one Metal draw.
assert "static let asteroidCount=820" in belt
assert "static let vertexStride=40" in belt
assert "let sourceBytes:Data" in belt
assert "func visible(_ stone:Stone,view:[Float],aspect:Float)" in belt
assert "stone.size*Self.sourceScale*1.9+1" in belt
assert "PC602OrbitBelt51.load()" in world
assert "sourceBytes.withUnsafeBytes" in world
assert "encoder.setVertexBuffer(beltBuffer,offset:0,index:0)" in world
assert "let rockModel=simd_float4x4(" in world
assert "diagonal:SIMD4(3.2,3.2,3.2,1)" in world
assert "for stone in belt.stones" in world
assert "runStart+runCount==stone.firstVertex" in world
assert "vertexStart:runStart,vertexCount:runCount" in world
assert 'name:"pc602Belt51Vertex"' in world
assert 'name:"pc602Belt51Fragment"' in world
assert "const uint" not in belt_shader or "id*10u" in belt_shader
assert "uint offset=id*10u;" in belt_shader
assert "float band=0.25f+0.33f*smoothstep(0.30f,0.32f,d)" in belt_shader
assert "float3 view=normalize(-in.eyePosition);" in belt_shader
assert "device const float *geometry" in belt_shader

# This is a source renderer, NOT a complete orbit gameplay/menu substitution.
assert "PC602HomeScene291(" not in app
assert "PC602HomeFlight291(" not in app
print("PASS PC602: original shared H290 source GPU, true world 100x geometry, "+
      "Toon60/lava source, 26 height-derived additive beacons, unchanged W3")
print("LIMIT: source contract does NOT confirm Apple device rendering, "+
      "player ship, 820-belt, wreck, docking or playable orbit mode")
