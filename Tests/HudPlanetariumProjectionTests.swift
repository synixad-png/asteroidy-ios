import Foundation

@main enum HudPlanetariumProjectionTests {
    static func test(_ condition: @autoclosure () -> Bool, _ description: String) {
        precondition(condition(), description)
    }
    static func close(_ a:Double,_ b:Double,_ tolerance:Double=1e-6)->Bool {
        abs(a-b)<=tolerance
    }
    static func main() {
        let hud=HudLayout600.defaults()
        let planet=hud.widget("hud.planetarium")!
        let modelRadius=5.112107576242468 // original PC v602 MeasurePlanetBounds463
        test(planet.x==64.7882 && planet.y==553.0863 &&
             planet.scale==1.4702 && planet.pitch == -20,
             "approved PC602 F6 planetarium layout must be unchanged")
        let screens:[CombatHUDViewport568]=[
            .init(width:1280,height:720),
            .init(width:956,height:440,safeLeft:59,safeRight:59,safeBottom:21),
            .init(width:1024,height:768,safeBottom:20)
        ]
        for vp in screens {
            let placement=HudWidgetPlacement600.frame(planet,
                        sourceWidth:250,sourceHeight:135,
                        anchor:.bottomLeft,viewport:vp)!
            let world=HudPlanetariumProjection.make(
                placement:placement,viewport:vp,widget:planet,
                modelRadius:modelRadius)!
            let fixed=world.screenPosition(viewport:vp)
            test(close(fixed.x,placement.centerX)&&close(fixed.y,placement.centerY),
                 "3D pivot must use the real F6 screen centre")
            test(close(world.cameraHalfHeight,vp.height/2),
                 "camera spans the full HUD display, not a 135px widget")
            test(close(world.pixelsPerModelUnit,
                       0.44*250*planet.scale*vp.scale/modelRadius),
                 "PC v602 3D widget pixel scale is exact")
            test(world.pixelsPerModelUnit>0 && world.pixelsPerModelUnit.isFinite,
                 "valid world scale")
            test(close(world.y,vp.height/2-placement.centerY),
                 "UIKit downward Y to SceneKit upward Y transform")
            test(world.x<0 && world.y<0,
                 "original planetarium appears in lower-left HUD quadrant")
            // The source GLB bounding sphere is taller than the *selection*
            // box. Clipping to that old box discarded much of the scene.
            let entireModelHeight=2*modelRadius*world.pixelsPerModelUnit
            test(entireModelHeight>placement.height,
                 "original model must extend beyond F6 selection box")
        }
        var hidden=hud
        hidden.change("hud.planetarium"){$0.visible=false}
        let vp=screens[0]
        let placement=HudWidgetPlacement600.frame(planet,
            sourceWidth:250,sourceHeight:135,anchor:.bottomLeft,viewport:vp)!
        test(HudPlanetariumProjection.make(
            placement:placement,viewport:vp,
            widget:hidden.widget("hud.planetarium")!,modelRadius:modelRadius)==nil,
            "invisible GLB is never rendered")
        test(HudPlanetariumProjection.make(
            placement:placement,viewport:vp,
            widget:planet,modelRadius:0)==nil,
            "invalid asset radius cannot enter renderer")
        print("PASS PC602 planetarium: true 1280x720 HUD camera, source scale, all-screen anchors, no widget clipping")
    }
}
