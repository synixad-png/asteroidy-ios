import Foundation

/// Faithful movement and physical collision of supply pickups on spherical
/// planets from Windows/src/Physics68.cs MovePickup68.
enum CombatPickupPhysics68 {
    static func advance(_ pickup:inout CombatBody68, dt:Float,
                        player:Vec2, secondPlayer:Vec2?,
                        coopEnabled:Bool, playerDown:Bool, secondDown:Bool,
                        collectorLevel:Int, rocks:inout [SphereAsteroid556])
                        -> Bool {
        guard dt>0 else {return false}
        let useSecond=coopEnabled && !secondDown && secondPlayer != nil &&
           (playerDown || Sphere67.delta(target:secondPlayer!,origin:pickup.position).lengthSquared <
                          Sphere67.delta(target:player,origin:pickup.position).lengthSquared)
        let target=useSecond ? secondPlayer! : player
        let toward=Sphere67.delta(target:target,origin:pickup.position)
        let distance=sqrt(toward.lengthSquared)
        let level=max(0,collectorLevel)
        let range=Float(165+level*30)
        let eligible=useSecond || !playerDown
        if eligible && distance<range && distance>0.1 {
            pickup.velocity = pickup.velocity +
                toward*(dt*Float(210+level*30)/distance)
        }
        pickup.velocity=pickup.velocity*exp(-dt*(distance<range ? 1.4 : 0.18))
        let limit=Float(145+level*20)
        let length=sqrt(pickup.velocity.lengthSquared)
        if length>limit {pickup.velocity=pickup.velocity*(limit/length)}
        pickup.position=Sphere67.advance(pickup.position,
                                          velocity:&pickup.velocity,dt:dt)
        // Game.MovePickup68 uses mass .15 and radius 6, independent of
        // the artwork size. Leave provided gameplay metadata unchanged.
        var physical=CombatBody68(position:pickup.position,velocity:pickup.velocity,
                                  mass:0.15,radius:6)
        for i in rocks.indices {
            var rock=rocks[i]
            if CombatSolids68.collisionWithRock(&physical,&rock,restitution:0.25) {
                rocks[i]=rock
            }
        }
        pickup.position=physical.position
        pickup.velocity=physical.velocity
        return useSecond
    }
}
