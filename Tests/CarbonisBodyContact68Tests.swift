import Foundation

@main struct CarbonisBodyContact68Tests {
    static func main() {
        var checks=0
        func verify(_ ok:Bool,_ message:String) {
            precondition(ok,message);checks+=1
        }
        typealias Body=CarbonisBodyContact68.Body
        let base=Vec2(x:640,y:360)
        var distantA=Body(position:base,velocity:Vec2(x:0,y:0),
                          mass:3.4,radius:11.2)
        var distantB=Body(position:Vec2(x:920,y:360),
                          velocity:Vec2(x:0,y:0),mass:8,radius:16)
        verify(!CarbonisBodyContact68.resolve(
            &distantA,&distantB,restitution:0.42),
            "non-overlapping spherical bodies are rejected")
        var ship=Body(position:base,velocity:Vec2(x:30,y:0),
                      mass:3.4,radius:11.2)
        var rock=Body(position:Vec2(x:649,y:360),
                      velocity:Vec2(x:-10,y:0),mass:8,radius:16)
        let initial=sqrt(Sphere67.delta(target:rock.position,
                                  origin:ship.position).lengthSquared)
        verify(CarbonisBodyContact68.resolve(
            &ship,&rock,restitution:0.42),"contact normal-case")
        let final=sqrt(Sphere67.delta(target:rock.position,
                                origin:ship.position).lengthSquared)
        verify(final>initial,"source positional correction separates bodies")
        verify(ship.velocity.x < 30,"closing player momentum changes")
        verify(rock.velocity.x > -10,"rock receives impulse")
        verify(ship.position.x.isFinite && rock.position.x.isFinite,
               "source tangent correction finite")

        var seamShip=Body(position:Vec2(x:1278,y:360),
                          velocity:Vec2(x:3,y:0),mass:3.4,radius:11.2)
        var seamFighter=Body(position:Vec2(x:2,y:360),
                             velocity:Vec2(x:-3,y:0),mass:2,radius:16)
        verify(CarbonisBodyContact68.resolve(
            &seamShip,&seamFighter,restitution:0.35),
            "longitude wrap seam collision remains continuous")
        verify((0...1280).contains(seamShip.position.x),
               "seam correction canonical coordinate")
        verify((0...1280).contains(seamFighter.position.x),
               "other seam correction canonical coordinate")

        var poleA=Body(position:Vec2(x:5,y:3),
                        velocity:Vec2(x:0,y:-20),mass:3.4,radius:11.2)
        var poleB=Body(position:Vec2(x:645,y:4),
                        velocity:Vec2(x:0,y:20),mass:2,radius:16)
        verify(CarbonisBodyContact68.resolve(
            &poleA,&poleB,restitution:0.35),
            "spherical pole reflected arc collision")
        verify(poleA.position.y>=0 && poleA.position.y<=Sphere67.height &&
               poleB.position.y>=0 && poleB.position.y<=Sphere67.height,
               "pole correction normalized")

        var staticA=Body(position:base,velocity:Vec2(x:0,y:0),
                         mass:0,radius:12)
        var staticB=Body(position:base,velocity:Vec2(x:0,y:0),
                         mass:0,radius:12)
        verify(!CarbonisBodyContact68.resolve(
            &staticA,&staticB,restitution:0.42),
            "both infinite-mass bodies cannot receive a physical impulse")
        print("PASS \(checks) verified source Physics68 ship-rock / ship-fighter impulse checks")
    }
}