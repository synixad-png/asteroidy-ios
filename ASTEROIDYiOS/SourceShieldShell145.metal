#include <metal_stdlib>
using namespace metal;

// Lightweight plasma membrane around the REAL source Vanguard hull.
// One precompiled pipeline and one draw call while Tarcza145.active.
// No textures, per-frame mesh uploads, extra framebuffer or world actor.
struct ShieldShellUniforms145 {
    float4x4 mvp;
    float4x4 model;
    float4 centerRadius; // original source mesh centre (xyz), local radius
    float4 cameraTime;   // source GpuSphere67 camera eye (xyz), game elapsed
    float4 state;        // Tarcza145 energy fraction, impact flash, unused
};
struct ShieldShellOutput145 {
    float4 position [[position]];
    float3 normal;
    float3 worldPos;
    float2 uv;
};
vertex ShieldShellOutput145 shieldShellVertex145(
    uint id [[vertex_id]],
    constant ShieldShellUniforms145 &u [[buffer(0)]])
{
    constexpr uint longitude=48,latitude=24;
    constexpr uint2 corners[6]={
        uint2(0,0),uint2(1,0),uint2(0,1),
        uint2(1,0),uint2(1,1),uint2(0,1)
    };
    uint triangle=id/6u;
    uint lat=triangle/longitude,lon=triangle%longitude;
    uint2 corner=corners[id%6u];
    float a=float(lon+corner.x)/float(longitude)*6.28318530718f;
    float b=float(lat+corner.y)/float(latitude)*3.14159265359f;
    float3 normal=float3(sin(b)*cos(a),cos(b),sin(b)*sin(a));
    float3 local=u.centerRadius.xyz+normal*u.centerRadius.w;
    float4 world=u.model*float4(local,1.0f);
    ShieldShellOutput145 out;
    out.position=u.mvp*float4(local,1.0f);
    out.normal=normalize((u.model*float4(normal,0.0f)).xyz);
    out.worldPos=world.xyz;
    out.uv=float2(float(lon+corner.x)/float(longitude),
                  float(lat+corner.y)/float(latitude));
    return out;
}
fragment float4 shieldShellFragment145(
    ShieldShellOutput145 input [[stage_in]],
    constant ShieldShellUniforms145 &u [[buffer(0)]])
{
    float t=u.cameraTime.w;
    float energy=clamp(u.state.x,0.0f,1.0f);
    float impact=clamp(u.state.y/0.37f,0.0f,1.0f);
    float3 toEye=normalize(u.cameraTime.xyz-input.worldPos);
    float rim=pow(clamp(1.0f-abs(dot(input.normal,toEye)),0.0f,1.0f),2.2f);
    float phase=input.uv.x*58.0f+sin(input.uv.y*27.0f+t*1.1f)*2.2f;
    float veins=pow(1.0f-abs(sin(phase+t*4.6f)),19.0f);
    float transverse=pow(1.0f-abs(sin(input.uv.y*51.0f-
                               sin(input.uv.x*19.0f+t)*2.1f-t*2.4f)),22.0f);
    // Low-opacity cyan membrane + irregular electrically animated lines.
    // Wide Fresnel remains visible without hiding the original ship.
    float flicker=0.88f+0.12f*sin(t*8.1f+input.uv.x*32.0f);
    float glow=(0.045f+0.30f*rim+0.16f*veins+0.09f*transverse);
    float alpha=clamp(glow*flicker*(0.65f+0.35f*energy)+0.23f*impact*rim,
                      0.0f,0.66f);
    float3 color=mix(float3(0.025f,0.38f,0.87f),
                     float3(0.29f,0.99f,1.0f),
                     clamp(rim*0.58f+veins*0.34f+impact*0.25f,0.0f,1.0f));
    return float4(color,alpha);
}
