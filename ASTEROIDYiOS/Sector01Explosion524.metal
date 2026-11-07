#include <metal_stdlib>
using namespace metal;

// Literal V8.2 volume/thermal/extinction equations from
// Windows/src/Explosion524.cs:40-123, preserving 13 sampled gas lobes,
// 22 gameplay depth steps, 64^3 xorshift noise, and source color curves.
// One camera-facing 3D volume bound per actual Game.SpawnDestruction524;
// not a static explosion billboard or a 2D animated sprite.
struct CarbonisExplosion524Uniforms {
    float4x4 mvp;
    float age,scale,fire,smoke,chaos,spread,seed;
    uint lobeCount,stepCount,kind;
};
// Invariant per-lobe data is calculated once per event on CPU, rather than
// re-evaluated at every pixel AND every depth sample on mobile GPU.
struct CarbonisExplosion524Lobe {
    float4 directionFire;  // xyz direction, w thermal amplitude
    float4 centerRadius;   // xyz time-dependent center, w lobe radius
    float4 smokePhase;     // x smoke amplitude, y granularity phase
};
struct CarbonisExplosion524Raster {
    float4 position [[position]];
    float2 uv;
};
vertex CarbonisExplosion524Raster sector01ExplosionVertex524(
    uint id [[vertex_id]],
    device const float *mesh [[buffer(0)]],
    constant CarbonisExplosion524Uniforms &u [[buffer(1)]])
{
    uint i=id*5u;
    CarbonisExplosion524Raster o;
    o.position=u.mvp*float4(mesh[i],mesh[i+1],mesh[i+2],1.0f);
    o.uv=float2(mesh[i+3],mesh[i+4]);
    return o;
}

inline float explosionHash524(float n) {
    return fract(sin(n*97.23f+12.4f)*43758.5453f);
}
inline float explosionNoise524(float3 p,
    texture3d<float,access::sample> noise) {
    constexpr sampler s(coord::normalized,address::repeat,filter::linear);
    return noise.sample(s,p/64.0f).r;
}
inline float3 explosionDirection524(uint j) {
    float k=float(j)+0.5f;
    float y=1.0f-2.0f*k/17.0f;
    float a=k*2.399963f;
    float r=sqrt(max(0.0f,1.0f-y*y));
    return float3(cos(a)*r,y,sin(a)*r);
}
inline float3 explosionField524(float3 p,float age,
    texture3d<float,access::sample> noise,
    constant CarbonisExplosion524Uniforms &u,
    constant CarbonisExplosion524Lobe *lobes)
{
    float fire=0.0f,smoke=0.0f,shadow=0.0f;
    float cl=u.chaos;
    float coarse=explosionNoise524(p*2.0f +
        float3(u.seed,-age*0.8f,0.0f),noise);
    float medium=explosionNoise524(p*3.95f +
        float3(11.0f,age*0.5f,u.seed),noise);
    float fine=explosionNoise524(p*7.8f +
        float3(5.0f,3.0f,age*0.4f),noise);
    float3 warp=float3(coarse,medium,fine)-0.5f;
    float3 q=p+warp*0.24f*cl;
    float centerRadius=0.23f+0.21f*age;
    float3 neck=float3(0.08f*sin(age*3.0f),
                         -0.10f+age*0.22f,0.0f);
    float3 rel=(q-neck)/max(0.01f,centerRadius);
    float center=exp(-dot(rel,rel)*1.6f)*exp(-age*1.3f);
    fire+=center*0.85f;
    for(uint i=0;i<17u;++i) {
        if(i>=u.lobeCount)break;
        float4 df=lobes[i].directionFire;
        float4 cr=lobes[i].centerRadius;
        float4 sp=lobes[i].smokePhase;
        float3 d=df.xyz;
        float3 c=cr.xyz;
        float radius=cr.w;
        float3 delta=q-c;
        float along=dot(delta,d);
        float3 transverse=delta-d*along;
        float shape=dot(transverse,transverse)/(radius*radius*0.56f)
            +along*along/(radius*radius*2.0f);
        float edge=exp(-shape*1.05f);
        float granular=clamp(mix(coarse,medium,0.55f)
            +0.23f*sin(sp.y+dot(p-c,d)*3.7f),0.0f,1.0f);
        edge*=mix(0.49f,1.45f,
            smoothstep(0.23f,0.71f,granular));
        fire+=edge*df.w;
        smoke+=edge*sp.x;
        shadow+=edge*max(0.0f,0.6f-granular)*(1.0f+age*0.3f);
    }
    float grain=coarse*0.40f+medium*0.38f+fine*0.22f;
    fire*=mix(0.61f,1.7f,smoothstep(0.23f,0.75f,grain))
        *exp(-max(0.0f,age-0.45f)*1.25f);
    smoke*=mix(0.48f,1.8f,smoothstep(0.20f,0.81f,
        medium*0.7f+coarse*0.3f));
    return float3(fire,smoke,shadow);
}
inline float3 explosionThermal524(float heat) {
    float3 color=float3(0.24f,0.035f,0.008f);
    color=mix(color,float3(0.86f,0.13f,0.018f),
        smoothstep(0.11f,0.42f,heat));
    color=mix(color,float3(1.0f,0.46f,0.065f),
        smoothstep(0.4f,0.7f,heat));
    color=mix(color,float3(1.0f,0.88f,0.42f),
        smoothstep(0.7f,1.0f,heat));
    return color;
}

