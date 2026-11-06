import Foundation
func near(_ a:Float,_ b:Float,_ name:String) {
    precondition(a.isFinite && abs(a-b)<0.000002,"\(name) \(a) != \(b)")
}
func vertex(_ x:Float,_ y:Float,_ z:Float)->[Float] {
    [x,y,z,0,0,1,1,1,1,1,0,0]
}
// Original carbonis279.mesh.gz 137067 vertices: max radius=1.09607509146.
@main struct CarbonisMissionPlanet523TestRunner {
    static func main() {
let floats=[vertex(1.0960751,0,0),vertex(0,0.92,0),
            vertex(0,-1,0),vertex(0,0,0.98)].flatMap { $0 }
let data=floats.withUnsafeBytes{Data($0)}
near(CarbonisMissionPlanet523.sourceOuterRadius523(
    vertexBytes:data)!,1.0960751,"C279 radius")
near(CarbonisMissionPlanet523.missionScale523(
    vertexBytes:data)!,0.91234625,"C279 scale")
precondition(CarbonisMissionPlanet523.missionScale523(
    vertexBytes:Data()) == nil)
precondition(CarbonisMissionPlanet523.missionScale523(
    vertexBytes:Data([0,1,2])) == nil)
var damaged=floats
damaged[0] = .nan
precondition(CarbonisMissionPlanet523.missionScale523(
    vertexBytes:damaged.withUnsafeBytes{Data($0)}) == nil)
print("PASS original C279 radius 1.0960751 / world scale 0.91234625")

    }
}
