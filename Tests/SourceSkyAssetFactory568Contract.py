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

for name in (
    "makeSphereHaloTexture", "sphereSky207", "solarOverlaySource556",
    "makeNebulaTextures556", "uploadNebulaSlice556", "nebulaSource556",
    "makeBlackHoleTextures55", "makeDeepPlanetTextures55",
    "uploadDeepPlanetSlice55",
):
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
for piece in (
    # 256×256 nebula texture array and exact per-theme source BGRA.
    "d.arrayLength = SphereNebula556.orbitThemeCount",
    "let texels=SphereNebula556.textureBGRA(theme:theme)",
    "bytesPerRow:n*4,bytesPerImage:n*n*4",
    "vertices.reserveCapacity(SphereNebula556.orbitLayerCount*6)",
    # Black hole 3×640×640 layers and original draw order.
    "desc.arrayLength = 3",
    "let image=BlackHoleSky55.textureBGRA(slice:slice)",
    "for slice in 0..<3",
    # Planets remain separate visibility-triggered 320×220 uploads.
    "d.arrayLength = DeepSkyPlanets55.count",
    "let img=DeepSkyPlanets55.textureBGRA(style:style)",
    "bytesPerRow:w*4",
    # Reject corrupt source pixel buffers, never silently return a success.
    "guard texels.count == n*n*4 else {",
    "guard img.count == w*h*4 else {",
):
    assert piece in shared, f"Original source texture formula lost: {piece}"
# No shared instance cache: each renderer still owns its independent
# visibility gates, slice caches and source-specific painter order.
for renderer in (intro, combat):
    for name in ("ensureCloudTextures55", "ensureDeepPlanetTextures55",
                 "ensureBlackHoleTextures55"):
        assert f"private func {name}(" in renderer
    for name in ("uploadNebulaSlice556", "uploadDeepPlanetSlice55"):
        assert f"SourceSkyAssetFactory568.{name}(" in renderer
    assert "private var nebulaTexture: MTLTexture?" in renderer
    assert "private var deepPlanetTextures: MTLTexture?" in renderer
    assert "private var blackHoleTextures: MTLTexture?" in renderer
assert "SourceSkyAssetFactory568.makeSphereHaloTexture(device)" in intro
assert "SourceSkyAssetFactory568.makeSphereHaloTexture(device)" in combat
print("PASS one sky source factory: 9 builders, star/nebula/planet/black-hole exact source formulas; both renderer caches independent")
