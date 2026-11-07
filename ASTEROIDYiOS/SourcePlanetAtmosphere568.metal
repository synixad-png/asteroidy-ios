#include <metal_stdlib>
using namespace metal;

// Source v568 Atmosphere47: GL SRC_ALPHA / ONE_MINUS_SRC_ALPHA.
struct PlanetAtmosphereRaster568 {
    float4 position [[position]];
    float4 color;
};
vertex PlanetAtmosphereRaster568 sourcePlanetAtmosphereVertex568(
    uint id [[vertex_id]], device const float *vertices [[buffer(0)]],
    constant float4x4 &mvp [[buffer(1)]]) {
    uint i=id*7u;
    PlanetAtmosphereRaster568 o;
    o.position=mvp*float4(vertices[i],vertices[i+1],vertices[i+2],1);
    o.color=float4(vertices[i+3],vertices[i+4],vertices[i+5],vertices[i+6]);
    return o;
}
fragment float4 sourcePlanetAtmosphereFragment568(
    PlanetAtmosphereRaster568 in [[stage_in]]) {
    return in.color;
}

// Source GpuPlanetAnimation.cs DrawPlanetGlow: additive GL ONE/ONE.
struct PlanetGlowRaster568 {
    float4 position [[position]];
    float4 color;
};
vertex PlanetGlowRaster568 sourcePlanetGlowVertex568(
    uint id [[vertex_id]], device const float *vertices [[buffer(0)]],
    constant float4 &centerScale [[buffer(1)]]) {
    uint i=id*6u;
    PlanetGlowRaster568 o;
    o.position=float4(centerScale.xy+
        float2(vertices[i],vertices[i+1])*centerScale.zw,0.9999,1);
    o.color=float4(vertices[i+2],vertices[i+3],vertices[i+4],vertices[i+5]);
    return o;
}
fragment float4 sourcePlanetGlowFragment568(PlanetGlowRaster568 in [[stage_in]]) {
    return in.color;
}
