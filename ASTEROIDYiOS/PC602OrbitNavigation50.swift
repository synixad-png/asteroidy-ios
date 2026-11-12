import Foundation

/// Exact PC v602 Windows/src/Orbit50.cs OrbitNavigation50 and
/// GpuIntro41.IntroProject: actual H290 beacon / terrain visibility,
/// source route vector and offscreen arrow. Same world-view matrix used
/// by PC602HomeScene291 Metal; no guessed compass target coordinates.
enum PC602OrbitNavigation50 {
    struct Arrow {
        let x:Float
        let y:Float
        let dx:Float
        let dy:Float
    }
    private static func length(_ v:SIMD3<Float>)->Float {
        sqrt(v.x*v.x+v.y*v.y+v.z*v.z)
    }
    private static func unit(_ v:SIMD3<Float>)->SIMD3<Float> {
        let n=length(v)
        return n>0.00001 ? v/n : SIMD3<Float>(repeating:0)
    }

    static func arrow(flight:PC602HomeFlight291,
                      width:Float,height:Float)->Arrow? {
        guard width>0,height>0,let destination=flight.home.beacon(flight.target),
              let view=PC602HomeWorldView291(
                  camera:flight.flight.camera,aspect:width/height)
        else{return nil}
        if flight.home.isInMissionArea(flight.orbitPosition,level:flight.target) &&
           PC602HomeFlight291.unlocked(flight.target,mask:flight.completedMask) {
            return nil // PC602 OrbitMissionReady51: no offscreen arrow in zone.
        }
        let m=view.view
        func project(_ p:SIMD3<Float>)->(x:Float,y:Float,depth:Float) {
            let x=m[0]*p.x+m[4]*p.y+m[8]*p.z+m[12]
            let y=m[1]*p.x+m[5]*p.y+m[9]*p.z+m[13]
            let z=-(m[2]*p.x+m[6]*p.y+m[10]*p.z+m[14])
            // IntroProject: 640+x*720/depth, 360-y*720/depth
            // Preserve the original source vertical FOV for any iOS aspect.
            return (width*0.5+x*height/max(0.01,z),
                    height*0.5-y*height/max(0.01,z),z)
        }
        let visible=PC602HomeWorldView291.visible(
            from:view.eye,to:destination,on:flight.home)
        var candidate=project(destination)
        if !(candidate.depth>0.4 && visible) {
            guard let route=PC602OrbitHud330.routeDirection(flight)
            else{return nil}
            let goal=flight.orbitPosition+route*36+
                     unit(flight.orbitPosition)*3
            candidate=project(goal)
        }
        var dx=candidate.x-width*0.5
        var dy=candidate.y-height*0.5
        if candidate.depth<=0.4 {
            guard let route=PC602OrbitHud330.routeDirection(flight)
            else{return nil}
            dx=(m[0]*route.x+m[4]*route.y+m[8]*route.z)*500*(width/1280)
            dy=-(m[1]*route.x+m[5]*route.y+m[9]*route.z)*245*(height/720)
            if abs(dx)+abs(dy)<20 {dx=500*(width/1280)}
        }
        let horizontalLimit=540*(width/1280)
        let verticalLimit=245*(height/720)
        let scale=max(1,max(abs(dx)/max(1,horizontalLimit),
                            abs(dy)/max(1,verticalLimit)))
        let x=width*0.5+dx/scale
        let y=max(height*255/720,min(height*605/720,
                                      height*0.5+dy/scale))
        let magnitude=length(SIMD3(dx,dy,0))
        if magnitude<1 {dx=0;dy = -1}
        let norm=max(1,magnitude)
        return Arrow(x:x,y:y,dx:dx/norm,dy:dy/norm)
    }
}
