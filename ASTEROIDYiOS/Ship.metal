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

// Original GpuCosmos39.NebulaTexture (two 256px array slices) and
// GpuIntro41 IntroSky clouds. Each of 36 quads carries its original
// 3D sky direction and 2D UVs; shader projects SkyProject55 at draw
// time, preserving camera-only orientation and exact per-layer bounds.
// Color RGB is white with source CloudLayer alpha, PArgb premultiplied.
struct NebulaOverlayUniforms {
    float4 right;
    float4 up;
    float4 back;
    float4 ndc; // 2/(720*aspect), -2/720, unused, unused
};
struct NebulaOverlayRaster {
    float4 position [[position]];
    float4 color;
    float2 uv;
    float theme;
};
vertex NebulaOverlayRaster nebulaOverlayVertex(
    uint vid [[vertex_id]],
    constant Vertex3D *vertices [[buffer(0)]],
    constant NebulaOverlayUniforms &camera [[buffer(1)]]) {
    Vertex3D v=vertices[vid];
    NebulaOverlayRaster out;
    out.uv=v.normal.xy;
    out.color=float4(v.color.rgb*v.color.a,v.color.a);
    out.theme=v.material.y;
    bool nearLayer=v.material.x>0.5f;
    float3 d=v.position.xyz;
    float depth=-dot(camera.back.xyz,d);
    float sourceX=dot(camera.right.xyz,d)*720.0f/max(0.01f,depth);
    float sourceY=-dot(camera.up.xyz,d)*720.0f/max(0.01f,depth);
    bool visible=depth>0.4f;
    float x=sourceX+640.0f;
    float y=sourceY+360.0f;
    if (nearLayer) {
        visible = visible && x>-900.0f && x<2180.0f &&
                  y>-600.0f && y<1320.0f;
    } else {
        visible = visible && x>-500.0f && x<1780.0f &&
                  y>-400.0f && y<1120.0f;
    }
    if (!visible) {
        out.position=float4(2.0f,2.0f,0.0f,1.0f);
        return out;
    }
    float size=nearLayer
        ? 720.0f*220.0f/depth
        : min(650.0f,720.0f*190.0f/depth);
    float px=sourceX+(v.normal.x*2.0f-1.0f)*size;
    float py=sourceY+(v.normal.y*2.0f-1.0f)*size*
                     (nearLayer ? 0.55f : 0.24f);
    out.position=float4(px*camera.ndc.x,py*camera.ndc.y,0.0f,1.0f);
    return out;
}
fragment float4 nebulaOverlayFragment(
    NebulaOverlayRaster in [[stage_in]],
    texture2d_array<float> sourceClouds [[texture(0)]]) {
    constexpr sampler sourceSampler(coord::normalized,
                                    address::clamp_to_edge,
                                    filter::linear);
    uint slice=uint(in.theme+0.5f);
    // Original GpuCosmos39 uses PArgb BGRA. Multiply the stored
    // premultiplied cloud alpha/color by source white-layer alpha.
    return in.color * sourceClouds.sample(sourceSampler,in.uv,slice);
}

