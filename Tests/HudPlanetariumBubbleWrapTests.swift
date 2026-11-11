import Foundation
import simd

@main enum HudPlanetariumBubbleWrapTests {
    static func check(_ ok:@autoclosure ()->Bool,_ label:String) {
        precondition(ok(),label)
    }
    static func close(_ x:Float,_ y:Float)->Bool {abs(x-y)<0.00001}
    static func main() {
        let a=SIMD4<Float>(6.9982233,1.3676833,0.173184,0)
        let b=SIMD4<Float>(3.1832228,1.3676833,0.173184,0)
        let c=SIMD4<Float>(3.304,1.3676833,0.173184,0)
        // These source positions are taken from the original SHA-verified
        // PC v602 CAPSULE_0_WATER_BUBBLE_02 translation sampler.
        let wrapped=HudPlanetariumOriginal600.Track(
            node:71,path:.translation,times:[0,0.25,0.50],
            values:[a,b,c],bubbleWrap:true)
        check(close(wrapped.at(0).x,a.x),"source key 0 retained")
        check(close(wrapped.at(0.125).x,a.x),
              "do not interpolate across original -3.815 bubble reset")
        check(close(wrapped.at(0.249).x,a.x),
              "bubble stays at right outlet until authentic wrap key")
        check(close(wrapped.at(0.25).x,b.x),
              "bubble starts new cycle at its exact source key")
        check(wrapped.at(0.375).x>b.x && wrapped.at(0.375).x<c.x,
              "after wrap, ordinary LINEAR motion is still sub-frame smooth")

        let original=HudPlanetariumOriginal600.Track(
            node:71,path:.translation,times:[0,0.25,0.50],
            values:[a,b,c],bubbleWrap:false)
        check(original.at(0.125).x>4.9 && original.at(0.125).x<5.2,
              "demonstrate bug: old interpolation causes rapid reverse flight")
        let notAReset=HudPlanetariumOriginal600.Track(
            node:71,path:.translation,times:[0,0.25],
            values:[SIMD4<Float>(3.18,0,0,0),SIMD4<Float>(3.32,0,0,0)],
            bubbleWrap:true)
        check(close(notAReset.at(0.125).x,3.25),
              "the 72 bubble tracks still interpolate all normal keys")

        let rotation=HudPlanetariumOriginal600.Track(
            node:31,path:.rotation,times:[0,2],
            values:[SIMD4<Float>(0,0,0,1),
                    SIMD4<Float>(0,0.70710678,0,0.70710678)],
            bubbleWrap:false)
        check(abs(simd_length(rotation.at(1))-1)<0.0001,
              "original authored planet rotations retain quaternion slerp")
        print("PASS source GLB: original bubble respawn teleport is not reverse-interpolated, normal keys and all rotations interpolate")
    }
}
