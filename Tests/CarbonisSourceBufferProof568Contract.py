#!/usr/bin/env python3
"""Regression contract: CARBONIS v568 immutable GPU mesh uploads and proof.

All original source geometry, byte counts, fallback paths, SHA checks,
UI states, and 60 FPS/audio scheduling must remain intact.
"""
from pathlib import Path

root=Path(__file__).resolve().parents[1]
renderer=(root/"ASTEROIDYiOS/Sector01CarbonisPreview568.swift").read_text()
writer=(root/"ASTEROIDYiOS/OriginalRenderProofWriter568.swift").read_text()
geometry=(root/"ASTEROIDYiOS/CarbonisRockGeometry568.swift").read_text()
shooter=(root/"ASTEROIDYiOS/CarbonisShooterMesh71.swift").read_text()
atmosphere=(root/"ASTEROIDYiOS/SourcePlanetAtmosphere568.swift").read_text()

# All four original init-time Float uploads share one unchanged Metal API.
for piece in (
    "private static func makeBuffer(_ values:[Float],device:MTLDevice)",
    "guard let buffer=values.withUnsafeBytes({ raw in",
    "device.makeBuffer(bytes:$0,length:raw.count,options:[])",
    "else {throw SourceError.metal}",
    "let capGPU=try Self.makeBuffer(cap,device:device)",
    "let haloGPU=try Self.makeBuffer(halo,device:device)",
    "rockBuffers[shape]=try Self.makeBuffer(values,device:device)",
    "let buffer=try Self.makeBuffer(mesh.vertices,device:device)",
    "sourceShooters[kind]=(buffer,mesh.ranges)",
    "private static func makeBuffer(_ data:Data,device:MTLDevice)",
    "vertexBuffer=try Self.makeBuffer(vertices,device:device)",
    "indexBuffer=try Self.makeBuffer(indices,device:device)",
):
    assert piece in renderer, f"Immutable source GPU buffer contract changed: {piece}"
assert renderer.count("private static func makeBuffer(_ values:[Float],device:MTLDevice)")==1
assert renderer.count("device.makeBuffer(bytes:$0,length:raw.count,options:[])")==1

# Actual input types stay [Float] and are not converted or quantized.
for name,piece in (
    ("original rock geometry", "static func vertices(shape:Int)->[Float]"),
    ("original shooter mesh", "let vertices:[Float]"),
    ("original atmosphere", "static func atmosphere(tint:(Float,Float,Float))->[Float]"),
    ("original halo", "static func glow(tint:(Float,Float,Float))->[Float]"),
):
    text={"original rock geometry":geometry,"original shooter mesh":shooter,
          "original atmosphere":atmosphere,"original halo":atmosphere}[name]
    assert piece in text, f"{name} is no longer source Float geometry"

# The game preloads ALL source rock shapes once; keep its emergency
# fallback in the hot path untouched, rather than changing combat.
assert "Set(0..<CarbonisRockGeometry568.sourceShapeCount)" in renderer
assert "if rockBuffers[shape] == nil {" in renderer
assert "rockBuffers[shape]=mesh.withUnsafeBytes { bytes in" in renderer

# Verify source data SHA checks, one-shot opt-in proof and same payload.
for piece in (
    "SHA256.hash(data:bytes)",
    "guard digest==expected[full] else {throw SourceError.invalid}",
    'ProcessInfo.processInfo.environment["ASTEROIDY_W3_MENU_VERIFY"]=="1"',
    "proofScheduled=true",
    "command.addCompletedHandler { completed in",
    '"gpuCommandBufferCompleted":completed.status == .completed',
    '"triangles":270249',
    '"sourceUniqueVertices":137067',
    '"sourceIndices":810747',
    'OriginalRenderProofWriter568.save(',
    'proof,filename:"ASTEROIDY_CARBONIS_L1_GPUProof.json"',
):
    assert piece in renderer, f"Original diagnostic/asset gate changed: {piece}"
assert "try? bytes.write" not in renderer
for piece in ("JSONSerialization.data(", "options: [.sortedKeys]",
              "options: .atomic", "catch {",
              "ASTEROIDY GPU proof write failed"):
    assert piece in writer, f"Shared GPU proof writer lost error handling: {piece}"
assert renderer.count("command.addCompletedHandler { completed in")==1

print("PASS CARBONIS immutable Float buffers: identical byte uploads, no gameplay fallback change, SHA-checked source and explicit-error GPU proof")
