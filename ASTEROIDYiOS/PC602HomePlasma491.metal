#include <metal_stdlib>
using namespace metal;

// Exact port of Windows/src/GpuShip.cs:19-63 (v491 plasma):
// two SOURCE 4311 EngineCenters, 3 layers x 3 crossed planes x
// 16 authored travelling segments x 2 triangles. No particle emitter,
// random jitter, sprite, HTML or per-frame generated GPU mesh.
struct PC602HomePlasmaUniform491 {
    float4x4 mvp;
    float4 engine0;
    float4 engine1;
    float4 timePowerSideSize; // time, visualPower, SideThrust, VisualSize172
};
struct PC602HomePlasmaVertex491 {
    float4 position [[position]];
    float4 tint;
};
vertex PC602HomePlasmaVertex491 pc602HomePlasmaVertex491(
    uint id [[vertex_id]],
    constant PC602HomePlasmaUniform491 &u [[buffer(0)]])
{
    const uint segmentVertices=6u;
    const uint planeVertices=16u*segmentVertices;
    const uint layerVertices=3u*planeVertices;
    const uint engineVertices=3u*layerVertices;
    float time=u.timePowerSideSize.x;
    float power=clamp(u.timePowerSideSize.y,0.0f,1.0f);
    float side=u.timePowerSideSize.z;
    float visualSize=u.timePowerSideSize.w;
    float3 point;
    float4 rgba;
    if(id<2u*engineVertices) {
        uint engine=id/engineVertices;
        uint slot=id%engineVertices;
        uint layer=slot/layerVertices;
        slot%=layerVertices;
        uint plane=slot/planeVertices;
        slot%=planeVertices;
        uint segment=slot/6u;
        uint corner=slot%6u;

        // GL_TRIANGLES: (first left, first right, next left),
        // then (next left, first right, next right).
        bool second=corner==2u || corner==3u || corner==5u;
        bool positive=corner==0u || corner==2u || corner==3u;
        float t=float(segment+(second?1u:0u))/16.0f;
        float3 origin=(engine==0u?u.engine0:u.engine1).xyz;
        float x=origin.x,ey=origin.y,z=origin.z;
        float plume=.17f+power*1.47f;
        float radial=layer==0u?.12f:(layer==1u?.072f:.030f);
        float alpha=layer==0u?.21f:(layer==1u?.48f:.82f);
        float angle=float(plane)*3.14159265359f/3.0f;
        float dx=cos(angle),dz=sin(angle);
        float offset=sin(t*11-time*11+float(plane)*1.9f+x*2.0f)*
                     t*t*.075f*power;
        float spread=pow(max(.035f,1.0f-t),.58f)*
                     (1.0f+.11f*sin(t*28-time*21+float(plane)));
        float width=visualSize*radial*spread;
        float fade=alpha*(1.0f-t*t)*
                  (.83f+.17f*sin(time*19-t*37+float(plane)));
        float g=layer==2u ? .96f-.19f*t :
                layer==1u ? .65f-.27f*t : .27f-.14f*t;
        float b=layer==2u ? .49f*(1.0f-t):.035f;
        float sign=positive ? 1.0f:-1.0f;
        point=float3(x+offset+sign*dx*width,
                     ey-plume*t,z+sign*dz*width);
        rgba=float4(1.0f,g,b,fade);
    } else {
        // Source Ship.cs:62 side-thruster uses 8 authored triangle wedges,
        // only when SideThrust is nonzero; the native caller skips this
        // 24-vertex range entirely when no side thrust is applied.
        uint k=(id-2u*engineVertices)/3u;
        uint corner=(id-2u*engineVertices)%3u;
        float sign=side>0 ? 1.0f:-1.0f;
        float x=-sign*1.28f;
        float a=float(k)*3.14159265359f/4.0f;
        float b=float(k+1u)*3.14159265359f/4.0f;
        if(corner==2u) {
            point=float3(x-sign*(.28f+.36f*abs(side)),-.77f,.02f);
            rgba=float4(1.0f,.26f,.02f,0.0f);
        } else {
            float angle=corner==0u ? a:b;
            point=float3(x,-.77f+cos(angle)*.05f,
                         .02f+sin(angle)*.05f);
            rgba=float4(1.0f,.75f,.24f,.75f);
        }
    }
    PC602HomePlasmaVertex491 out;
    out.position=u.mvp*float4(point,1.0f);
    out.tint=rgba;
    return out;
}
fragment float4 pc602HomePlasmaFragment491(
    PC602HomePlasmaVertex491 in [[stage_in]]) {
    return in.tint;
}
