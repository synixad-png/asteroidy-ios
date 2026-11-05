#!/usr/bin/env python3
"""Verify source v556 visibility-triggered GPU textures, not GPU execution.

Original GpuIntro41.DrawSkyPlanet55 and DrawSkyBlackHole55 generate their
bitmaps only AFTER SkyProject55 succeeds; GpuCosmos39.CloudLayer caches
NebulaTexture on first use. Large arrays must not be made at renderer
initialization, especially while only the flat sandbox is being used.
"""
from pathlib import Path
root=Path(__file__).resolve().parents[1]
src=(root/"ASTEROIDYiOS"/"MetalRenderer.swift").read_text()
gate=(root/"ASTEROIDYiOS"/"SkyTextureGate55.swift").read_text()
def ck(ok,message):
    if not ok:
        raise AssertionError(message)
for kind,field,method,call in (
    ("cloud","nebulaTexture","ensureCloudTextures55",
     "Self.makeNebulaTextures556(device)"),
    ("planet","deepPlanetTextures","ensureDeepPlanetTextures55",
     "Self.makeDeepPlanetTextures55(device)"),
    ("black hole","blackHoleTextures","ensureBlackHoleTextures55",
     "Self.makeBlackHoleTextures55(device)")):
    ck(f"private var {field}: MTLTexture?" in src,
       kind+": source texture no longer lazily optional")
    signature=(f"private func {method}(camera: SphereCamera67) -> MTLTexture?"
               if kind=="cloud" else
               f"private func {method}(style: Int) -> MTLTexture?"
               if kind=="planet" else
               f"private func {method}() -> MTLTexture?")
    ck(signature in src,kind+": missing one-time resource getter")
    ck(f"let created=try {call}" in src,
       kind+": source GPU array construction missing")
    ck(f"let created=try {call}" not in src.split("init(device: MTLDevice",1)[1].split(
        "private static let sourceCloudLayers55:",1)[0],
       kind+": attempted eager resource creation at renderer init")
    ck(f"if let current={field}" in src,
       kind+": texture cache not returned on subsequent frames")
    ck(f"{field}=created" in src,
       kind+": source texture not cached for subsequent frames")

for token in (
    "private var nebulaLoadGate = SkyTextureGate55()",
    "private var blackHoleLoadGate = SkyTextureGate55()",
    "private var deepPlanetLoadGate = SkyTextureGate55()",
    "guard blackHoleLoadGate.shouldAllocate(visible: true)",
    "guard deepPlanetLoadGate.shouldAllocate(visible: true)",
    "let sourceCloudTexture=ensureCloudTextures55(camera:c)",
    "private static let sourceCloudLayers55: [SphereNebula556.Layer]",
    "let hasVisibleCloud=Self.sourceCloudLayers55.contains",
    "$0.projected(camera:camera) != nil",
    "guard nebulaLoadGate.shouldAllocate(visible:hasVisibleCloud)",
    "if let clouds=sourceCloudTexture",
    "guard let planets=ensureDeepPlanetTextures55(style:style)",
    "private var deepPlanetSliceCache55 = SkyTextureSliceCache55(count: DeepSkyPlanets55.count)",
    "if deepPlanetSliceCache55.needsUpload(style:style)",
    "deepPlanetSliceCache55.markUploaded(style:style)",
    "guard Self.uploadDeepPlanetSlice55(texture,style:style)",
    "let blackTextures=ensureBlackHoleTextures55()",
    "encoder.setFragmentTexture(clouds,index:0)",
    "encoder.setFragmentTexture(planets,index:0)",
    "encoder.setFragmentTexture(blackTextures,index:0)",
    "vertexStart:24*6,vertexCount:12*6",
):
    ck(token in src, "Visible-only source texture path missing: "+token)

ck(src.index("if input.planetPreview {\n            // Original GpuIntro41.DrawDeepSpace55") <
   src.index("let sourceCloudTexture=ensureCloudTextures55(camera:c)"),
   "GpuCosmos39 clouds should not allocate in flat arena")
ck(src.index("guard let projected=DeepSkyPlanets55.project(") <
   src.index("guard let planets=ensureDeepPlanetTextures55()"),
   "GpuIntro41 planets must project before texture generation")
ck(src.index("if let blackProjection=BlackHoleSky55.project(") <
   src.index("let blackTextures=ensureBlackHoleTextures55()"),
   "GpuIntro41 black hole must project before texture generation")
ck(src.index("encoder.setFragmentTexture(clouds,index:0)") <
   src.index("encoder.setFragmentTexture(planets,index:0)") <
   src.index("encoder.setFragmentTexture(blackTextures,index:0)") <
   src.index("vertexStart:24*6,vertexCount:12*6"),
   "Original DrawDeepSpace55 painter order changed")

for token in (
    "guard visible && !attempted else { return false }",
    "attempted = true",
    "static let blackHoleBytes = 3 * 640 * 640 * 4",
    "static let threePlanetsBytes = 3 * 320 * 220 * 4",
    "static let nebulaBytes = 2 * 256 * 256 * 4",
):
    ck(token in gate,"Resource gate/size regression: "+token)
print("PASS: original source GpuIntro41 / GpuCosmos39 lazy image creation,")
print("      no 6.28MB sky textures in flat mode, max one attempt each,")
print("      preserved far worlds / black hole / near clouds painter order")
print("LIMITATION: static contract, not native Apple Metal GPU execution")
