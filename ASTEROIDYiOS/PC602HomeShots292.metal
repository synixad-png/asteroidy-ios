#include <metal_stdlib>
using namespace metal;

// Original Combat69.DrawShipShots69: three RGB/alpha ribbons after the
// source Sphere67/ShotPosition292 terrain-following CPU sampler.
// The seven floats are original: XYZ then RGBA, not billboard texture UV.
// Triangles use the original SRC_ALPHA/ONE additive blend and depth test.
struct PC602ShotRaster292 {
    float4 position [[position]];
    float4 tint;
};
vertex PC602ShotRaster292 pc602HomeShotVertex292(
    uint index [[vertex_id]],
    device const float *data [[buffer(0)]],
    constant float4x4 &mvp [[buffer(1)]]) {
    uint i=index*7u;
    PC602ShotRaster292 r;
    r.position=mvp*float4(data[i],data[i+1],data[i+2],1.0f);
    r.tint=float4(data[i+3],data[i+4],data[i+5],data[i+6]);
    return r;
}
fragment float4 pc602HomeShotFragment292(
    PC602ShotRaster292 in [[stage_in]]) {
    return in.tint;
}
