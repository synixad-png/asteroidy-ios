#include <metal_stdlib>
using namespace metal;
struct Vertex3D { float4 position; float4 color; float4 normal; float4 material; };
struct SceneUniforms { float4x4 mvp; float4x4 model; float4 lighting; };
struct RasterOutput {
    float4 position [[position]];
    float4 color;
    float3 normal;
    float3 worldPosition;
    float3 cameraEye;
    float unlit;
    float4 material;
};
vertex RasterOutput sceneVertex(uint vid [[vertex_id]],
                               constant Vertex3D *vertices [[buffer(0)]],
                               constant SceneUniforms &scene [[buffer(1)]]) {
    RasterOutput o;
    Vertex3D v = vertices[vid];
    o.position = scene.mvp * v.position;
    o.worldPosition = (scene.model * v.position).xyz;
    o.cameraEye = scene.lighting.yzw;
    // The current renderer uses uniform scales only, hence transformed normals
    // can be normalized in the fragment stage without inverse-transpose.
    o.normal = (scene.model * float4(v.normal.xyz, 0.0)).xyz;
    o.color = v.color;
    o.unlit = scene.lighting.x;
    o.material = v.material;
    return o;
}
// Exact Windows/src/GpuAmbient37.cs:5 StarTexture() is uploaded as a
// premultiplied 64x64 BGRA texture generated at initialization. GpuIntro41
// IntroHalo draws its pixel-accurate 10px/21px additional bright-star layer
// BEFORE the normal 2*size-radius halo; both use the same source texture.
// GPU point sprites are the iOS equivalent of the original 2D halo quads.
struct SkyPointOutput {
    float4 position [[position]];
    float pointSize [[point_size]];
    float4 color;
};
// Metal Shading Language: [[point_size]] is a VERTEX output only,
// and must not appear as an input to a fragment [[stage_in]] struct.
// Fragment receives position and color, while point_coord is provided
// separately by the rasterizer.
struct SkyPointFragmentInput {
    float4 position [[position]];
    float4 color;
};
vertex SkyPointOutput skyPointVertex(
    uint vid [[vertex_id]],
    constant Vertex3D *vertices [[buffer(0)]],
    constant SceneUniforms &scene [[buffer(1)]]) {
    Vertex3D star = vertices[vid];
    SkyPointOutput out;
    out.position = scene.mvp * star.position;
    // scene.lighting.x carries drawableHeight/720 for this sky-only
    // uniform. star.material.x remains the exact C# source pixel size.
    out.pointSize = max(1.0f, star.material.x * scene.lighting.x);
    // Gpu2DRenderer.Vertex2D premultiplies tint by Color.A/255.
    // StarTexture is itself premultiplied white. Use source blend ONE,
    // ONE_MINUS_SRC_ALPHA, not the earlier sourceAlpha convention.
    out.color = float4(star.color.rgb*star.color.a,star.color.a);
    return out;
}
fragment float4 skyPointFragment(
    SkyPointFragmentInput in [[stage_in]],
    float2 uv [[point_coord]],
    texture2d<float> sourceHalo [[texture(0)]]) {
    // Exact 64x64 PArgb StarTexture from GpuAmbient37.cs. The uploaded
    // BGRA texels have B=G=R=A=the original byte alpha and use LINEAR
    // filtering like the original GL SetFilter(true). Vertex tint is
    // already premultiplied by its source Color.A.
    constexpr sampler sourceSampler(coord::normalized,
                                    address::clamp_to_edge,
                                    filter::linear);
    float4 mask=sourceHalo.sample(sourceSampler,uv);
    return in.color*mask;
}

// Windows GpuIntro41.cs:454 solar flare/rays are 2D AFTER SkyProject55.
// Offset vertices were generated once by GpuCosmos39.RayVertex in source
// 1280x720 pixel coordinates. Only the 2D solar center changes with the
// sphere camera; no GPU model-space approximation or per-frame rebuild.
// centerScale=(sun NDC x, sun NDC y, 2/(720*aspect), -2/720).
struct SolarOverlayUniforms { float4 centerScale; };
struct SolarOverlayRaster {
    float4 position [[position]];
    float4 color;
    float2 uv;
    float textured;
};
vertex SolarOverlayRaster solarOverlayVertex(
    uint vid [[vertex_id]],
    constant Vertex3D *vertices [[buffer(0)]],
    constant SolarOverlayUniforms &info [[buffer(1)]]) {
    Vertex3D v=vertices[vid];
    SolarOverlayRaster out;
    out.position=float4(
        info.centerScale.x+v.position.x*info.centerScale.z,
        info.centerScale.y+v.position.y*info.centerScale.w,
        0.0,1.0);
    // C# Gpu2DRenderer.Vertex2D premultiplies all RGB by source alpha.
    out.color=float4(v.color.rgb*v.color.a,v.color.a);
    out.uv=v.normal.xy;
    out.textured=v.material.x;
    return out;
}
fragment float4 solarOverlayFragment(
    SolarOverlayRaster in [[stage_in]],
    texture2d<float> sourceHalo [[texture(0)]]) {
    if (in.textured < 0.5) return in.color;
    constexpr sampler originalHalo(coord::normalized,
                                   address::clamp_to_edge,
                                   filter::linear);
    return in.color*sourceHalo.sample(originalHalo,in.uv);
}

