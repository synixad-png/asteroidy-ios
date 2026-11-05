import Foundation

@main struct CombatPickupPhysics68Tests {
    static func item(_ x:Float,_ speed:Float=0) -> CombatBody68 {
        CombatBody68(position:Vec2(x:x,y:360),
                     velocity:Vec2(x:speed,y:0),mass:99,radius:40)
    }
    static func main() {
        let player=Vec2(x:640,y:360)
        var rocks=[SphereAsteroid556]()
        var nearest=item(700)
        let usedSecond=CombatPickupPhysics68.advance(&nearest,dt:0.1,
            player:player,secondPlayer:nil,coopEnabled:false,
            playerDown:false,secondDown:false,collectorLevel:0,rocks:&rocks)
        precondition(!usedSecond)
        precondition(nearest.velocity.x < -12)
        precondition(nearest.position.x < 700)
        precondition(nearest.mass==99 && nearest.radius==40)

        var noMagnet=item(700)
        _ = CombatPickupPhysics68.advance(&noMagnet,dt:0.1,
            player:player,secondPlayer:nil,coopEnabled:false,
            playerDown:true,secondDown:false,collectorLevel:3,rocks:&rocks)
        precondition(noMagnet.velocity.lengthSquared==0 && noMagnet.position.x==700)

        var prefersPartner=item(700)
        let partner=Vec2(x:740,y:360)
        precondition(CombatPickupPhysics68.advance(&prefersPartner,dt:0.1,
            player:player,secondPlayer:partner,coopEnabled:true,
            playerDown:false,secondDown:false,collectorLevel:0,rocks:&rocks))
        precondition(prefersPartner.velocity.x>0)

        var downFirst=item(700)
        precondition(CombatPickupPhysics68.advance(&downFirst,dt:0.1,
            player:player,secondPlayer:Vec2(x:900,y:360),coopEnabled:true,
            playerDown:true,secondDown:false,collectorLevel:2,rocks:&rocks))
        precondition(downFirst.velocity.x>0)

        var downSecond=item(700)
        precondition(!CombatPickupPhysics68.advance(&downSecond,dt:0.1,
            player:player,secondPlayer:partner,coopEnabled:true,
            playerDown:false,secondDown:true,collectorLevel:0,rocks:&rocks))
        precondition(downSecond.velocity.x<0)

        var outside=item(1000,120)
        _ = CombatPickupPhysics68.advance(&outside,dt:0.1,
            player:player,secondPlayer:nil,coopEnabled:false,
            playerDown:false,secondDown:false,collectorLevel:0,rocks:&rocks)
        precondition(outside.velocity.x>110 && outside.velocity.x<120,
                     "Outside collector range must use original .18 damping")

        var boosted=item(700,1000)
        _ = CombatPickupPhysics68.advance(&boosted,dt:0.1,
            player:player,secondPlayer:nil,coopEnabled:false,
            playerDown:false,secondDown:false,collectorLevel:2,rocks:&rocks)
        precondition(sqrt(boosted.velocity.lengthSquared)<=185.001)

        var seam=item(1278)
        _ = CombatPickupPhysics68.advance(&seam,dt:0.1,
            player:Vec2(x:5,y:360),secondPlayer:nil,coopEnabled:false,
            playerDown:false,secondDown:false,collectorLevel:0,rocks:&rocks)
        precondition(seam.velocity.x>0)
        precondition(seam.position.x>=0 && seam.position.x<1280)

        var colliding=item(640)
        var contactRocks=[SphereAsteroid556(
            position:Vec2(x:646,y:360),velocity:Vec2(x:0,y:0),
            radius:12,mass:8)]
        _ = CombatPickupPhysics68.advance(&colliding,dt:0.01,
            player:player,secondPlayer:nil,coopEnabled:false,
            playerDown:false,secondDown:false,collectorLevel:0,
            rocks:&contactRocks)
        precondition(Sphere67.delta(target:colliding.position,
           origin:contactRocks[0].position).lengthSquared>30,
           "Pickup must be separated from asteroid by Physics68.Contact68")
        precondition(colliding.position.x.isFinite && contactRocks[0].position.x.isFinite)

        let frozen=colliding
        let rockBefore=contactRocks[0].position
        precondition(!CombatPickupPhysics68.advance(&colliding,dt:0,
            player:player,secondPlayer:nil,coopEnabled:false,
            playerDown:false,secondDown:false,collectorLevel:0,
            rocks:&contactRocks))
        precondition(colliding.position==frozen.position)
        precondition(contactRocks[0].position==rockBefore)
        print("PASS: original spherical pickup magnet, co-op target/down priority, damping, speed caps, seam and rock contact")
    }
}
