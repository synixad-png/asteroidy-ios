#include <metal_stdlib>
using namespace metal;

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
    float3 eyePosition;
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
    o.eyePosition=(u.model*float4(p,1)).xyz;
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

// Native version of GpuRockInstancing75.cs:49-50 original source toon bands.
// Uses the same original procedural vertex colors/normals from RockVertices75;
// unlike the CARBONIS planet fragment this does not sample any planet textures.
fragment float4 sector01SourceRockFragment568(
    CarbonisSectorRaster568 in [[stage_in]],
    constant CarbonisSectorUniforms568 &u [[buffer(1)]])
{
    float3 n=normalize(in.normal);
    float3 light=normalize((u.model*float4(-0.6f,0.8f,1.4f,0)).xyz);
    float diffuse=max(0.0f,dot(n,light));
    float band=0.25f
        +0.33f*smoothstep(0.30f,0.32f,diffuse)
        +0.40f*smoothstep(0.70f,0.72f,diffuse);
    float3 eye=normalize(-in.eyePosition);
    float rim=0.10f*smoothstep(0.72f,0.86f,
        1.0f-max(0.0f,dot(n,eye)))*smoothstep(0.1f,0.3f,diffuse);
    float3 ink=in.color.rgb*(band+rim);
    return float4(clamp(ink,0.0f,1.0f),in.color.a);
}
