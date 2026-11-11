#include <metal_stdlib>
using namespace metal;

// One triangle stream per original glTF primitive. The exact scene is
// CPU-decoded once from the SHA-verified PC v602 GLB: xyz + rgba per vertex.
struct PlanetariumHudUniform {
    float4x4 mvp;
    float4 baseColor;
};

struct PlanetariumHudVertex {
    float4 position [[position]];
    float4 color;
};

vertex PlanetariumHudVertex hudPlanetariumVertex600(
        device const float *vertices [[buffer(0)]],
        constant PlanetariumHudUniform &state [[buffer(1)]],
        uint vertexID [[vertex_id]]) {
    uint index = vertexID * 7;
    float3 position = float3(vertices[index],vertices[index+1],vertices[index+2]);
    float4 tint = float4(vertices[index+3],vertices[index+4],
                          vertices[index+5],vertices[index+6]);
    PlanetariumHudVertex out;
    out.position = state.mvp * float4(position,1.0);
    out.color = saturate(tint*state.baseColor);
    return out;
}

fragment float4 hudPlanetariumFragment600(
        PlanetariumHudVertex in [[stage_in]]) {
    return in.color;
}
