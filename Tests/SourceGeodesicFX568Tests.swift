import Foundation

/// CPU-only parity with the ORIGINAL Sphere67.delta/Sphere67.offset six-piece
/// geodesic path, before using the faster recurrence in live explosion FX.
/// This does not assert iPad/iPhone Metal frame time.
@main struct SourceGeodesicFX568Tests {
    static func almost(_ a:SphereVector3,_ b:SphereVector3,_ tolerance:Float,
                       _ description:String) {
        let error=(a-b).length
        precondition(error<=tolerance,
            "\(description): reference geodesic error \(error) > \(tolerance)")
    }
    static func main() {
        var seed:UInt32=0x29fe081
        func random()->Float {
            seed=seed &* 1664525 &+ 1013904223
            return Float(seed & 0x00ffffff)/16777216
        }
        let count=2400
        var pairs:[(Vec2,Vec2)]=[]
        pairs.reserveCapacity(count)
        for _ in 0..<count {
            let origin=Vec2(x:random()*1280,
                            y:15+random()*690)
            let motion=Vec2(x:(random()-0.5)*140,
                            y:(random()-0.5)*140)
            let destination=Sphere67.offset(origin,by:motion)
            pairs.append((origin,destination))
        }
        var worst:Float=0
        for (origin,destination) in pairs {
            let delta=Sphere67.delta(target:destination,origin:origin)
            var arc=SourceGeodesicStep568(from:origin,to:destination,steps:6)
            almost(arc.origin,Sphere67.normal(origin),0.000002,
                   "first source arc point")
            for j in 1...6 {
                let original=Sphere67.normal(Sphere67.offset(
                    origin,by:delta*(Float(j)/6)))
                let actual=arc.nextUnit()
                let error=(original-actual).length
                worst=max(worst,error)
                almost(actual,original,0.00005,
                       "original 6-segment arc at \(origin) step \(j)")
            }
        }

        // Visibility gates exist ONLY in live gameplay (aspect is passed);
        // the archived source test and explosion preview omit aspect.
        let near=Vec2(x:640,y:360)
        let far=Vec2(x:0,y:360)
        let camera=SphereCamera67(at:near)
        var state=CarbonisDestruction524()
        state.light(at:near,kind:0,life:0.9)
        let nearBaseline=CarbonisExplosion524Meshes.vertices(
            state,time:0.2,camera:camera)
        let nearLive=CarbonisExplosion524Meshes.vertices(
            state,time:0.2,camera:camera,aspect:16/9)
        precondition(!nearLive.isEmpty && nearBaseline==nearLive,
            "visible source ring must preserve all 32x6 segments")
        state.light(at:far,kind:0,life:0.9)
        let bothBaseline=CarbonisExplosion524Meshes.vertices(
            state,time:0.2,camera:camera)
        let bothLive=CarbonisExplosion524Meshes.vertices(
            state,time:0.2,camera:camera,aspect:16/9)
        precondition(bothBaseline.count>nearBaseline.count)
        precondition(bothLive==nearLive,
            "fully hidden back-of-planet ring must not be tessellated")
        // Camera beyond target view can only skip safely occluded geometry.
        // Simulated action/physics source event and life remain untouched.
        precondition(state.lights.count==2 && state.lights[0].life==0.9,
            "visual visibility changed original game event state")

        print("PASS 2,400 original source great-circle ribbons x6 = 14,400 points")
        print("PASS original 32x6 near ring identical, far-side hidden ring omitted")
        print(String(format:"Max unit-sphere error %.9f (limit 0.000050)", worst))
        print("LIMIT: no on-device iPhone/iPad GPU or FPS measurement")
    }
}
