#include "SourceHome290Vertex.metalh"

// The original W3 preview vertex entry point is kept unchanged. The shared
// H290 source decoder is also used by the real PC602 orbital world renderer.
vertex W3Home290Output w3Home290Vertex(
    uint id [[vertex_id]],
    device const float *mesh [[buffer(0)]],
    constant W3Home290Uniforms& u [[buffer(1)]])
{
    return sourceHome290Vertex(id,mesh,u);
}

fragment float4 w3Home290Fragment(
    W3Home290Output in [[stage_in]],
    constant W3Home290Uniforms& u [[buffer(1)]],
    texture2d<float> baseMap [[texture(0)]],
    texture2d<float> glowMap [[texture(1)]])
{
    constexpr sampler sourceSampler(coord::normalized, address::repeat,
                                    filter::linear);
    float4 base=in.color;
    if(u.material==0u)
        base*=baseMap.sample(sourceSampler,in.uv);
    float3 n=normalize(in.normal);
    // Directional-preview lighting: GpuToon60's smooth branch baseline.
    // Original FighterLight / orbit sun state needs a separate source audit.
    // Windows/src/GpuShip.cs FighterLight(false): keyPosition
    // = {-0.6f, 0.8f, 1.4f, 0}; directional source light in eye space.
    // OpenGL was configured before the HomePlanetPreview333 model transforms.
    float3 l=normalize(float3(-0.6f,0.8f,1.4f));
    float d=max(0.0f,dot(n,l));
    float band=0.25f+0.78f*d;
    float3 view=normalize(float3(0.0f,0.0f,6.0f)-in.viewPosition);
    float rim=0.10f*smoothstep(0.72f,0.86f,1.0f-max(0.0f,dot(n,view)))
               *smoothstep(0.10f,0.30f,d);
    float3 ink=base.rgb*(band+rim);
    if(u.material==0u){
        // Exact v568 GpuToon60.cs HOME glow recipe in the SAME fragment pass.
        float heat=max(0.0f,glowMap.sample(sourceSampler,in.uv).r);
        float glowMask=smoothstep(0.24f,0.58f,heat);
        float core=smoothstep(0.36f,0.86f,heat);
        float fill=pow(clamp(heat,0.0f,1.0f),0.90f);
        float crack=smoothstep(0.52f,0.94f,heat);
        float3 hot=mix(float3(0.36f,0.10f,0.03f),
                       float3(1.0f,0.40f,0.09f),core);
        ink+=(float3(1.0f,0.30f,0.07f)*core*0.68f
             +float3(0.66f,0.23f,0.06f)*fill*0.34f
             +hot*crack*0.22f)*glowMask*u.glowPower;
    }
    return float4(clamp(ink,0.0f,1.0f),clamp(base.a,0.0f,1.0f));
}
