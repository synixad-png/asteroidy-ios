#!/usr/bin/env python3
"""Regression: actual PC609 KESTREL orbit visibility and original Intro41 ASNT.

Both reported iPad failures were real production-source omissions, not
missing GitHub blob assets or mere UI accessibility errors. This source
contract is supplemental to the macOS REAL Swift ASNT runtime test and
native ARM64 Metal build; it does not pretend to measure GPU pixels.
"""
from pathlib import Path

root=Path(__file__).resolve().parents[1]/"ASTEROIDYiOS"
read=lambda name:(root/name).read_text(encoding="utf-8")
pose=read("PC602HomeShipPose291.swift")
ship=read("SourceHomeVanguard431.swift")
scene=read("PC602HomeScene291.swift")
nodes=read("BoreasNodeTracks556.swift")
decoder=read("SourcePC609Zlib.swift")
renderer=read("MetalRenderer.swift")

# The PC609 KESTREL (.kestrel 6031) was already real in GPU/physics.
# H290 previously left its model transform NIL for original shipType=0.
assert "static func kestrel(_ flight:PC602HomeFlight291" in pose
assert "case .kestrel:return kestrel(flight,orbitScale:orbitScale)" in pose
for craft in ("kestrel","vanguard","bastion"):
    assert f"case .{craft}:return {craft}(flight,orbitScale:orbitScale)" in pose
assert "case .kestrel:return" in pose
assert "case .vanguard:return" in pose
assert "case .bastion:return" in pose
assert "default:return nil" in pose
assert "return sourcePose(flight,orbitScale:orbitScale)" in pose
assert "let pose=PC602HomeShipPose291.active(" in ship
assert "guard flight.equipment.craft.rawValue==shipType" in ship
assert "originalShip.draw(encoder:encoder,flight:flight," in scene
assert "SourceHomeVanguard431(" in scene

# Python exporter produces RFC1950 (zlib.compress) and SHA-locked 96
# original Boreas glTF node tracks, which Foundation's old NSDecompression
# path rejected on iPad. All three original source ships and this
# animation use the SAME proven bounded Apple COMPRESSION_ZLIB helper.
assert "SourcePC609Zlib.inflateRFC1950(" in nodes
assert ".decompressed(using:.zlib)" not in "\n".join(line.split("//",1)[0] for line in nodes.splitlines())
assert "SourcePC609Zlib.inflateRFC1950(" in read("SourceKestrel603.swift")
assert "SourcePC609Zlib.inflateRFC1950(" in read("SourceBastion606.swift")
assert "COMPRESSION_ZLIB" in decoder
assert "planetNodeTracks=try BoreasNodeTracks556(" in renderer
assert "planetNodeTracks.updateVertices(seconds:seconds," in renderer
assert "planetAnimator.updateVertices(seconds: seconds," in renderer

print("PASS PC609: all three original fighter poses, exact KESTREL H290 route, bounded RFC1950 BOREAS Intro41 source decode; no fake Vanguard fallbacks")
print("LIMIT: source-only test. Actual Swift track parsing and iPad GPU screenshot require independent runtime evidence")
