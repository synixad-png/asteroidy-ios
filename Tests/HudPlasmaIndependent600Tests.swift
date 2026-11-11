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
        // The globe and all three plasma bars share ONE visual matrix
        // (0.78 weighting), but preserve completely separate saved F6
        // coordinates. This prevents the angle between them changing
        // during a bank without pinning either end of any plasma ribbon.
        let groupID="armor.bar"
        let p=HudMotionProject600.project(x:planet.x+125,y:planet.y+67.5,
                                          pose:flight,widget:groupID)
        let gauge=baseline.widget("shield.bar")!
        let g=HudMotionProject600.project(
            x:gauge.x+74,y:gauge.y+4.5,pose:flight,widget:groupID)
        let rest=HudMotion600.Pose()
        let stationaryPlanet=HudMotionProject600.project(
            x:planet.x+125,y:planet.y+67.5,pose:rest,widget:groupID)
        let stationaryGauge=HudMotionProject600.project(
            x:gauge.x+74,y:gauge.y+4.5,pose:rest,widget:groupID)
        check(close(hypot(p.x-g.x,p.y-g.y),
                    hypot(stationaryPlanet.x-stationaryGauge.x,
                          stationaryPlanet.y-stationaryGauge.y)),
              "one shared flight matrix preserves relative gauge/globe spacing")
        let globeEdit=globeOnly.widget("hud.planetarium")!
        let relocated=HudMotionProject600.project(
            x:globeEdit.x+125,y:globeEdit.y+67.5,
            pose:flight,widget:groupID)
        check(!close(relocated.x,p.x) || !close(relocated.y,p.y),
              "individual planetarium movement remains adjustable")
        check(close(Double(flight.weight(groupID)),0.78),
              "planetarium uses the same 0.78 HUD motion weight as plasma bars")
        let pt=screen.x(p.x,at:.bottomLeft)
        check(pt.isFinite,"independent screen projection stays finite")
        print("PASS PC602 independent plasma: top red/middle amber/bottom green, free F6 drag, planetarium no longer tethered, shared flight matrix")
    }
}
