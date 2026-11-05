import Foundation

/// Compared against independent arithmetic of the original real v556
/// Windows/src/GpuIntro41.cs:27-63. The GDI+ pen strokes have analytic
/// AA approximations and are NOT claimed to be bit-identical.
@main struct DeepSkyPlanets55Tests {
    static func near(_ a:Float,_ b:Float,_ tolerance:Float=0.004) {
        precondition(a.isFinite && abs(a-b)<=tolerance,
            "Source GpuIntro41 planet value mismatch: \(a) / \(b)")
    }
    static func testSourceBody() {
        // Independent v556 PlanetShade55 body goldens (RGB, before GDI
        // DrawArc anti-aliasing); selected pixel coordinates are not
        // near either white/coral glint arc or the gas giant ring.
        let goldens:[(Int,Int,Int,[Int])]=[
            (0,160,110,[140,106,68]), (0,120,110,[155,119,76]),
            (0,199,118,[104,76,49]), (0,210,85,[98,71,45]),
            (1,160,110,[120,168,206]), (1,120,110,[137,189,228]),
            (1,199,118,[84,124,161]),(1,210,85,[72,109,145]),
            (2,160,110,[181,98,77]), (2,120,110,[227,128,93]),
            (2,199,118,[137,70,62]), (2,210,85,[152,80,67])
        ]
        for (style,x,y,expected) in goldens {
            guard let px=DeepSkyPlanets55.body(x:x,y:y,style:style)
            else {fatalError("Source body missing at \(x),\(y)")}
            for (actual,ref) in zip([px.r,px.g,px.b],expected) {
                near(actual,Float(ref),3.0)
            }
            near(px.a,1)
        }
        for style in 0..<3 {
            precondition(DeepSkyPlanets55.body(x:160,y:22,style:style)==nil)
            precondition(DeepSkyPlanets55.body(x:160,y:110,style:style) != nil)
            precondition(DeepSkyPlanets55.body(x:0,y:0,style:style)==nil)
        }
        // Explicit PlanetShade55 interpolation/truncation behavior.
        precondition(DeepSkyPlanets55.shade(
            light:0.5,band:0.5,a:20,b:220)==70)
        precondition(DeepSkyPlanets55.shade(
            light:2,band:2,a:20,b:220)==220)
        precondition(DeepSkyPlanets55.shade(
            light:-1,band:2,a:20,b:220)==20)
    }

    static func testGDIStrokeApproximation() {
        precondition(DeepSkyPlanets55.arcIncluded(
            x:160,y:140,cx:160,cy:115,rx:148,ry:25,
            start:0,span:180))
        precondition(!DeepSkyPlanets55.arcIncluded(
            x:160,y:90,cx:160,cy:115,rx:148,ry:25,
            start:0,span:180))
        near(DeepSkyPlanets55.strokeCoverage(
            x:160,y:140,cx:160,cy:115,rx:148,ry:25,width:5),1)
        precondition(DeepSkyPlanets55.strokeCoverage(
            x:160,y:115,cx:160,cy:115,rx:148,ry:25,width:5)<0.1)
        // Source Windows GDI stroke placement and alpha are
        // approximated; don't compare anti-aliased edge bytes.
    }

    static func testSourceTextures() {
        precondition(DeepSkyPlanets55.textureWidth==320)
        precondition(DeepSkyPlanets55.textureHeight==220)
        precondition(DeepSkyPlanets55.count==3)
        for style in 0..<3 {
            let pixels=DeepSkyPlanets55.textureBGRA(style:style)
            precondition(pixels.count==320*220*4)
            precondition(pixels[0]==0 && pixels[1]==0 &&
                         pixels[2]==0 && pixels[3]==0)
            let center=(110*320+160)*4
            let expected=DeepSkyPlanets55.body(
                x:160,y:110,style:style)!
            near(Float(pixels[center]),expected.b,3)
            near(Float(pixels[center+1]),expected.g,3)
            near(Float(pixels[center+2]),expected.r,3)
            precondition(pixels[center+3]==255)
            for (x,y) in [(0,0),(160,110),(120,110),(199,118),
                          (160,140),(250,115),(160,84)] {
                let i=(y*320+x)*4
                precondition(pixels[i]<=pixels[i+3] &&
                             pixels[i+1]<=pixels[i+3] &&
                             pixels[i+2]<=pixels[i+3],
                    "Source GpuRenderer expects premultiplied 32bppPArgb")
            }
            let farRing=(115*320+12)*4
            if style==0 {
                precondition(pixels[farRing+3]>0,
                    "Original ringed gas giant must have back ellipse")
            } else {
                precondition(pixels[farRing+3]==0,
                    "Other source styles have no gas giant ring")
            }
        }
    }

    static func testAnimatedSourceProjection() {
        let originalDirections=[
            SphereVector3(x:0.94,y:0.02,z:-0.34),
            SphereVector3(x:0.18,y:-0.62,z:-0.76),
            SphereVector3(x:-0.78,y:0.42,z:-0.46)]
        let dims:[(Float,Float,Float,Float)]=[
            (148,96,2.05,28),(176,116,2.25,44),
            (166,108,2.18,34)]
        for style in 0..<3 {
            let p=DeepSkyPlanets55.profile(style)
            near(p.halfWidth,dims[style].0)
            near(p.halfHeight,dims[style].1)
            near(p.maxScale,dims[style].2)
            near(p.glow.3,dims[style].3)
            let direction=DeepSkyPlanets55.direction(style:style,time:0)
            let base=originalDirections[style].normalized
            precondition((direction-base).length<0.015)
            near(direction.length,1)
            let later=DeepSkyPlanets55.direction(style:style,time:90)
            precondition((later-direction).length>0.0001,
                "Sky planet should follow original animated direction")
            let facing=SphereCamera67(
                at:Sphere67.coordinates(direction * -1))
            guard let proj=DeepSkyPlanets55.project(
                style:style,time:0,camera:facing)
            else {fatalError("Original sky planet should be visible")}
            near(proj.screen.x,640,0.03)
            near(proj.screen.y,360,0.03)
            near(proj.scale,1)
            let away=SphereCamera67(at:Sphere67.coordinates(direction))
            precondition(DeepSkyPlanets55.project(
                style:style,time:0,camera:away)==nil)
            let overlays=DeepSkyPlanets55.overlays(style:style,scale:1)
            precondition(overlays.count==2)
            precondition(overlays[0].textureSlice == -1)
            precondition(overlays[1].textureSlice == style)
            near(overlays[0].radiusX,max(p.halfWidth,p.halfHeight)*0.54)
            near(overlays[1].radiusX,p.halfWidth)
            near(overlays[1].radiusY,p.halfHeight)
            near(overlays[0].rgba.3,p.glow.3/255)
            near(overlays[1].rgba.3,1)
            let noGlow=DeepSkyPlanets55.overlays(
                style:style,scale:2,glow:false)
            precondition(noGlow.count==1)
            near(noGlow[0].radiusX,p.halfWidth*2)
        }
    }

    static func main() {
        testSourceBody()
        testGDIStrokeApproximation()
        testSourceTextures()
        testAnimatedSourceProjection()
        print("PASS: v556 GpuIntro41 3 original 320x220 deep-space planets,")
        print("      source procedural body RGB goldens, GDI rings and arcs,")
        print("      PArgb textures, 3 AnimatedSkyDirection profiles,")
        print("      SkyProject55 visibility and glow→bitmap painter order")
        print("LIMITATION: GDI+ antialias stroke pixels approximate;")
        print("            Xcode/Metal compiler and iPhone GPU not tested")
    }
}