// Windows/src/GpuIntro41.cs DrawSkyBlackHole55: three real 640px
// PArgb image slices (back/core/front) plus 3 IntroHalo and 4 DrawRay55
// quads. Original painter order is 10 quads / 60 vertices for glow on.
// All dynamic ray rotation/scales are passed as one tiny uniform array:
// 1 float4 screen projection, then 3 float4 per source layer:
// (radiusX,radiusY,cos,sin), premultiplied tint, (textureSlice,-,-,-).
// textureSlice=-1 uses original 64px StarTexture; 0-2 use the 640px
// disk/core/front array. No per-frame mesh or texture regeneration.
struct BlackHoleRaster55 {
    float4 position [[position]];
    float4 color;
    float2 uv;
    float textureSlice;
};
vertex BlackHoleRaster55 blackHoleVertex55(
    uint vid [[vertex_id]],
    constant float4 *data [[buffer(0)]]) {
    uint layer=vid/6;
    uint corner=vid%6;
    const float2 unit[6]={
        float2(-1,-1),float2(1,-1),float2(1,1),
        float2(-1,-1),float2(1,1),float2(-1,1)
    };
    const float2 uv[6]={
        float2(0,0),float2(1,0),float2(1,1),
        float2(0,0),float2(1,1),float2(0,1)
    };
    float4 frame=data[0];
    float4 shape=data[1+layer*3];
    float4 color=data[2+layer*3];
    float slice=data[3+layer*3].x;
    float2 scaled=unit[corner]*shape.xy;
    float2 rotated=float2(
        scaled.x*shape.z-scaled.y*shape.w,
        scaled.x*shape.w+scaled.y*shape.z);
    BlackHoleRaster55 out;
    out.position=float4(
        frame.x+rotated.x*frame.z,
        frame.y+rotated.y*frame.w,
        0,1);
    out.color=color;
    out.uv=uv[corner];
    out.textureSlice=slice;
    return out;
}
fragment float4 blackHoleFragment55(
    BlackHoleRaster55 in [[stage_in]],
    texture2d_array<float> diskCoreFront [[texture(0)]],
    texture2d<float> originalHalo [[texture(1)]]) {
    constexpr sampler originalSampler(coord::normalized,
                                      address::clamp_to_edge,
                                      filter::linear);
    float4 sampled=in.textureSlice<0
       ? originalHalo.sample(originalSampler,in.uv)
       : diskCoreFront.sample(originalSampler,in.uv,
                              uint(in.textureSlice+0.5f));
    return sampled*in.color;
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


// Windows/src/GpuShip.cs:19-63, v491 sustained 3D twin-engine
// plasma, rendered AFTER fighter with additive src-alpha/ONE blending.
// Original source produces 2*3*3*16*6 = 1728 triangle vertices.
// Positions, opacity, warm-white/orange/ember RGB and traveling sine
// waves are calculated directly by GPU vertex_id: zero transient
// per-frame CPU meshes or buffers, no inaccurate v490 blue wedges.
struct FighterPlasmaUniform491 {
    float4x4 mvp;
    float4 engine0;
    float4 engine1;
    float4 frame; // time, thrust (0..1), visualSize172=1.06, unused
};
struct FighterPlasmaRaster491 {
    float4 position [[position]];
    float4 color;
};

vertex FighterPlasmaRaster491 fighterPlasmaVertex491(
    uint vertexID [[vertex_id]],
    constant FighterPlasmaUniform491 &source [[buffer(0)]]) {
    uint engineIndex=vertexID/(3u*3u*16u*6u);
    uint layer=(vertexID/(3u*16u*6u))%3u;
    uint plane=(vertexID/(16u*6u))%3u;
    uint i=(vertexID/6u)%16u;
    uint corner=vertexID%6u;
    bool atStart=(corner==0u||corner==1u||corner==4u);
    bool positive=(corner==0u||corner==2u||corner==3u);
    float u=float(atStart ? i : i+1u)/16.0f;
    float3 engine=engineIndex==0u
        ? source.engine0.xyz : source.engine1.xyz;
    float x=engine.x,ey=engine.y,z=engine.z;
    float t=source.frame.x;
    float power=clamp(source.frame.y,0.0f,1.0f);
    float sz=source.frame.z;
    float plume=0.17f+power*1.47f;
    float radial=layer==0u ? 0.12f : layer==1u ? 0.072f : 0.030f;
    float alpha=layer==0u ? 0.21f : layer==1u ? 0.48f : 0.82f;
    float angle=float(plane)*M_PI_F/3.0f;
    float dx=cos(angle),dz=sin(angle);
    float off=sin(u*11.0f-t*11.0f+float(plane)*1.9f+x*2.0f) *
        u*u*0.075f*power;
    float spread=pow(max(0.035f,1.0f-u),0.58f) *
        (1.0f+0.11f*sin(u*28.0f-t*21.0f+float(plane)));
    float width=sz*radial*spread;
    float fade=alpha*(1.0f-u*u) *
        (0.83f+0.17f*sin(t*19.0f-u*37.0f+float(plane)));
    float side=positive ? 1.0f : -1.0f;
    float3 pos=float3(x+off+side*dx*width,
                      ey-plume*u,z+side*dz*width);
    float g=layer==2u ? 0.96f-0.19f*u :
        layer==1u ? 0.65f-0.27f*u : 0.27f-0.14f*u;
    float b=layer==2u ? 0.49f*(1.0f-u) : 0.035f;
    FighterPlasmaRaster491 out;
    out.position=source.mvp*float4(pos,1.0f);
    out.color=float4(1.0f,g,b,fade);
    return out;
}

fragment float4 fighterPlasmaFragment491(
    FighterPlasmaRaster491 in [[stage_in]]) {
    // The GL GpuShip.cs line 22 uses Blend(SRC_ALPHA,ONE), no premul.
    return in.color;
}