fragment float4 sector01ExplosionFragment524(
    CarbonisExplosion524Raster in [[stage_in]],
    constant CarbonisExplosion524Uniforms &u [[buffer(1)]],
    texture3d<float,access::sample> noise [[texture(0)]],
    constant CarbonisExplosion524Lobe *lobes [[buffer(2)]])
{
    float age=max(0.0f,u.age);
    if(age>4.8f)discard_fragment();
    float bound=min(5.1f,max(2.6f,
        1.9f+age*1.55f*u.spread))*u.scale;
    float2 xy=(in.uv-0.5f)*2.0f*bound;
    // This radius is the *exact* zero-opacity support from source
    // smoothstep(bound*0.70, bound*0.98, length(p)).
    // Outside it all ray samples have zero alpha. The source flash
    // alone is strictly below the existing 0.012 alpha-discard gate
    // for every supported source scale >= 45%.
    float activeRadius=bound*0.98f;
    float pixelRadius2=dot(xy,xy);
    if(pixelRadius2>=activeRadius*activeRadius)discard_fragment();
    float3 accum=float3(0.0f);
    float transmittance=1.0f;
    float step=2.0f*bound/float(max(1u,u.stepCount));
    // Opacity is EXACTLY zero for length(p) >= 0.98*bound in the
    // original smoothstep below. Trim those empty ray samples without
    // changing sample positions, colors, smoke or alpha.
    float reach2=activeRadius*activeRadius-pixelRadius2;
    uint first=0u,last=0u;
    if(reach2>0.0f) {
        float reach=sqrt(reach2);
        float startIndex=ceil((bound-reach)/step-0.5f);
        float endIndex=ceil((bound+reach)/step-0.5f);
        first=uint(clamp(startIndex,0.0f,float(u.stepCount)));
        last=uint(clamp(endIndex,0.0f,float(u.stepCount)));
    }
    for(uint i=first;i<last;i++) {
        float z=-bound+(float(i)+0.5f)*step;
        float3 p=float3(xy,z);
        float3 fields=explosionField524(p,age,noise,u,lobes);
        float fire=fields.x*u.fire;
        float smoke=fields.y*u.smoke;
        float heat=clamp(fire*0.85f,0.0f,1.0f);
        float soot=clamp(smoke*0.52f+fields.z*0.30f,0.0f,1.0f);
        float cool=smoothstep(0.35f,1.95f,age);
        float hotAlpha=fire*0.29f*(1.0f-cool*0.55f);
        float ashAlpha=smoke*0.18f*cool+smoke*0.032f;
        float opacity=clamp((hotAlpha+ashAlpha)*step*8.0f,
                            0.0f,0.52f);
        opacity*=1.0f-smoothstep(bound*0.70f,
                                 bound*0.98f,length(p));
        float3 hot=explosionThermal524(heat)
            *min(fire*1.6f,2.0f)*(1.25f-cool*0.35f);
        float3 dark=mix(float3(0.20f,0.18f,0.16f),
                        float3(0.085f,0.09f,0.095f),
                        clamp(soot*0.7f,0.0f,1.0f));
        float3 color=mix(hot,dark,
            clamp(cool*0.85f+soot*0.20f,0.0f,0.97f));
        accum+=transmittance*color*opacity;
        transmittance*=1.0f-opacity;
        if(transmittance<0.02f)break;
    }
    float flash=exp(-age*24.0f)*u.fire*1.25f;
    float focus=exp(-dot(xy,xy)*12.0f);
    float3 col=accum+focus*flash*float3(1.0f,0.89f,0.68f);
    col=col/(float3(1.0f)+col*0.35f);
    col=pow(max(col,float3(0.0f)),float3(0.86f));
    if(u.kind==1u) {
        float gray=dot(col,float3(0.299f,0.587f,0.114f));
        col=mix(col,float3(gray)*float3(0.87f,0.82f,0.76f),0.32f);
    }
    if(u.kind==2u) {
        col=mix(col,float3(col.r*0.9f,col.g*0.8f,col.b*1.22f),
                0.25f);
    }
    float alpha=clamp(
        1.0f-transmittance+flash*focus*0.8f,0.0f,1.0f)
        *(1.0f-smoothstep(3.0f,4.8f,age));
    if(alpha<0.012f)discard_fragment();
    return float4(col/max(alpha,0.12f),alpha);
}
