#!/usr/bin/env python3
"""Source GpuIntro41 lazy texture life cycle: one implementation, two owners.

Never create an application-global GPU cache: Intro41 and live combat
must independently own Metal textures, failed attempts and uploaded slices.
A source contract complements native iOS compilation and real-device tests.
"""
from pathlib import Path
root=Path(__file__).resolve().parents[1]/"ASTEROIDYiOS"
intro=(root/"MetalRenderer.swift").read_text()
combat=(root/"SourceCombatSky568.swift").read_text()
life=(root/"SourceSkyTextureLifecycle55.swift").read_text()
gate=(root/"SkyTextureGate55.swift").read_text()
factory=(root/"SourceSkyAssetFactory568.swift").read_text()

names=("ensureCloudTextures55","ensureDeepPlanetTextures55",
       "ensureBlackHoleTextures55")
for name in names:
    assert life.count("static func "+name+"(")==1, "Duplicate source lifecycle: "+name
    for label,renderer in (("intro",intro),("combat",combat)):
        assert renderer.count("private func "+name+"(")==1, label+name
        assert renderer.count("SourceSkyTextureLifecycle55."+name+"(")==1, label+name
        assert "static func "+name+"(" not in renderer, label+name

# Both renderers, not the utility or a singleton, own all six mutable
# GPU cache fields. Passing separate inout fields maintains independent
# per-scene texture lifetimes and visibility-gate attempts.
for renderer in (intro,combat):
    for name in ("nebulaTexture","deepPlanetTextures","blackHoleTextures"):
        assert "privatevar"+name+":MTLTexture?" in renderer.replace(" ","")
        assert "&"+name in renderer
        assert name+":inout MTLTexture?" not in renderer
    for name in ("nebulaLoadGate","blackHoleLoadGate","deepPlanetLoadGate",
                 "nebulaSliceCache55","deepPlanetSliceCache55"):
        assert "private var "+name in renderer or "private var "+name+"=" in renderer
        assert "&"+name in renderer
    assert "sourceCloudLayers55:Self.sourceCloudLayers55" in renderer
    assert "let sourceCloudTexture=ensureCloudTextures55(camera:c)" in intro or renderer is combat
for forbidden in ("static var nebulaTexture","static var blackHoleTextures",
                  "static var deepPlanetTextures","static var nebulaLoadGate",
                  "static let singleton","sharedInstance"):
    assert forbidden not in life, "Unexpected globally shared sky state: "+forbidden

for token in (
    "if let cached=nebulaTexture, nebulaSliceCache55.allUploaded {",
    "return cached",
    "let visibleThemes=Set(sourceCloudLayers55.compactMap",
    "layer.projected(camera:camera) != nil ? layer.theme : nil",
    "guard nebulaLoadGate.shouldAllocate(visible:!visibleThemes.isEmpty)",
    "let created=try SourceSkyAssetFactory568.makeNebulaTextures556(device)",
    "nebulaTexture=created",
    "where visibleThemes.contains(theme)",
    "nebulaSliceCache55.needsUpload(style:theme)",
    "guard SourceSkyAssetFactory568.uploadNebulaSlice556(texture,theme:theme)",
    "nebulaSliceCache55.markUploaded(style:theme)",
    "guard (0..<DeepSkyPlanets55.count).contains(style) else { return nil }",
    "guard deepPlanetLoadGate.shouldAllocate(visible: true)",
    "let created=try SourceSkyAssetFactory568.makeDeepPlanetTextures55(device)",
    "deepPlanetTextures=created",
    "if deepPlanetSliceCache55.needsUpload(style:style)",
    "guard SourceSkyAssetFactory568.uploadDeepPlanetSlice55(texture,style:style)",
    "deepPlanetSliceCache55.markUploaded(style:style)",
    "guard blackHoleLoadGate.shouldAllocate(visible: true)",
    "let created=try SourceSkyAssetFactory568.makeBlackHoleTextures55(device)",
    "blackHoleTextures=created",
):
    assert token in life, "Original lazy sky texture logic changed: "+token
assert life.index("if let cached=nebulaTexture, nebulaSliceCache55.allUploaded {") < \
       life.index("let visibleThemes=Set(sourceCloudLayers55.compactMap")
assert life.count("let created=try SourceSkyAssetFactory568.")==3
assert life.count("catch {")==3
assert life.count("NSLog(")==3
assert "guard visible && !attempted else { return false }" in gate
for fn in ("makeNebulaTextures556","makeDeepPlanetTextures55","makeBlackHoleTextures55"):
    assert "static func "+fn+"(" in factory

# Retain actual source painter order in both scene draw implementations.
for label,render in (("intro",intro),("combat",combat)):
    assert "encoder.setFragmentTexture(clouds,index:0)" in render, label
    assert "encoder.setFragmentTexture(planets,index:0)" in render, label
    assert "encoder.setFragmentTexture(blackTextures,index:0)" in render, label
    assert render.index("vertexCount:24*6") < \
           render.index("vertexStart:24*6,vertexCount:12*6"), label
print("PASS source lazy sky cache lifecycle: three identical algorithms shared, independent per-renderer GPU gates and slice caches, exact visibility-first upload and painter order")
