#!/usr/bin/env python3
"""Protect exact original Metal blending while removing nine forced unwraps.

This checks wiring across both sky renderers and the C279 planet. It is not
a substitute for Apple's native descriptor test or an iPhone GPU screenshot.
"""
from pathlib import Path

base=Path(__file__).resolve().parents[1]/"ASTEROIDYiOS"
sky=(base/"MetalRenderer.swift").read_text()
combat=(base/"SourceCombatSky568.swift").read_text()
carbonis=(base/"Sector01CarbonisPreview568.swift").read_text()
shared=(base/"SourceSkyPremultipliedBlend.swift").read_text()

for name,contents in (("MetalRenderer",sky),("SourceCombatSky",combat),
                      ("Sector01CarbonisPreview",carbonis)):
    assert "colorAttachments[0]!" not in contents,         f"{name}: unsafe forced attachment access restored"

# Source premultiplied ONE/ONE_MINUS_SRC_ALPHA must stay exact, including
# BOTH color and alpha; never replace with ordinary alpha blending.
for value in (
    "guard let attachment=descriptor.colorAttachments[0] else {",
    "throw MetalBlendAttachmentError.missingColorAttachment",
    "attachment.pixelFormat = .bgra8Unorm",
    "attachment.isBlendingEnabled=true",
    "attachment.sourceRGBBlendFactor = .one",
    "attachment.destinationRGBBlendFactor = .oneMinusSourceAlpha",
    "attachment.sourceAlphaBlendFactor = .one",
    "attachment.destinationAlphaBlendFactor = .oneMinusSourceAlpha",
):
    assert value in shared, f"Source PArgb blend source changed: {value}"
assert "makeRenderPipelineState" not in shared
assert "makeBuffer" not in shared
assert "MTLCommandBuffer" not in shared

for descriptor,shader in (
    ("solarDescriptor","solarOverlayPipeline"),
    ("nebulaDescriptor","nebulaOverlayPipeline"),
    ("blackDesc","blackHolePipeline"),
):
    required=f"try SourceSkyPremultipliedBlend.configure({descriptor})"
    assert sky.count(required)==1, f"Original {shader} source blend missing"
    assert sky.index(required)<sky.index(
        f"{shader}=try device.makeRenderPipelineState(")
assert shared.index("guard let attachment=descriptor.colorAttachments[0] else {") < \
       shared.index("attachment.pixelFormat = .bgra8Unorm"), \
       "Original sky attachment must be validated BEFORE pixel format access"
for descriptor in ("solarDescriptor", "nebulaDescriptor", "blackDesc"):
    assert f"{descriptor}.colorAttachments[0].pixelFormat" not in sky, \
        f"{descriptor}: unsafe pixel format assignment before source guard"
assert "d.colorAttachments[0].pixelFormat" not in combat, \
    "Combat sky pixel format bypasses the checked shared source setter"
for shader,name,descriptor in (
    (sky, "atmosphereBlend", "atmosphereDesc"),
    (sky, "plasmaBlend", "plasmaDescriptor"),
    (sky, "blend", "skyDescriptor"),
    (carbonis, "atmBlend", "atmosphereSpec"),
    (carbonis, "glowBlend", "glowSpec"),
):
    guard=f"guard let {name}={descriptor}.colorAttachments[0] else {{"
    pixel=f"{name}.pixelFormat = .bgra8Unorm"
    assert shader.index(guard) < shader.index(pixel), \
        f"{name}: unguarded pixel format access retained"
assert combat.count("try SourceSkyPremultipliedBlend.configure(d)")==1
for shader in (
    'pipeline("skyPointVertex","skyPointFragment")',
    'pipeline("solarOverlayVertex","solarOverlayFragment")',
    'pipeline("nebulaOverlayVertex","nebulaOverlayFragment")',
    'pipeline("blackHoleVertex55","blackHoleFragment55")',
):
    assert shader in combat, f"Combat source shader connection changed: {shader}"

# Sky stars explicitly use .add operations; the shared helper must NOT
# override the original default operations for the other pipelines.
for token in (
    "blend.rgbBlendOperation = .add",
    "blend.alphaBlendOperation = .add",
    "blend.sourceRGBBlendFactor = .one",
    "blend.destinationRGBBlendFactor = .oneMinusSourceAlpha",
    "blend.sourceAlphaBlendFactor = .one",
    "blend.destinationAlphaBlendFactor = .oneMinusSourceAlpha",
    "guard let blend=skyDescriptor.colorAttachments[0] else {",
):
    assert token in sky, f"Original star blending changed: {token}"

# Do not substitute source-alpha with PArgb for atmosphere or plasma.
for name,descriptor,factors in (
    ("atmosphereBlend","atmosphereDesc",
     (".sourceAlpha",".oneMinusSourceAlpha",".sourceAlpha",".oneMinusSourceAlpha")),
    ("plasmaBlend","plasmaDescriptor",
     (".sourceAlpha",".one",".sourceAlpha",".one")),
):
    assert f"guard let {name}={descriptor}.colorAttachments[0] else {{" in sky
    for field,value in zip(("sourceRGBBlendFactor","destinationRGBBlendFactor",
                            "sourceAlphaBlendFactor","destinationAlphaBlendFactor"),
                           factors):
        assert f"{name}.{field} = {value}" in sky, f"{name}.{field} source changed"

for name,descriptor,source,destination in (
    ("atmBlend","atmosphereSpec",".sourceAlpha",".oneMinusSourceAlpha"),
    ("glowBlend","glowSpec",".one",".one"),
):
    assert f"guard let {name}={descriptor}.colorAttachments[0] else {{" in carbonis
    assert f"{name}.sourceRGBBlendFactor = {source}" in carbonis
    assert f"{name}.destinationRGBBlendFactor = {destination}" in carbonis
    assert f"{name}.sourceAlphaBlendFactor = {source}" in carbonis
    assert f"{name}.destinationAlphaBlendFactor = {destination}" in carbonis

print("PASS original Metal source blends: 9 forced unwraps eliminated; unchanged sky, star, plasma, planet and depth configurations")
