#include "SourceHome290Vertex.metalh"

// Actual PC602 HomeScene291: GpuNewHome290.DrawNewHome290 with the same
// original H290 vertex stream as the W3 preview. Projection, model and light
// direction use the full-world OrbitWorld50 camera, NOT W3's orthographic
// globe viewer. Preserve the complete 2 material-group draw intervals.
struct Home291Lighting {
    float4 sourceKeyEye;             // FighterLight(false): eye-space w=0
    uint smooth65;                   // GpuToon60: default toon band shading
    float padding0;
    float padding1;
    float padding2;
};
vertex W3Home290Output home291Vertex(
    uint id [[vertex_id]],
    device const float *mesh [[buffer(0)]],
    constant W3Home290Uniforms& u [[buffer(1)]])
{
    return sourceHome290Vertex(id,mesh,u);
}

fragment float4 home291Fragment(
    W3Home290Output in [[stage_in]],
    constant W3Home290Uniforms& u [[buffer(1)]],
    constant Home291Lighting& light [[buffer(2)]],
    texture2d<float> baseMap [[texture(0)]],
    texture2d<float> glowMap [[texture(1)]])
{
    constexpr sampler sourceSampler(coord::normalized,address::repeat,
                                    filter::linear);
    float4 base=in.color;
    if(u.material==0u)base*=baseMap.sample(sourceSampler,in.uv);
    float3 n=normalize(in.normal);
    // Original GpuToon60 uses gl_NormalMatrix and gl_LightSource[0]
    // in EYE space. The shared vertex decoder's 'model' matrix is the
    // actual model-view; not world-only normal positions.
    float3 l=normalize(light.sourceKeyEye.xyz);
    float d=max(0.0f,dot(n,l));
    // Windows/src/GpuToon60.cs: actual non-smooth default uses hard bands.
    float band=0.25f+0.33f*smoothstep(0.30f,0.32f,d)
                       +0.40f*smoothstep(0.70f,0.72f,d);
    if(light.smooth65!=0u)band=0.25f+0.78f*d;
    float3 view=normalize(-in.viewPosition);
    float rim=0.10f*smoothstep(0.72f,0.86f,
         1.0f-max(0.0f,dot(n,view)))*smoothstep(0.10f,0.30f,d);
    float3 ink=base.rgb*(band+rim);

    // Windows/src/GpuToon60.cs: v293 lava emission and irradiance are
    // composed in the ORIGINAL terrain fragment (not a second coplanar pass).
    if(u.material==0u){
        float3 lava=glowMap.sample(sourceSampler,in.uv).rgb;
        float heat=max(0.0f,lava.r);
        float glowMask=smoothstep(0.24f,0.58f,heat);
        float core=smoothstep(0.36f,0.86f,heat);
        float fill=pow(clamp(heat,0.0f,1.0f),0.90f);
        float crack=smoothstep(0.52f,0.94f,heat);
        float3 hot=mix(float3(0.36f,0.10f,0.03f),
                       float3(1.0f,0.40f,0.09f),core);
        ink+=(float3(1.0f,0.30f,0.07f)*core*0.68f
            +float3(0.66f,0.23f,0.06f)*fill*0.34f
            +hot*crack*0.22f)*glowMask*clamp(u.glowPower,0.0f,4.0f);
    }
    return float4(clamp(ink,0.0f,1.0f),clamp(base.a,0.0f,1.0f));
}

struct Home291BeaconVertex {
    float4 position;
    float4 tint;
};
struct Home291BeaconOutput {
    float4 position [[position]];
    float4 tint;
};
vertex Home291BeaconOutput home291BeaconVertex(
    uint id [[vertex_id]],
    device const Home291BeaconVertex *segments [[buffer(0)]],
    constant float4x4 &viewProjection [[buffer(1)]])
{
    Home291BeaconOutput o;
    o.position=viewProjection*segments[id].position;
    o.tint=segments[id].tint;
    return o;
}
fragment float4 home291BeaconFragment(Home291BeaconOutput in [[stage_in]]) {
    // Source HomeScene291 uses (GL_SRC_ALPHA, GL_ONE) and glDepthMask(0).
    return in.tint;
}
