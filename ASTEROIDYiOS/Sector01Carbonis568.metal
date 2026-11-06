#include <metal_stdlib>
using namespace metal

// CARBONIS v568 C279 original INDEXED vertex stream.
// 137067 unique vertices, 810747 source indices, 2 original groups.
// Preview shader: SOURCE geometry/textures; light/PBR approximation.
// It is not yet the full Windows/src/GpuPlanet.cs rendering model.
struct CarbonisSectorUniforms568 {
    float4x4 mvp;
    float4x4 model;
    uint material;
    float glow;
};
struct CarbonisSectorRaster568 {
    float4 position [[position]];
    float3 normal;
    float4 color;
    float2 uv;
};
vertex CarbonisSectorRaster568 sector01CarbonisVertex568(
    uint id [[vertex_id]],
    device const float *mesh [[buffer(0)]],
    constant CarbonisSectorUniforms568 &u [[buffer(1)]])
{
    uint i=id*12u;
    CarbonisSectorRaster568 o;
    float3 p=float3(mesh[i],mesh[i+1],mesh[i+2]);
    o.position=u.mvp*float4(p,1);
    float3x3 axes=float3x3(u.model[0].xyz,
                         u.model[1].xyz,
                         u.model[2].xyz);
    o.normal=normalize(axes*float3(mesh[i+3],mesh[i+4],mesh[i+5]));
    o.color=float4(mesh[i+6],mesh[i+7],mesh[i+8],mesh[i+9]);
    o.uv=float2(mesh[i+10],mesh[i+11]);
    return o;
}
fragment float4 sector01CarbonisFragment568(
    CarbonisSectorRaster568 in [[stage_in]],
    constant CarbonisSectorUniforms568 &u [[buffer(1)]],
    texture2d<float> base [[texture(0)]],
    texture2d<float> emission [[texture(1)]],
    texture2d<float> irradiance [[texture(2)]])
{
    constexpr sampler sourceSampler(coord::normalized,address::repeat,
                                    filter::linear);
    float4 albedo=in.color;
    if(u.material==0u) albedo*=base.sample(sourceSampler,in.uv);
    float sunlight=max(0.0f,dot(normalize(in.normal),
                       normalize(float3(-0.6f,0.8f,1.4f))));
    float3 lit=albedo.rgb*(0.24f+sunlight*0.72f);
    if(u.material==0u){
        // These are the authentic unmodified CARBONIS texture samples.
        // This is deliberately a conservative pre-PBR preview, not fake
        // claim of parity with Windows v568 GpuPlanet Carbonis shader.
        float3 ambient=irradiance.sample(sourceSampler,in.uv).rgb;
        float3 hot=emission.sample(sourceSampler,in.uv).rgb;
        lit+=albedo.rgb*ambient*0.10f+hot*u.glow*0.38f;
    }
    return float4(clamp(lit,0.0f,1.0f),clamp(albedo.a,0.0f,1.0f));
}
