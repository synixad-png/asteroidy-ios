import Foundation
@main struct Sphere67Tests {
 static func close(_ a: Float,_ b: Float,_ epsilon: Float=0.005,_ msg: String="") {
  precondition(a.isFinite && b.isFinite && abs(a-b)<=epsilon,"\(msg): \(a) vs \(b)")
 }
 static func main() {
  let r=Sphere67.radius
  close(r,720/Float.pi,0.0001,"radius")
  let origin=Vec2(x:123,y:310)
  let normal=Sphere67.normal(origin)
  close(normal.length,1,1e-5,"unit normal")
  close(sqrt(Sphere67.delta(target:Vec2(x:0,y:360),origin:Vec2(x:640,y:360)).lengthSquared),Float.pi*r,0.02,"antipodal")
  let across=Sphere67.delta(target:Vec2(x:1,y:360),origin:Vec2(x:1279,y:360))
  close(sqrt(across.lengthSquared),2*Float.pi*Sphere67.radius/640,0.004,"seam")
  let pole=Sphere67.canonical(Vec2(x:33,y:-20))
  close(pole.x,673,0.0001,"pole reflects longitude")
  close(pole.y,20,0.0001,"pole reflects latitude")
  let displacement=Vec2(x:12,y:-9)
  let target=Sphere67.offset(origin,by:displacement)
  let recovered=Sphere67.delta(target:target,origin:origin)
  close(recovered.x,displacement.x,0.01,"log/exp east")
  close(recovered.y,displacement.y,0.01,"log/exp south")
  let tang=Sphere67.vector(origin,displacement)
  close(SphereVector3.dot(tang,normal),0,1e-4,"tangent orthogonal")
  let transported=Sphere67.transport(tang,from:normal,to:Sphere67.normal(target))
  close(SphereVector3.dot(transported,Sphere67.normal(target)),0,1e-4,"parallel transported tangent")
  close(transported.length,tang.length,0.001,"transport magnitude")
  var p=Vec2(x:1278,y:360), v=Vec2(x:42,y:0)
  for _ in 0..<2000 { p=Sphere67.advance(p,velocity:&v,dt:1/120); precondition(p.x.isFinite && p.y.isFinite && v.x.isFinite && v.y.isFinite); close(sqrt(v.lengthSquared),42,0.003,"velocity transport") }
  var camera=SphereCamera67(at:origin)
  camera.update(target:target,dt:1/120)
  let right=camera.screenVector(at:origin,screen:Vec2(x:1,y:0))
  close(sqrt(right.lengthSquared),1,0.001,"screen vector normal")
  var ship=SphereFlight67()
  for _ in 0..<12000 { ship.tick(move:Vec2(x:1,y:0.25),aim:Vec2(x:0.4,y:1),dt:1/120); precondition(ship.position.x.isFinite && ship.position.y.isFinite && ship.velocity.x.isFinite && ship.velocity.y.isFinite) }
  print("PASS: Sphere67 topology, seam, pole, exp/log map, parallel transport, camera, 12000 spherical flight steps")
 }
}
