#include <metal_stdlib>
using namespace metal;

// v469 Windows/src/GpuPlanet.cs:175-225 caches ONE combined CARBONIS
// texture on a source brightness change. The previous iOS fragment
// re-sampled three 4K images on every pixel of every gameplay frame.
// Bake once on Metal, rather than forcing 3 texture fetches per pixel
// and repeated hot-mask/irradiance arithmetic each frame. Source
// dimensions, UV and slider brightness are not reduced or quantized.
kernel void sector01SourceCarbonisBake469(
    texture2d<float, access::sample> base [[texture(0)]],
    texture2d<float, access::sample> emission [[texture(1)]],
    texture2d<float, access::sample> irradiance [[texture(2)]],
    texture2d<float, access::write> combined [[texture(3)]],
    constant float &lavaBoost [[buffer(0)]],
    uint2 gid [[thread_position_in_grid]])
{
    uint width=combined.get_width();
    uint height=combined.get_height();
    if(gid.x>=width || gid.y>=height) return;
    // GpuPlanet.cs:185-191 resizes irradiance with GDI+ bilinear
    // clamped edges, not a wrapped UV seam. Target base/emission already
    // match source resolution; sample their texel centers unchanged.
    constexpr sampler sourceSampler(coord::normalized,address::clamp_to_edge,
                                    filter::linear);
    float2 uv=(float2(gid)+0.5f)/float2(width,height);
    float4 sourceBase=base.sample(sourceSampler,uv);
    float3 hot=emission.sample(sourceSampler,uv).rgb;
    float3 ambient=irradiance.sample(sourceSampler,uv).rgb;
    float heat469=max(max(hot.r,hot.g),hot.b);
    float mask469=smoothstep(0.12f,0.46f,heat469);
    float strength469=clamp(lavaBoost,0.0f,4.0f);
    float irradiation469=min(1.0f,lavaBoost*0.45f)*0.38f;
    float3 result=clamp(
        sourceBase.rgb+
        hot*strength469*mask469*float3(1.0f,0.8f,0.5f)+
        ambient*irradiation469,0.0f,1.0f);
    combined.write(float4(result,sourceBase.a),gid);
}
