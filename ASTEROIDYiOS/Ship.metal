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
