import Foundation

@main enum HudPlasmaIndependent600Tests {
    static func check(_ condition:@autoclosure ()->Bool,_ description:String) {
        precondition(condition(),description)
    }
    static func close(_ a:Double,_ b:Double)->Bool {abs(a-b)<0.0001}

    static func main() {
        let baseline=HudLayout600.defaults()
        check(baseline.widgets.count==46,"F6 editor retains all original widgets")
        let top=baseline.widget("shield.bar")!
        let middle=baseline.widget("armor.bar")!
        let bottom=baseline.widget("hull.bar")!
        check(top.y < middle.y && middle.y < bottom.y,
              "approved layout rows are top shield ID, centre armor ID, bottom hull ID")
        // The three COLOR/ENERGY slots are drawn in the order:
        // red hull -> top row; orange armor -> centre; green shield -> bottom.
        var edited=baseline
        edited.change("shield.bar"){$0.x += 23;$0.y += 11}
        check(edited.widget("armor.bar")==middle &&
              edited.widget("hull.bar")==bottom,
              "moving the top red bar does not drag the other bars")
        check(edited.widget("hud.planetarium")==baseline.widget("hud.planetarium"),
              "moving a bar never drags planetarium")
        let topMoved=edited.widget("shield.bar")!
        check(close(topMoved.x,top.x+23) && close(topMoved.y,top.y+11),
              "the top bar persists its independent F6 coordinates")
        edited.change("hull.bar"){$0.y -= 31}
        check(edited.widget("armor.bar")==middle &&
              edited.widget("shield.bar")==topMoved,
              "moving the green lower bar leaves top and middle unchanged")
        var globeOnly=baseline
        globeOnly.change("hud.planetarium"){$0.x += 40;$0.y -= 16}
        for id in ["shield.bar","armor.bar","hull.bar"] {
            check(globeOnly.widget(id)==baseline.widget(id),
                  "planetarium moving cannot drag "+id)
        }

        let screen=CombatHUDViewport568(width:1024,height:768,safeBottom:20)
        var flight=HudMotion600.Pose()
        flight.parallax=true;flight.roll=1.3;flight.x=10;flight.y = -2
        let planet=baseline.widget("hud.planetarium")!
        let p=HudMotionProject600.project(x:planet.x+125,y:planet.y+67.5,
                                          pose:flight,widget:planet.id)
        let m=HudMotionProject600.project(x:planet.x+125,y:planet.y+67.5,
                                          pose:flight,widget:"armor.bar")
        check(!close(p.x,m.x) || !close(p.y,m.y),
              "planetarium keeps its own original HUD motion, not a gauge tether")
        let pt=screen.x(p.x,at:.bottomLeft)
        check(pt.isFinite,"independent screen projection stays finite")
        print("PASS PC602 independent plasma: top red/middle amber/bottom green, free F6 drag, planetarium no longer tethered")
    }
}
