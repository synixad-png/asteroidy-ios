import Foundation

/// Independent fixtures from actual ASTEROIDY v568 PC source files:
///   Shared/assets/vanguard431/vanguard431.mesh.gz (4311 header)
///   Shared/assets/vanguard431/BakeInfo.json
///   Shared/assets/vanguard431/Vanguard_551_SOURCE.glb (source POS[0])
/// Not based on a guessed ship collision radius or stale bake script.
@main struct IntroVanguard431Tests {
    typealias V = SphereVector3
    static func near(_ x:Float,_ y:Float,_ tol:Float=0.00001) {
        precondition(x.isFinite && y.isFinite && abs(x-y)<=tol,
                     "Authentic PC Vanguard scale/coordinate mismatch")
    }
    static func nearV(_ a:V,_ b:V,_ tol:Float=0.00001) {
        near(a.x,b.x,tol);near(a.y,b.y,tol);near(a.z,b.z,tol)
    }
    static func main() {
        let pcScale:Float=3.265866381849069
        let pcCenter:Float=0.18199390172958374
        near(IntroVanguard431.pcBakedScale,pcScale)
        near(IntroVanguard431.pcBakedYCenter,pcCenter)
        near(IntroVanguard431.iosExportScale,0.32)
        near(IntroVanguard431.iosExportYCenter,0.18)
        near(IntroVanguard431.sourceUnitsPerPackedUnit,
             pcScale/0.32,0.000001)
        near(IntroVanguard431.sourceLocalDorsalCorrection,
             (0.18-pcCenter)*pcScale,0.000001)
        near(IntroVanguard431.normalizedShipModelScale,
             (pcScale/0.32)/144.19674,0.0000001)
        near(IntroVanguard431.normalizedDorsalCorrection,
             (0.18-pcCenter)*pcScale/144.19674,0.0000001)

        // First GLB source accessor POS[0], actual unmodified bytes.
        let glb=V(x:-0.1273176372,y:0.1308931261,z:0.1579895914)
        // Current Tools/export_vanguard.py: (x,z,y-0.18)*0.32.
        let packed=V(x:glb.x*0.32,
                     y:glb.z*0.32,
                     z:(glb.y-0.18)*0.32)
        let fromIOS=IntroVanguard431.sourceLocalPosition(packed)
        let expected=IntroVanguard431.sourceLocalFromGLB(glb)
        nearV(fromIOS,expected,0.0000003)
        // The first actual baked v4311 vertex in PC mesh.gz:
        nearV(fromIOS,V(x:-0.4158024,y:0.51597285,z:-0.1668883),
              0.0000003)

        // Original PC baked mesh Min/Max from BakeInfo.json.
        // GLB bounds before baking:
        // x[-.44092435,+.44092435], y[0,.3639878],
        // z[-.4888971,+.4888971].
        let negative=V(x:-0.44092435,y:0,z:-0.4888971)
        let positive=V(x:0.44092435,y:0.3639878,z:0.4888971)
        let low=IntroVanguard431.sourceLocalFromGLB(negative)
        let high=IntroVanguard431.sourceLocalFromGLB(positive)
        nearV(low,V(x:-1.43999994,y:-1.59667253,z:-0.59436774),0.00002)
        nearV(high,V(x:1.43999994,y:1.59667253,z:0.59436774),0.00002)

        // Source PC IntroScene41 / ShipMesh axes remain unchanged:
        // right X, nose Y, dorsal Z. No extra axes swap or negative
        // determinant may be introduced into the live scene.
        let origin=IntroVanguard431.sourceLocalPosition(V(x:0,y:0,z:0))
        let axisX=IntroVanguard431.sourceLocalPosition(V(x:1,y:0,z:0)) - origin
        let axisY=IntroVanguard431.sourceLocalPosition(V(x:0,y:1,z:0)) - origin
        let axisZ=IntroVanguard431.sourceLocalPosition(V(x:0,y:0,z:1)) - origin
        nearV(axisX,V(x:pcScale/0.32,y:0,z:0))
        nearV(axisY,V(x:0,y:pcScale/0.32,z:0))
        nearV(axisZ,V(x:0,y:0,z:pcScale/0.32))
        print("PASS: original Vanguard v4311 runtime mesh exact GLB POS[0],")
        print("      baked PC vertex, dimensions, 3 local axes and GLB origin")
        print("      remapped from existing iOS 0.32 export without regressions")
        print("LIMIT: actual Apple GPU, UV/PBR texture and gameplay lighting")
        print("       remain separate unverified renderer steps")
    }
}
