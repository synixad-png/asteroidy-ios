import Foundation

@main enum HudPlanetariumPlasmaAnchorTests {
    private static func verify(_ condition:@autoclosure ()->Bool,
                               _ description:String) {
        precondition(condition(),description)
    }
    private static func near(_ x:Double,_ y:Double,_ tolerance:Double=0.0001)->Bool {
        abs(x-y)<tolerance
    }

    static func main() {
        let baseline=HudLayout600.defaults()
        verify(baseline.widgets.count==46,"approved unchanged 46-element editor")
        guard let widget=baseline.widget("hud.planetarium") else{
            preconditionFailure("missing PC602 3D planetarium")
        }
        let source=HudPlanetariumPlasmaAnchor600.sourceCenter(
            widget:widget,layout:baseline)!
        verify(near(source.x,widget.x+125) &&
               near(source.y,widget.y+67.5),
               "the original approved planetarium must not jump at rest")
        let vp=CombatHUDViewport568(width:956,height:440,
                                    safeLeft:59,safeRight:59,safeBottom:21)
        let atRest=HudPlanetariumPlasmaAnchor600.screenCenter(
            widget:widget,layout:baseline,pose:.init(),viewport:vp)!
        verify(near(atRest.x,vp.x(source.x,at:.bottomLeft)) &&
               near(atRest.y,vp.y(source.y,at:.bottomLeft)),
               "screen anchor matches the original F6 layout on iPhone")

        // Editing all 3 energy bars as a group must move the GLB once,
        // without changing the original planetarium's F6 x/y/scale.
        var moved=baseline
        for id in ["hull.bar","armor.bar","shield.bar"] {
            moved.change(id){$0.x += 17;$0.y -= 9}
        }
        let shifted=HudPlanetariumPlasmaAnchor600.sourceCenter(
            widget:widget,layout:moved)!
        verify(near(shifted.x,source.x+17) &&
               near(shifted.y,source.y-9),
               "whole plasma group pulls the planetarium by the same delta")
        verify(moved.widget("hud.planetarium")==widget,
               "dynamic tether never mutates the approved stored GLB")
        let originAgain=HudPlanetariumPlasmaAnchor600.sourceCenter(
            widget:widget,layout:baseline)!
        verify(near(originAgain.x,source.x) && near(originAgain.y,source.y),
               "no hidden accumulation across frames")

        // All three animated plasma bars use weight(.bar)=.78 when moving.
        // Apply that SAME virtual screen roll and displacement to the GLB.
        var flight=HudMotion600.Pose()
        flight.parallax=true
        flight.x=13;flight.y = -3
        flight.roll=2.2
        let expected=HudMotionProject600.project(
            x:source.x,y:source.y,pose:flight,widget:"armor.bar")
        let tethered=HudPlanetariumPlasmaAnchor600.screenCenter(
            widget:widget,layout:baseline,pose:flight,viewport:vp)!
        verify(near(tethered.x,vp.x(expected.x,at:.bottomLeft)) &&
               near(tethered.y,vp.y(expected.y,at:.bottomLeft)),
               "planetarium inherits the live plasma-screen motion")
        verify(near(Double(HudPlanetariumPlasmaAnchor600.visualRoll(
            pose:flight)),Double(flight.roll)*0.78,0.0002),
            "the 3D body rolls with the same 0.78 plasma weight")

        // Editing only planetarium remains independent and reversible in F6.
        var separate=baseline
        separate.change("hud.planetarium"){$0.x += 20;$0.y -= 10}
        let independent=HudPlanetariumPlasmaAnchor600.sourceCenter(
            widget:separate.widget("hud.planetarium")!,layout:separate)!
        verify(near(independent.x,source.x+20) &&
               near(independent.y,source.y-10),
               "working F6 planetarium dragging is preserved")

        // Three gauges contain different status values, but the original GLB
        // is rigid. Moving one gauge cannot pretend to align all three.
        var single=baseline
        single.change("armor.bar"){$0.x += 30}
        let average=HudPlanetariumPlasmaAnchor600.sourceCenter(
            widget:widget,layout:single)!
        verify(near(average.x,source.x+10),
               "one changed gauge contributes only 1/3 group movement")

        var hidden=baseline
        for id in ["hull.bar","armor.bar","shield.bar"] {
            hidden.change(id){$0.visible=false}
        }
        let fallback=HudPlanetariumPlasmaAnchor600.sourceCenter(
            widget:widget,layout:hidden)!
        verify(near(fallback.x,source.x) &&
               near(fallback.y,source.y),
               "hidden gauges cannot pull the planetarium")
        print("PASS PC602 native HUD: stable 46-element F6, plasma-gauge group tether, matching flight parallax/roll, no mutations")
    }
}