// Single directional-light Cook-Torrance GGX BRDF, without environment IBL or
// texture maps. Metallic/roughness values are sourced from original glTF factors.
fragment float4 sceneFragment(RasterOutput in [[stage_in]]) {
    if (in.unlit > 0.5) return in.color;
    const float3 L = normalize(float3(0.48, 0.68, 0.56));
    // v556 SphereCombat67/GpuSphere67 orbits the combat planet. The
    // fragment view vector must use the same camera as MetalRenderer's MVP.
    const float3 V = normalize(in.cameraEye - in.worldPosition);
    const float3 N = normalize(in.normal);
    const float3 H = normalize(V + L);
    const float metallic = clamp(in.material.x, 0.0, 1.0);
    const float roughness = clamp(in.material.y, 0.04, 1.0);
    const float alpha = roughness * roughness;
    const float a2 = alpha * alpha;
    const float NdotL = max(dot(N,L), 0.0);
    const float NdotV = max(dot(N,V), 0.001);
    const float NdotH = max(dot(N,H), 0.0);
    const float HdotV = max(dot(H,V), 0.0);
    const float denom = NdotH * NdotH * (a2 - 1.0) + 1.0;
    const float D = a2 / max(M_PI_F * denom * denom, 0.00001);
    const float k = (roughness + 1.0) * (roughness + 1.0) / 8.0;
    const float Gv = NdotV / (NdotV * (1.0 - k) + k);
    const float Gl = NdotL / (NdotL * (1.0 - k) + k);
    const float3 baseColor = clamp(in.color.rgb, 0.0, 1.0);
    const float3 F0 = mix(float3(0.04), baseColor, metallic);
    const float3 F = F0 + (1.0 - F0) * pow(1.0 - HdotV, 5.0);
    const float3 specular = (D * Gv * Gl * F) / max(4.0 * NdotV * NdotL, 0.001);
    const float3 diffuse = (1.0 - F) * (1.0 - metallic) * baseColor / M_PI_F;
    const float hemi = 0.5 + 0.5 * N.y;
    const float3 ambient = baseColor * (1.0 - metallic * 0.85) * (0.045 + hemi * 0.09);
    const float3 radiance = float3(1.5, 1.4, 1.25);
    // Simplified direct-light clearcoat lobe. Clearcoat is dielectric and
    // does not change base metallic. Not yet full KHR_materials_clearcoat:
    // no independent clearcoat normal texture or environment reflections.
    const float coat = clamp(in.material.z, 0.0, 1.0);
    const float coatRoughness = clamp(in.material.w, 0.04, 1.0);
    const float coatAlpha = coatRoughness * coatRoughness;
    const float coatA2 = coatAlpha * coatAlpha;
    const float coatDenom = NdotH * NdotH * (coatA2 - 1.0) + 1.0;
    const float coatD = coatA2 / max(M_PI_F * coatDenom * coatDenom, 0.00001);
    const float coatK = (coatRoughness + 1.0) * (coatRoughness + 1.0) / 8.0;
    const float coatGv = NdotV / (NdotV * (1.0 - coatK) + coatK);
    const float coatGl = NdotL / (NdotL * (1.0 - coatK) + coatK);
    const float coatF = 0.04 + 0.96 * pow(1.0 - HdotV, 5.0);
    const float coatSpecular = coat * coatD * coatGv * coatGl * coatF / max(4.0 * NdotV * NdotL, 0.001);
    const float coatAttenuation = 1.0 - coat * coatF;
    const float3 shaded = ambient + (diffuse + specular) * radiance * NdotL;
    return float4(clamp(shaded * coatAttenuation + coatSpecular * radiance * NdotL, 0.0, 1.0), in.color.a);
}
