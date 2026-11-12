import Foundation
@main struct CombatFlatShield556Tests {
    static func near(_ a:Float,_ b:Float,_ tol:Float=0.01) {
        precondition(abs(a-b)<=tol,"Expected \(b), got \(a)")
    }
    static func main() {
        let ship=Vec2(x:640,y:360)
        let r=Vec2(x:680,y:360)
        let v=Vec2(x:20,y:0)
        let unknown=CombatFlatShield556.collide(
            ship:ship,angle:0,rockPosition:r,rockVelocity:v,rockRadius:31,
            purchasedShieldCharges:2,tarczaAbsorbed:nil)
        precondition(unknown == .defenseUnverified)
        let t=CombatFlatShield556.collide(
            ship:ship,angle:0,rockPosition:r,rockVelocity:v,rockRadius:31,
            purchasedShieldCharges:2,tarczaAbsorbed:true)
        guard case .tarczaAbsorbed(let tarcza)=t else {fatalError("tarcza")}
        near(tarcza.position.x,640+31+52)
        near(tarcza.velocity.x,65)
        precondition(tarcza.remainingCharges==2 && tarcza.invincibility==0)
        // v608 removes the passive one-hit rock rebound entirely.
        // Both flat and spherical contacts must fall through to real
        // armor/hull damage, leaving the reserve reducer untouched.
        for charges in [0,1,2,3] {
            precondition(CombatFlatShield556.collide(
                ship:ship,angle:0,rockPosition:r,rockVelocity:v,rockRadius:31,
                purchasedShieldCharges:charges,tarczaAbsorbed:false)
                == .applyDamage)
        }
        let overlap=CombatFlatShield556.collide(
            ship:ship,angle:0,rockPosition:ship,
            rockVelocity:Vec2(x:90,y:0),rockRadius:18,
            purchasedShieldCharges:3,tarczaAbsorbed:true)
        guard case .tarczaAbsorbed(let o)=overlap else {fatalError("overlap")}
        near(o.position.x,640-18-52)
        near(o.position.y,360)
        near(o.velocity.x,-90)
        precondition(o.remainingCharges==3,"active shove never spends reserve")
        let fast=CombatFlatShield556.collide(
            ship:ship,angle:0,rockPosition:r,
            rockVelocity:Vec2(x:200,y:0),rockRadius:18,
            purchasedShieldCharges:3,tarczaAbsorbed:true)
        guard case .tarczaAbsorbed(let f)=fast else {fatalError("fast")}
        near(f.velocity.x,200)
        print("PASS PC608: active Tarcza rock shove 52/65, NO passive shield rock shove, zero reserve spending")
    }
}
