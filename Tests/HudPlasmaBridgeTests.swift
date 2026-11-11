import Foundation

@main enum HudPlasmaBridgeTests {
    static func near(_ a:Double,_ b:Double,eps:Double=0.001)->Bool {
        abs(a-b)<eps
    }
    static func check(_ condition:@autoclosure ()->Bool,_ label:String) {
        precondition(condition(),label)
    }
    static func main() {
        let original=HudLayout600.defaults()
        let vp=CombatHUDViewport568(width:1024,height:768,safeBottom:20)
        let still=HudMotion600.Pose()
        let id="armor.bar"
        let bridge=HudPlasmaBridge600.segment(
            id:id,layout:original,pose:still,viewport:vp,fill:1)!
        let left=bridge.project(x:bridge.sourceX,y:bridge.centerY)
        let right=bridge.project(x:bridge.sourceX+bridge.length,
                                 y:bridge.centerY)
        check(near(left.x,bridge.start.x) && near(left.y,bridge.start.y),
              "source glTF socket remains the first fixed plasma endpoint")
        check(near(right.x,bridge.end.x) && near(right.y,bridge.end.y),
              "F6 energy terminal remains the second fixed endpoint")
        check(near(bridge.length,146),"full live gauge uses PC v602 146px flow")
        let bar=original.widget(id)!
        let terminal=HudMotionProject600.project(
            x:bar.x+147*bar.scale,
            y:bar.y+4.5*bar.scale,
            pose:still,widget:id)
        check(near(bridge.end.x,vp.x(terminal.x,at:.bottomLeft)) &&
              near(bridge.end.y,vp.y(terminal.y,at:.bottomLeft)),
              "second endpoint follows actual F6 gauge placement")
        let partial=HudPlasmaBridge600.segment(
            id:id,layout:original,pose:still,viewport:vp,fill:0.35)!
        check(near(partial.length,146*0.35),
              "plasma tip follows actual resource amount")
        check(HudPlasmaBridge600.segment(id:id,layout:original,
              pose:still,viewport:vp,fill:0)==nil,
              "no luminous bridge at zero energy")
        var moved=original
        moved.change("armor.bar"){$0.x += 16;$0.y -= 12}
        let shifted=HudPlasmaBridge600.segment(
            id:id,layout:moved,pose:still,viewport:vp,fill:1)!
        check(near(shifted.start.x,bridge.start.x) &&
              near(shifted.start.y,bridge.start.y),
              "moving a gauge cannot drag the original GLB socket")
        check(near(shifted.end.x-bridge.end.x,16*vp.scale) &&
              near(shifted.end.y-bridge.end.y,-12*vp.scale),
              "second endpoint follows separately edited gauge")
        check(moved.widget("hud.planetarium") ==
              original.widget("hud.planetarium"),
              "F6 planetarium storage untouched")

        var flight=HudMotion600.Pose()
        flight.x=13;flight.y = -4;flight.roll=2.1;flight.parallax=true
        let inFlight=HudPlasmaBridge600.segment(
            id:id,layout:original,pose:flight,viewport:vp,fill:1)!
        check(!near(inFlight.start.x,bridge.start.x) ||
              !near(inFlight.start.y,bridge.start.y),
              "3D socket moves together with HUD manoeuvre")
        check(!near(inFlight.end.x,bridge.end.x) ||
              !near(inFlight.end.y,bridge.end.y),
              "energy tip also moves during HUD manoeuvre")
        let movingEnd=HudMotionProject600.project(
            x:bar.x+147*bar.scale,y:bar.y+4.5*bar.scale,
            pose:flight,widget:id)
        check(near(inFlight.end.x,vp.x(movingEnd.x,at:.bottomLeft)) &&
              near(inFlight.end.y,vp.y(movingEnd.y,at:.bottomLeft)),
              "bar terminal shares exact PC source HUD motion matrix")

        // A small change in bank/pitch must produce a small change in
        // both transformed endpoints, without snapping or quantization.
        var next=flight
        next.roll += 0.01
        next.x += 0.05
        let following=HudPlasmaBridge600.segment(
            id:id,layout:original,pose:next,viewport:vp,fill:1)!
        check(hypot(following.start.x-inFlight.start.x,
                    following.start.y-inFlight.start.y)<0.5,
              "original capsule endpoint continuous at display cadence")
        check(hypot(following.end.x-inFlight.end.x,
                    following.end.y-inFlight.end.y)<0.5,
              "original bar endpoint continuous at display cadence")
        for name in ["hull.bar","armor.bar","shield.bar"] {
            let bridge=HudPlasmaBridge600.segment(
                id:name,layout:original,pose:still,viewport:vp,fill:1)!
            check(bridge.project(x:bridge.sourceX,
                  y:bridge.centerY)==bridge.start,
                  "source node "+name+" anchored without distortion")
            let tip=bridge.project(
                x:bridge.sourceX+bridge.length,y:bridge.centerY)
            check(near(tip.x,bridge.end.x) && near(tip.y,bridge.end.y),
                  "source gauge "+name+" independently anchored")
        }
        print("PASS original 3×2-ended plasma: exact GLB sockets, independent F6 terminals, continuous live 60 Hz pose, real fractions")
    }
}
