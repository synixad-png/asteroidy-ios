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
wreck=read("SourceHomeWreck209.swift")
ship=read("SourceHomeVanguard431.swift")
ship_pose=read("PC602HomeShipPose291.swift")
ship_source=read("SourceVanguardMesh431.swift")
ship_shader=read("Ship.metal")
wreck_mesh=read("ResearchWreckGeometry214.swift")
combat_wreck=read("SourceCombatWreck214.swift")
combat_shader=read("Sector01Carbonis568.metal")
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
assert "let sunAngle:Float=0.62+max(0,flight.orbitTime)*0.047" in world
assert "sourceKeyEye:sunEye" in world
assert "sourceLightEye:sunEye" in world
atmosphere=read("PC602HomeAtmosphere47.swift")
signal=read("PC602HomeMissionSignal58.swift")
shot_lights=read("PC602HomeProjectileLights296.swift")
assert "SourcePlanetAtmosphere568.atmosphere(" in atmosphere
assert "originalAtmosphere.draw(encoder:encoder," in world
# PC602 Renderer.cs:139 and HomeFlight291.cs:106,113,123
# independently feed glow/nebula/rays at runtime. Old iOS profiles
# may omit option #12/#13 and must restore original enabled defaults.
settings=read("SourcePlanetAtmosphere568.swift")
panel=read("CarbonisVisualSettingsPanel568.swift")
assert "var nebulaEnabled=true" in settings
assert "var solarRaysEnabled=true" in settings
assert "init(from decoder:Decoder) throws" in settings
assert "decodeIfPresent(Bool.self" in settings
assert "static let revisionKey=key+" in settings
assert "defaults.integer(forKey:Self.revisionKey) &+ 1" in settings
assert 'Toggle("MGŁAWICA KOSMICZNA"' in panel
assert 'Toggle("PROMIENIE SŁONECZNE"' in panel
assert 'accessibilityIdentifier("w3-source-nebula-option-12")' in panel
assert 'accessibilityIdentifier("w3-source-solar-rays-option-13")' in panel
assert "if revision != graphicsRevision" in world
assert "glow:effects.glowEnabled" in world
assert "nebula:effects.nebulaEnabled" in world
assert "rays:effects.solarRaysEnabled" in world
assert world.count("if effects.glowEnabled {")==2
# Original PC602 GpuIntro41.cs:452:
# if(glow&&bright)IntroHalo(p,21 or 10,...); IntroHalo(p,size*2,...);
# Glow disabled MUST retain all 1500 ordinary star cores.
factory=read("SourceSkyAssetFactory568.swift")
sky=read("SourceCombatSky568.swift")
assert "static func sphereSky207WithGlow(_ glow:Bool)" in factory
assert "if SphereSky207.hasBrightHalo(star)" in factory
assert "if glow {" in factory.split("if SphereSky207.hasBrightHalo(star)",1)[1].split("}",1)[0]
assert factory.count("static func sphereSky207(")==1
assert factory.count("static func sphereSky207WithGlow(")==1
assert factory.index("appendHalo(SphereSky207.brightHaloDiameterPixels") < factory.index("appendHalo(SphereSky207.baseDiameterPixels")
assert "starCoreCount==SphereSky207.count" in sky
assert "let cores=SourceSkyAssetFactory568.sphereSky207WithGlow(false)" in sky
assert "glow ? starBuffer : starCoreBuffer" in sky
assert "vertexCount:glow ? starCount : starCoreCount" in sky
assert "worldScale:SphereCameraView556.originalPlanetOuterRadius" in world

assert "let glowEnabled:Bool" not in world

assert "PC602HomeMissionSignal58" in signal
assert "originalSignal.draw(encoder:encoder," in world
assert "PC602HomeProjectileLights296" in shot_lights
assert "projectileLights.draw(encoder:encoder,command:command," in world
assert world.count("onProjectiles?() ?? []")==1
assert "HudPlanetariumMetal600(" not in world
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
assert "uint offset=id*10u;" in belt_shader
assert "float band=0.25f+0.33f*smoothstep(0.30f,0.32f,d)" in belt_shader
assert "float3 view=normalize(-in.eyePosition);" in belt_shader
assert "device const float *geometry" in belt_shader

