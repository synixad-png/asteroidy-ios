import Foundation

/// Independent checks against original Windows/src/GpuIntro41.cs:454
/// and GpuCosmos39.cs:8-10 (v556). This tests source geometry and
/// screen projection, NOT Apple Metal compilation or GPU rendering.
@main struct SphereSolarOverlay556Tests {
    static func near(_ a:Float,_ b:Float,_ e:Float=0.002) {
        precondition(a.isFinite && abs(a-b)<=e,
            "Original GpuCosmos39 ray geometry mismatch: \(a) vs \(b)")
    }
    static func main() {
        precondition(SphereSolarOverlay556.rayCount==5)
        precondition(SphereSolarOverlay556.columns==6)
        precondition(SphereSolarOverlay556.rows==4)
        precondition(SphereSolarOverlay556.rayVertexCount==720)
        precondition(SphereSolarOverlay556.haloVertexCount==18)
        precondition(SphereSolarOverlay556.totalVertices==738)

        let data=SphereSolarOverlay556.vertices()
        precondition(data.count==738)
        // GpuIntro41:454: big 130 halo, 55 halo, 15 core.
        let radii:[Float]=[130,55,15]
        let alpha:[Float]=[170,220,255]
        for halo in 0..<3 {
            let n=halo*6
            let radius=radii[halo]
            near(data[n].offset.x,-radius)
            near(data[n].offset.y,-radius)
            near(data[n+1].offset.x,radius)
            near(data[n+1].offset.y,-radius)
            near(data[n+2].offset.x,radius)
            near(data[n+2].offset.y,radius)
            near(data[n+5].offset.x,-radius)
            near(data[n+5].offset.y,radius)
            near(data[n].rgba.3,alpha[halo]/255)
            precondition(data[n].textured)
            near(data[n].uv.x,0)
            near(data[n].uv.y,0)
            near(data[n+1].uv.x,1)
            near(data[n+2].uv.y,1)
        }
        near(data[0].rgba.0,1)
        near(data[0].rgba.1,199/255)
        near(data[0].rgba.2,127/255)
        near(data[6].rgba.1,217/255)
        near(data[6].rgba.2,164/255)
        near(data[12].rgba.1,245/255)
        near(data[12].rgba.2,207/255)

        // GpuCosmos39's RayVertex has 5 distance rows and 7
        // column boundaries. All 4×6 cells emit exactly 6 vertices.
        let rv=SphereSolarOverlay556.rayVertex(
            angle:2.16,row:1,column:3)
        near(rv.offset.x,-50.01292)
        near(rv.offset.y,74.82451)
        near(rv.rgba.3,18/255)
        let first=SphereSolarOverlay556.rayVertex(
            angle:2.16,row:0,column:0)
        near(first.offset.x,2.49415)
        near(first.offset.y,1.66710)
        near(first.rgba.3,0)
        let centre=SphereSolarOverlay556.rayVertex(
            angle:2.5,row:2,column:4)
        near(centre.offset.x,-212.99332)
        near(centre.offset.y,153.49379)
        near(centre.rgba.3,9/255)
        let last=SphereSolarOverlay556.rayVertex(
            angle:2.84,row:4,column:6)
        near(last.offset.x,-725.95083)
        near(last.offset.y,191.27048)
        near(last.rgba.3,0)
        precondition(data.dropFirst(18).allSatisfy { !$0.textured })

        // Original triangles: first 6 vertices are row 0,col 0
        // corner order A,B,C, A,C,D.
        let i=18
        let a=SphereSolarOverlay556.rayVertex(
            angle:2.16,row:0,column:0)
        let b=SphereSolarOverlay556.rayVertex(
            angle:2.16,row:1,column:0)
        let c=SphereSolarOverlay556.rayVertex(
            angle:2.16,row:1,column:1)
        let d=SphereSolarOverlay556.rayVertex(
            angle:2.16,row:0,column:1)
        let expected=[a,b,c,a,c,d]
        for k in 0..<6 {
            near(data[i+k].offset.x,expected[k].offset.x)
            near(data[i+k].offset.y,expected[k].offset.y)
            near(data[i+k].rgba.3,expected[k].rgba.3)
        }
        // The original GpuIntro41 solar direction is (.6,.8,.32)*900.
        // At the antipode its SkyProject55 centre is (640,360);
        // at the same surface normal the solar source is BEHIND camera.
        let sun=SphereSolarOverlay556.sunDirection
        let opposite=Sphere67.coordinates(sun * -1)
        let frame=SphereCamera67(at:opposite)
        guard let projected=SphereSolarOverlay556.project(camera:frame)
        else {fatalError("Original sky sun should be visible at antipode")}
        near(projected.x,640,tolerance:0.02)
        near(projected.y,360,tolerance:0.02)
        let toward=SphereCamera67(at:Sphere67.coordinates(sun))
        precondition(SphereSolarOverlay556.project(camera:toward)==nil)
        // GpuIntro41 screen centre maps to the same Metal NDC centre for
        // any aspect ratio, and offsets preserve the source 720px basis.
        for aspect:Float in [4/3,16/9,19.5/9] {
            let ndcX=(projected.x-640)*2/(720*aspect)
            let ndcY=(360-projected.y)*2/720
            near(ndcX,0)
            near(ndcY,0)
            near(720*2/(720*aspect),2/aspect)
        }

        print("PASS: v556 solar GpuIntro41 3 textured halos + 5 GpuCosmos39 ray fans")
        print("      exactly 738 static vertices, C# alpha/UV/row/column goldens,")
        print("      original SkyProject55 camera clipping and NDC 720px mapping")
        print("LIMITATION: no Apple Metal compiler/GPU or physical iPhone test")
    }
}
