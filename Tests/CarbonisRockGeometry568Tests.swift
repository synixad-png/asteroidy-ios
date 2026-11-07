import Foundation
@main struct CarbonisRockGeometry568Tests {
 static func main() {
  var count=0
  func check(_ value:Bool,_ message:String) {
    precondition(value,message); count += 1
  }
  check(CarbonisRockGeometry568.ico.count==12,"original 12 vertices")
  check(CarbonisRockGeometry568.faces.count==60,"original 20 faces")
  var shapeZero:[Float]=[]
  check(CarbonisRockGeometry568.sourceShapeCount==80,
        "all eight seeds / five tiers / intact and fragment shapes")
  for shape in 0..<CarbonisRockGeometry568.sourceShapeCount {
    let mesh=CarbonisRockGeometry568.vertices(shape:shape)
    check(mesh.count==CarbonisRockGeometry568.sourceVertexCount
          * CarbonisRockGeometry568.gpuStride,"source 2-subdiv 960 vertices")
    check(mesh.allSatisfy{$0.isFinite},"finite positions, normals and colors")
    var outward=0
    var minimum:Float=1000,maximum:Float=0
    for i in stride(from:0,to:mesh.count,by:12) {
      let p=CarbonisRockGeometry568.V3(x:mesh[i],y:mesh[i+1],z:mesh[i+2])
      let n=CarbonisRockGeometry568.V3(x:mesh[i+3],y:mesh[i+4],z:mesh[i+5])
      let length=p.length
      minimum=min(minimum,length);maximum=max(maximum,length)
      if CarbonisRockGeometry568.V3.dot(p,n)>0 {outward += 1}
      check(mesh[i+9]==1 && mesh[i+10]==0 && mesh[i+11]==0,
            "rock shader alpha and extra UV stride")
    }
    check(outward>950,"source normals point outward")
    check(minimum>0.2 && maximum<1.8,"stone/noise radius bounds")
    if shape==0 {shapeZero=mesh}
  }
  check(shapeZero==CarbonisRockGeometry568.vertices(shape:0),"deterministic mesh")
  check(CarbonisRockGeometry568.vertices(shape:0) !=
        CarbonisRockGeometry568.vertices(shape:1),"armor colors")
  check(CarbonisRockGeometry568.vertices(shape:0) !=
        CarbonisRockGeometry568.vertices(shape:5),"source shape seed")
  print("PASS \(count) source Carbonis rock geometry assertions for all 80 variants")
 }
}