# The REAL original GpuIntro41 full orbital research wreck must use the
# preexisting proven hull, not the partial 161-box debris mesh as a substitute.
assert "makeOrbitHome602()->Mesh" in wreck_mesh
assert "builder.drawSourceWreck214(seed:211,debris:146,trail:178)" in wreck_mesh
assert "func drawSourceWreck214(seed:Int,debris:Int=112,trail:Float=118)" in wreck_mesh
assert "builder.drawSourceWreck214(seed:sector+214)" in wreck_mesh
assert "mesh.hullVertices=mesh.triangleCount" in wreck_mesh
assert "mesh.hullLineVertices=mesh.lineCount" in wreck_mesh
assert "ResearchWreckGeometry214.makeOrbitHome602()" in wreck
assert 'combatWreckTriangleVertex214' in wreck
assert 'combatWreckLineFragment214' in wreck
assert 'combatWreckTriangleVertex214' in combat_wreck
assert 'combatWreckTriangleVertex214' in combat_shader
assert "WreckWarningLamp213" in combat_shader
assert "sourceScale=PC602NewHome290.wreckScale295" in wreck
assert "let orientation=Self.rotateY(31) * Self.rotateZ(-9)" in wreck
assert "let transform=Self.translate(dock) * orientation * scale" in wreck
assert "let angle:Float=0.62+max(0,time)*0.047" in wreck
assert "drawPrimitives(type:.triangle" in wreck
assert "drawPrimitives(type:.line" in wreck
assert "originalWreck=try SourceHomeWreck209(device:device)" in world
assert "originalWreck.draw(encoder:encoder,projection:projection" in world
assert "dock:flight.dockPosition" in world
assert world.index("for stone in belt.stones") < world.index("originalWreck.draw")
assert world.index("originalWreck.draw") < world.index("PC602HomeBeacons291.vertices(")
assert "PC602WreckDebris209.structuralBoxFaces" not in world

# REAL PC602 4311 Vanguard (craft 1) rather than a generated/substitute
# GLB; the original binary and skin hashes are checked by the runtime.
assert "SourceVanguardMesh431.exactMeshSHA256" in ship
assert "SourceVanguardMesh431.exactBaseJPEG_SHA256" in ship
assert "SourceVanguardMesh431(data:originalMesh)" in ship
assert 'name:"sourceVanguardVertex431"' in ship
assert 'name:"sourceVanguardTexturedToonFragment431"' in ship
assert "sourceVanguardTexturedToonFragment431" in ship_shader
assert "sourceVanguardVertex431" in ship_shader
assert "static let sourceHomeWorldOuterRadius:Float=144.19674" in ship_pose
assert "sourceContactRadius*originalWorldScale*0.65*1.35" in ship_pose
assert "flight.equipment.craft == .vanguard" in ship_pose
assert "flight.flight.flight.visualBank" in ship_pose
assert "flight.flight.flight.visualPitch" in ship_pose
assert "flight.home.surface(" in ship_pose
assert "altitude+12" in ship_pose
assert "sourceShipScale*orbitScale" in ship_pose
assert "originalShip=try SourceHomeVanguard431(device:device)" in world
assert "originalShip.draw(encoder:encoder,flight:flight," in world
assert world.index("PC602HomeBeacons291.vertices(") < world.index("originalShip.draw")
assert "SourceShipScale472.load().orbitFactor" in world
assert "sourceVanguardTexturedToonFragment431" in ship_shader
assert "PC602HomeShipPose291" not in app

# This is a source renderer, NOT a complete orbit gameplay/menu substitution.
assert "PC602HomeWorldPage291(" in app
assert "PC602HomeFlight291(" not in app
print("PASS PC602: original shared H290 source GPU, true world 100x geometry, "+
      "Toon60/lava source, 26 height-derived additive beacons, unchanged W3")
print("LIMIT: source contract does NOT confirm actual Apple GPU framebuffer, "+
      "player ship, physical docking, full 26-mission integration or playable orbit mode")
