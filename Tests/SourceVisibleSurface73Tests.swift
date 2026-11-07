import Foundation

@main struct SourceVisibleSurface73Tests {
    static func main() {
        func ck(_ test:Bool,_ name:String){precondition(test,name)}
        let camera=SphereCamera67(at:Vec2(x:0,y:360))
        let view=SphereCameraView556(camera:camera)
        let front=Vec2(x:0,y:360)
        let back=Vec2(x:640,y:360)
        for aspect:Float in [4.0/3.0,16.0/9.0,19.5/9.0] {
            ck(SourceVisibleSurface73.possiblyVisible(
                front,worldRadius:0.15,camera:view,aspect:aspect),
               "foreground sphere actor must never be culled")
            ck(SourceVisibleSurface73.possiblyVisible(
                front,worldRadius:0.45,camera:view,aspect:aspect),
               "large source destruction ring centered on-screen must stay visible")
            ck(!SourceVisibleSurface73.possiblyVisible(
                back,worldRadius:0.09,camera:view,aspect:aspect),
               "far-side small sphere actor is completely behind terrain")
            ck(SourceVisibleSurface73.possiblyVisible(
                back,worldRadius:0.9,camera:view,aspect:aspect),
               "oversized actor must NOT be hidden by tiny inner terrain")
        }
        let rock=SphereAsteroid556(
            position:front,velocity:Vec2(x:0,y:0),
            radius:34.72,size:3,tier:0,health:1)
        let r=SourceVisibleSurface73.rockWorldRadius(rock)
        ck(r>0.20 && r<0.28,"original 34.72 radius rock with 1.4x source guard")
        ck(SourceVisibleSurface73.shooterWorldRadius()>0.06,
           "source GpuSphere67 normal fighter visual radius")
        ck(SourceVisibleSurface73.innerTerrainRadius<0.839,
           "actual C279 mesh nearest vertex after mission normalization")
        print("PASS source Windows v73 conservative rock/fighter visibility and 4:3/16:9/iPhone frusta")
    }
}
