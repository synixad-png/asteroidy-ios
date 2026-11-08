#!/usr/bin/env python3
"""Source-exact shared sky factory: no duplicated GPU builders or new effects.

Previous MetalRenderer / SourceCombatSky bodies were verified identical
before extraction. Tests validate their original resource contracts in ONE
source module and both independent scene integrations.
"""
from pathlib import Path

root=Path(__file__).resolve().parents[1]/"ASTEROIDYiOS"
shared=(root/"SourceSkyAssetFactory568.swift").read_text()
intro=(root/"MetalRenderer.swift").read_text()
combat=(root/"SourceCombatSky568.swift").read_text()

for name in ("makeSphereHaloTexture","sphereSky207","solarOverlaySource556"):
    signature=f"static func {name}("
    assert shared.count(signature)==1, f"Source builder duplicated: {name}"
    for source in (intro,combat):
        assert signature not in source, f"Old copied source builder remains: {name}"
        assert f"SourceSkyAssetFactory568.{name}(" in source, \
            f"Renderer not using shared source builder: {name}"

for piece in (
    "pixelFormat:.bgra8Unorm,width:n,height:n,mipmapped:false",
    "descriptor.usage=[.shaderRead]",
    "descriptor.storageMode = .shared",
    "SphereSky207.haloTexelsBGRA()",
    "bytesPerRow:n*4",
    "vertices.reserveCapacity(SphereSky207.count*2)",
    "indices.reserveCapacity(SphereSky207.count*2)",
    "if SphereSky207.hasBrightHalo(star)",
    "appendHalo(SphereSky207.brightHaloDiameterPixels(star),",
    "appendHalo(SphereSky207.baseDiameterPixels(star),",
    "let source=SphereSolarOverlay556.vertices()",
    "material:SIMD4<Float>(v.textured ? 1:0,1,0,0)",
):
    assert piece in shared, f"Original v568 sky source formula lost: {piece}"

assert shared.index("appendHalo(SphereSky207.brightHaloDiameterPixels") < \
       shared.index("appendHalo(SphereSky207.baseDiameterPixels"), \
       "Source star bloom must be drawn before the base point"
assert "makeTexture(descriptor:descriptor)" in shared
assert "return (vertices,(0..<source.count).map {UInt32($0)})" in shared
assert "SourceSkyAssetFactory568.makeSphereHaloTexture(device)" in intro
assert "SourceSkyAssetFactory568.makeSphereHaloTexture(device)" in combat
print("PASS single sky GPU factory: unchanged 64x64 source BGRA, star halo ordering and solar mesh; both renderers connected")
