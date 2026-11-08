#!/usr/bin/env python3
"""Original source sky uniform packing is one pure implementation, not 6 copies.

This static integration check complements SourceSkyUniformPackingTests.swift,
which validates independently computed numerical vector values.
"""
from pathlib import Path

root=Path(__file__).resolve().parents[1]/"ASTEROIDYiOS"
intro=(root/"MetalRenderer.swift").read_text()
combat=(root/"SourceCombatSky568.swift").read_text()
shared=(root/"SourceSkyUniformPacking.swift").read_text()

for func,variable in (
    ("planet(frame:frame,layers:layers)","uniforms"),
    ("blackHole(screen:screen,layers:layers)","properties"),
):
    call=f"let {variable}=SourceSkyUniformPacking.{func}"
    assert intro.count(call)==2, f"Two independent source sky intro passes must use {func}"
    assert combat.count(call)==1, f"Combat source sky must use {func}"

for legacy in (
    "var uniforms:[SIMD4<Float>]=[frame]",
    "var properties:[SIMD4<Float>]=[screen]",
):
    assert legacy not in intro and legacy not in combat, f"Old copied packer returned: {legacy}"
    assert shared.count(legacy)==1, f"Original source data packer missing/duplicated: {legacy}"

for formula in (
    "uniforms.reserveCapacity(1+layers.count*3)",
    "layer.radiusX,layer.radiusY,1,0",
    "Float(layer.textureSlice),0,0,0",
    "properties.reserveCapacity(1+layers.count*3)",
    "cos(layer.angle),sin(layer.angle)",
    "layer.isTexture ? Float(layer.layer) : -1",
    "SIMD4(r*a,g*a,b*a,a)",
):
    assert formula in shared, f"GpuIntro41 BlackHoleRaster55 uniform packing changed: {formula}"
assert shared.count("SIMD4(r*a,g*a,b*a,a)")==2, "Both color paths must premultiply alpha"
# The renderer owns the Metal binding and draw order. Packing must not
# create textures, buffers, pipelines, timers or change scene state.
for forbidden in ("MTLTexture","MTLBuffer","MTLRenderCommandEncoder",
                  "DispatchQueue","CACurrentMediaTime","drawPrimitives"):
    assert forbidden not in shared, f"Pure uniform packing must not own GPU state: {forbidden}"
for renderer in (intro,combat):
    for token in ("encoder.setVertexBytes(","encoder.drawPrimitives(type:.triangle,"):
        assert token in renderer, "Actual GPU draw contract removed"
print("PASS source sky uniforms shared across 3 draw paths each, exact original shader data order; no GPU side effects")
