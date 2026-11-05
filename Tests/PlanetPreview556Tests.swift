import Foundation
@main struct PlanetPreview556Tests {
 static func main() {
  let m = PlanetPreview556.make(longitudes:64,latitudes:32)
  precondition(m.vertices.count == 65*33)
  precondition(m.indices.count == 64*32*6)
  precondition(m.indices.allSatisfy { $0 < m.vertices.count })
  for row in 0...32 {
   let a=m.vertices[row*65].position, b=m.vertices[row*65+64].position
   precondition(abs(a.x-b.x)<0.0001 && abs(a.y-b.y)<0.0001 && abs(a.z-b.z)<0.0001)
  }
  var flight=SphereFlight67()
  for i in 0..<12000 {
   flight.tick(move:Vec2(x:1,y:0.3),aim:Vec2(x:0,y:1),dt:1/120)
   let s=PlanetPreview556.shipSurfacePosition(flight.position)
   let r=sqrt(s.x*s.x+s.y*s.y+s.z*s.z)
   precondition(s.x.isFinite && s.y.isFinite && s.z.isFinite && abs(r-1.09)<0.0001, "step \(i)")
  }
  print("PASS: sphere mesh, closed longitude seam, valid triangles, 12000 orbital positions")
 }
}
