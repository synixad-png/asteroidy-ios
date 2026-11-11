#include <metal_stdlib>
using namespace metal;

// Original PC v602 GpuIntro41.PrepareIntroBelt produces interleaved 10xfloat:
// XYZ, normal XYZ, linear vertex RGBA. The source world multiplies geometry
// by 3.2 before drawing, then renders only visible authored rocks.
// This is NOT the unrelated combat-only RockVertices75 mesh.
struct PC602Belt51Uniforms {
    float4x4 mvp;
    float4x4 modelView;
    float4 sourceLightEye;
};
struct PC602Belt51Vertex {
    float4 position [[position]];
    float3 eyePosition;
    float3 eyeNormal;
    float4 color;
};
vertex PC602Belt51Vertex pc602Belt51Vertex(
    uint id [[vertex_id]],
    device const float *geometry [[buffer(0)]],
    constant PC602Belt51Uniforms &u [[buffer(1)]])
{
    uint offset=id*10u;
    float3 local=float3(
        geometry[offset],geometry[offset+1u],geometry[offset+2u]);
    float3 normal=float3(
        geometry[offset+3u],geometry[offset+4u],geometry[offset+5u]);
    PC602Belt51Vertex v;
    v.position=u.mvp*float4(local,1.0f);
    v.eyePosition=(u.modelView*float4(local,1.0f)).xyz;
    v.eyeNormal=normalize(float3x3(
        u.modelView[0].xyz,u.modelView[1].xyz,
        u.modelView[2].xyz)*normal);
    v.color=float4(
        geometry[offset+6u],geometry[offset+7u],
        geometry[offset+8u],geometry[offset+9u]);
    return v;
}
fragment float4 pc602Belt51Fragment(
    PC602Belt51Vertex in [[stage_in]],
    constant PC602Belt51Uniforms &u [[buffer(1)]])
{
    // Source GpuToon60: non-textured, non-smooth rock colour & rim.
    float3 n=normalize(in.eyeNormal);
    float3 light=normalize(u.sourceLightEye.xyz);
    float d=max(0.0f,dot(n,light));
    float band=0.25f+0.33f*smoothstep(0.30f,0.32f,d)
                     +0.40f*smoothstep(0.70f,0.72f,d);
    float3 view=normalize(-in.eyePosition);
    float rim=0.10f*smoothstep(0.72f,0.86f,
        1.0f-max(0.0f,dot(n,view)))*
        smoothstep(0.10f,0.30f,d);
    float3 ink=in.color.rgb*(band+rim);
    return float4(clamp(ink,0.0f,1.0f),in.color.a);
}
