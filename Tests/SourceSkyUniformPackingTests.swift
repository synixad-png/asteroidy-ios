import Foundation

/// Independent known-value tests for the original BlackHoleRaster55
/// uniform layout: first frame + 3 float4s for each overlay.
@main struct SourceSkyUniformPackingTests {
    static func near(_ value:Float,_ expected:Float) {
        precondition(value.isFinite && abs(value-expected)<0.0001,
                     "Source sky uniform drift: \(value) vs \(expected)")
    }
    static func vector(_ actual:SIMD4<Float>,_ expected:SIMD4<Float>) {
        for i in 0..<4 {near(actual[i],expected[i])}
    }
    static func main() {
        let frame=SIMD4<Float>(12,23,0.5,-0.3)
        let planets:[DeepSkyPlanets55.Overlay]=[
            .init(textureSlice:-1,radiusX:3,radiusY:4,
                  rgba:(0.5,0.25,0.75,0.4)),
            .init(textureSlice:2,radiusX:40,radiusY:30,
                  rgba:(1,1,1,1))
        ]
        let p=SourceSkyUniformPacking.planet(frame:frame,layers:planets)
        precondition(p.count == 7)
        vector(p[0],frame)
        vector(p[1],SIMD4(3,4,1,0))
        vector(p[2],SIMD4(0.2,0.1,0.3,0.4))
        vector(p[3],SIMD4(-1,0,0,0))
        vector(p[4],SIMD4(40,30,1,0))
        vector(p[5],SIMD4(1,1,1,1))
        vector(p[6],SIMD4(2,0,0,0))
        precondition(SourceSkyUniformPacking.planet(frame:frame,layers:[]).count==1)

        let screen=SIMD4<Float>(7,9,0.08,-0.06)
        let holes:[BlackHoleSky55.Overlay]=[
            .init(isTexture:false,layer:3,radiusX:5,radiusY:6,
                  angle:Float.pi/2,rgba:(0.5,0.25,0.75,0.4)),
            .init(isTexture:true,layer:2,radiusX:100,radiusY:110,
                  angle:0,rgba:(1,1,1,1))
        ]
        let h=SourceSkyUniformPacking.blackHole(screen:screen,layers:holes)
        precondition(h.count == 7)
        vector(h[0],screen)
        vector(h[1],SIMD4(5,6,0,1))
        vector(h[2],SIMD4(0.2,0.1,0.3,0.4))
        vector(h[3],SIMD4(-1,0,0,0))
        vector(h[4],SIMD4(100,110,1,0))
        vector(h[5],SIMD4(1,1,1,1))
        vector(h[6],SIMD4(2,0,0,0))
        precondition(SourceSkyUniformPacking.blackHole(screen:screen,layers:[]).count==1)
        print("PASS source sky overlay packing: exact SIMD4 cardinalities, premultiplied alpha, angle and texture slice sentinel")
    }
}
