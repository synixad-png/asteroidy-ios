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
    float4 planetSunNight;
    float lavaBoost287;
};
struct CarbonisSectorRaster568 {
    float4 position [[position]];
    float3 normal;
    float4 color;
    float2 uv;
    float3 eyePosition;
    float3 planetPosition;
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
    o.planetPosition=p;
    return o;
}
fragment float4 sector01CarbonisFragment568(
    CarbonisSectorRaster568 in [[stage_in]],
    constant CarbonisSectorUniforms568 &u [[buffer(1)]],
    texture2d<float> combined [[texture(0)]])
{
    constexpr sampler sourceSampler(coord::normalized,address::repeat,
                                    filter::linear);
    float4 albedo=in.color;
    if(u.material==0u){
        // Source Windows v469: source maps were COMBINED ONCE at
        // creation/brightness change. The 3-source blend formula
        // runs in sector01SourceCarbonisBake469, not once per fragment.
        float4 sourceCombined=combined.sample(sourceSampler,in.uv);
        albedo.rgb*=sourceCombined.rgb;
        albedo.a*=sourceCombined.a;
    }
    float sunlight=max(0.0f,dot(normalize(in.normal),
                       normalize(float3(-0.6f,0.8f,1.4f))));
    // Lighting remains a partial iOS port, but source emission/irradiance
    // composition and its user value are no longer arbitrary approximations.
    float3 lit=clamp(albedo.rgb,0.0f,1.0f)*(0.24f+sunlight*0.72f);
    // Windows GpuToon60.cs:202: terminator on the *planet only*.
    // Disabled source light uses night factor 1, preserving the
    // previous planet appearance; actors/ship/rock are unchanged.
    float h436=dot(normalize(in.planetPosition),
                   normalize(u.planetSunNight.xyz));
    float k436=smoothstep(-0.14f,0.18f,h436);
    lit*=mix(clamp(u.planetSunNight.w,0.0f,1.0f),1.0f,k436);
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

// GpuRockInstancing75: shared original mesh with per-instance transforms.
// This path uses the same instance Uniforms ABI as the legacy rock renderer.
struct CarbonisRockRasterInstanced568 {
    float4 position [[position]];
    float3 normal;
    float4 color;
    float3 eyePosition;
    uint instanceIndex [[flat]];
};
vertex CarbonisRockRasterInstanced568 sector01RockInstancedVertex568(
    uint id [[vertex_id]],
    uint instanceIndex [[instance_id]],
    device const float *mesh [[buffer(0)]],
    device const CarbonisSectorUniforms568 *instances [[buffer(1)]])
{
    const CarbonisSectorUniforms568 u=instances[instanceIndex];
    const uint i=id*12u;
    const float3 p=float3(mesh[i],mesh[i+1],mesh[i+2]);
    CarbonisRockRasterInstanced568 o;
    o.position=u.mvp*float4(p,1);
    float3x3 axes=float3x3(u.model[0].xyz,
                         u.model[1].xyz,
                         u.model[2].xyz);
    o.normal=normalize(axes*float3(mesh[i+3],mesh[i+4],mesh[i+5]));
    o.color=float4(mesh[i+6],mesh[i+7],mesh[i+8],mesh[i+9]);
    o.eyePosition=(u.model*float4(p,1)).xyz;
    o.instanceIndex=instanceIndex;
    return o;
}
fragment float4 sector01RockInstancedFragment568(
    CarbonisRockRasterInstanced568 in [[stage_in]],
    device const CarbonisSectorUniforms568 *instances [[buffer(1)]])
{
    const CarbonisSectorUniforms568 u=instances[in.instanceIndex];
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

// Source Vanguard431 textured model in the actual CARBONIS gameplay scene.
// Retains original UV/vertex RGBA, reuses the fragment conventions of the
// existing source W3 Vanguard431, distinct from the planet's three textures.
fragment float4 sector01SourceCraftFragment568(
    CarbonisSectorRaster568 in [[stage_in]],
    texture2d<float> skin [[texture(0)]])
{
    constexpr sampler sourceSkin(coord::normalized,address::repeat,filter::linear);
    float4 albedo=in.color*skin.sample(sourceSkin,in.uv);
    float3 n=normalize(in.normal);
    float diffuse=max(0.0f,dot(n,normalize(float3(-0.6f,0.8f,1.4f))));
    float band=.25f+.33f*smoothstep(.30f,.32f,diffuse)
                    +.40f*smoothstep(.70f,.72f,diffuse);
    return float4(clamp(albedo.rgb*band,0.0f,1.0f),clamp(albedo.a,0.0f,1.0f));
}

// The current CARBONIS tactical fire streaks are geometry colored by the
// original pulse/enemy projectile state. Detailed GpuSphere67 beam VFX pending.
fragment float4 sector01CombatTracer568(
    CarbonisSectorRaster568 in [[stage_in]]) {
    return float4(in.color.rgb,in.color.a);
}


// Windows/src/GpuRobot70.cs: ShooterMesh71 uses BossMesh65(type,"drone"),
// eight authored parts from ShipMesh, not a billboard or a repainted
// player Vanguard. Materials 5/6 are emissive cores in original BeginToon60.
// Geometry and material ranges are generated by CarbonisShooterMesh71.swift.
fragment float4 sector01ShooterFragment71(
    CarbonisSectorRaster568 in [[stage_in]],
    constant CarbonisSectorUniforms568 &u [[buffer(1)]])
{
    float3 albedo=in.color.rgb;
    if (u.material==5u || u.material==6u) {
        return float4(albedo,1.0f);
    }
    float light=max(0.0f,dot(normalize(in.normal),
               normalize(float3(-0.6f,0.8f,1.4f))));
    float band=0.25f + 0.33f*smoothstep(0.30f,0.32f,light)
                     + 0.40f*smoothstep(0.70f,0.72f,light);
    return float4(clamp(albedo*band,0.0f,1.0f),in.color.a);
}


// Windows v568 GpuIntro41.cs DrawDetailedResearchWreck211 + GpuSphere67
// DrawCombatResearchWreck214. Original position/normal/RGBA attributes;
// element #11 only identifies the source warning-lamp animation phase.
struct CombatWreckUniforms214 {
    float4x4 mvp;
    float4x4 model;
    float4 sunAndTime; // v269 directional PlanetSun71 and g.Time
};
struct CombatWreckRaster214 {
    float4 position [[position]];
    float3 normal;
    float4 color;
    float phase [[flat]];
};
vertex CombatWreckRaster214 combatWreckTriangleVertex214(
    uint id [[vertex_id]],
    device const float *mesh [[buffer(0)]],
    constant CombatWreckUniforms214 &u [[buffer(1)]]) {
    const uint i=id*11u;
    float3 p=float3(mesh[i],mesh[i+1],mesh[i+2]);
    CombatWreckRaster214 v;
    v.position=u.mvp*float4(p,1);
    float3x3 axes=float3x3(u.model[0].xyz,
                         u.model[1].xyz,
                         u.model[2].xyz);
    v.normal=normalize(axes*float3(mesh[i+3],mesh[i+4],mesh[i+5]));
    v.color=float4(mesh[i+6],mesh[i+7],mesh[i+8],mesh[i+9]);
    v.phase=mesh[i+10];
    return v;
}
fragment float4 combatWreckTriangleFragment214(
    CombatWreckRaster214 in [[stage_in]],
    constant CombatWreckUniforms214 &u [[buffer(1)]]) {
    float3 tint=in.color.rgb;
    if(in.phase > -50.0f) {
        // Exact WreckWarningLamp213: 0.50 + 0.50*sin(g.Time*4.8+phase)
        float pulse=0.5f+0.5f*sin(u.sunAndTime.w*4.8f+in.phase);
        tint *= 0.45f+0.55f*pulse;
    }
    float3 n=normalize(in.normal);
    // GpuPlanet.cs PlanetSun71, planetAmbient269 and planetFill269,
    // GpuShip.cs keyDiffuse/fillPosition source values.
    float main=max(0.0f,dot(n,normalize(u.sunAndTime.xyz)));
    float fill=max(0.0f,dot(n,normalize(float3(1.0f,-0.3f,0.45f))));
    float3 factor=float3(0.045f,0.06f,0.09f)
        +main*float3(0.90f,0.95f,1.0f)
        +fill*float3(0.06f,0.09f,0.13f);
    return float4(clamp(tint*factor,0.0f,1.0f),in.color.a);
}
struct CombatWreckLineRaster214 {
    float4 position [[position]];
    float4 color;
};
vertex CombatWreckLineRaster214 combatWreckLineVertex214(
    uint id [[vertex_id]],
    device const float *mesh [[buffer(0)]],
    constant CombatWreckUniforms214 &u [[buffer(1)]]) {
    const uint i=id*7u;
    CombatWreckLineRaster214 v;
    v.position=u.mvp*float4(mesh[i],mesh[i+1],mesh[i+2],1.0f);
    v.color=float4(mesh[i+3],mesh[i+4],mesh[i+5],mesh[i+6]);
    return v;
}
fragment float4 combatWreckLineFragment214(
    CombatWreckLineRaster214 in [[stage_in]]) {
    return in.color;
}


// PC v586: original opaque GLB pickup triangles, vertex normal and UV.
// Same 12-float Metal geometry ABI and existing gameplay command encoder;
// no SceneKit pass, no per-object importer, no geometry recreation in draw().
struct PickupRaster586 {
    float4 position [[position]];
    float3 normal;
    float2 uv;
    float4 tint;
    float sourceFill;
};
vertex PickupRaster586 sector01PickupVertex586(
    uint id [[vertex_id]],
    device const float *mesh [[buffer(0)]],
    constant CarbonisSectorUniforms568 &u [[buffer(1)]])
{
    uint i=id*12u;
    float3 p=float3(mesh[i],mesh[i+1],mesh[i+2]);
    PickupRaster586 output;
    output.position=u.mvp*float4(p,1);
    float3x3 basis=float3x3(u.model[0].xyz,u.model[1].xyz,u.model[2].xyz);
    output.normal=normalize(basis*float3(mesh[i+3],mesh[i+4],mesh[i+5]));
    output.tint=float4(mesh[i+6],mesh[i+7],mesh[i+8],mesh[i+9]);
    output.uv=float2(mesh[i+10],mesh[i+11]);
    output.sourceFill=max(0.0,u.glow);
    return output;
}
fragment float4 sector01PickupFragment586(
    PickupRaster586 input [[stage_in]],
    texture2d<float> originalSkin [[texture(0)]])
{
    constexpr sampler glbSampler(coord::normalized,
                                  address::repeat,filter::linear);
    float4 texel=originalSkin.sample(glbSampler,input.uv);
    float3 n=normalize(input.normal);
    float sun=max(0.0f,dot(n,normalize(float3(-0.6f,0.8f,1.4f))));
    // 0% brightness preserves original ambient+solar illumination.
    // Only this pickup material sees the PC ItemGlbFill control.
    float illumination=0.28f+0.47f*sun+
        input.sourceFill*(0.22f+0.28f*sun);
    return float4(clamp(texel.rgb*input.tint.rgb*illumination,
                        0.0f,1.0f),1.0f);
}
