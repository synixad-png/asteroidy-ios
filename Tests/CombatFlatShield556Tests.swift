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
        let charged=CombatFlatShield556.collide(
            ship:ship,angle:0,rockPosition:r,rockVelocity:v,rockRadius:31,
            purchasedShieldCharges:1,tarczaAbsorbed:false)
        guard case .purchasedShieldAbsorbed(let shield)=charged else {fatalError("shield")}
        near(shield.position.x,640+31+32)
        near(shield.velocity.x,55)
        near(shield.invincibility,0.8)
        precondition(shield.remainingCharges==0)
        precondition(CombatFlatShield556.collide(
            ship:ship,angle:0,rockPosition:r,rockVelocity:v,rockRadius:31,
            purchasedShieldCharges:0,tarczaAbsorbed:false) == .applyDamage)
        // Directly overlapping ship/rock invokes Direction(angle+PI).
        let overlap=CombatFlatShield556.collide(
            ship:ship,angle:0,rockPosition:ship,
            rockVelocity:Vec2(x:90,y:0),rockRadius:18,
            purchasedShieldCharges:1,tarczaAbsorbed:false)
        guard case .purchasedShieldAbsorbed(let o)=overlap else {fatalError("overlap")}
        near(o.position.x,640-18-32)
        near(o.position.y,360)
        near(o.velocity.x,-90)
        // Source never slows a faster incoming rock.
        let fast=CombatFlatShield556.collide(
            ship:ship,angle:0,rockPosition:r,
            rockVelocity:Vec2(x:200,y:0),rockRadius:18,
            purchasedShieldCharges:1,tarczaAbsorbed:false)
        guard case .purchasedShieldAbsorbed(let f)=fast else {fatalError("fast")}
        near(f.velocity.x,200)
        print("PASS: original flat Tarcza145 and purchased shield rock shove (52/32), velocity floors (65/55), fallback and unknown protection")
    }
}
