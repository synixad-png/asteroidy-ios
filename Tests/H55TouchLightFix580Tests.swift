import Foundation

@main struct H55TouchLightFix580Tests {
    static func check(_ yes:Bool,_ what:String) {
        precondition(yes,"H55 TOUCH/LIGHT: "+what)
    }
    static func approx(_ a:Float,_ b:Float)->Bool {
        abs(a-b)<0.0001
    }
    static func main() {
        let up=H55TouchMapping580.walk(dx:0,dy:-78)
        let down=H55TouchMapping580.walk(dx:0,dy:78)
        let left=H55TouchMapping580.walk(dx:-78,dy:0)
        let right=H55TouchMapping580.walk(dx:78,dy:0)
        check(approx(up.forward,1)&&approx(up.right,0),"finger up = forward")
        check(approx(down.forward,-1),"finger down = backward")
        check(approx(left.right,-1),"finger left = strafe left")
        check(approx(right.right,1),"finger right = strafe right")
        let diagonal=H55TouchMapping580.walk(dx:78,dy:-78)
        check(approx(hypot(diagonal.forward,diagonal.right),1),
              "no diagonal speed exploit")
        let invalid=H55TouchMapping580.walk(dx:Float.nan,dy:-90)
        check(invalid.forward==0 && invalid.right==0,"invalid drag cancels")

        // PC H06 player at yaw +: physics forward = (+sin(yaw), -cos(yaw)).
        // SceneKit's positive Y rotation maps local -Z toward -X; therefore
        // camera Euler Y must be NEGATIVE of physics yaw for matching view.
        for yaw in stride(from:Float(-3),through:3,by:0.125) {
            let scene=H55TouchMapping580.sceneYaw(for:yaw)
            let cameraForwardX = -sin(scene),cameraForwardZ = -cos(scene)
            let worldForwardX = sin(yaw),worldForwardZ = -cos(yaw)
            check(approx(cameraForwardX,worldForwardX) &&
                  approx(cameraForwardZ,worldForwardZ),
                  "camera forward matches H06 velocity for every yaw")
            let cameraRightX=cos(scene), cameraRightZ = -sin(scene)
            check(approx(cameraRightX,cos(yaw)) &&
                  approx(cameraRightZ,sin(yaw)),
                  "camera right matches H06 right strafe")
        }
        var walk=H55Walk580()
        walk.look(deltaX:100,deltaY:-100) // drag RIGHT then UP
        check(walk.yaw>0 && walk.pitch>0 &&
              H55TouchMapping580.sceneYaw(for:walk.yaw)<0 &&
              H55TouchMapping580.scenePitch(for:walk.pitch)>0,
              "right drag turns right, upward drag looks upward")

        let white="H46_GENERAL_SPOT_01_KHR_SPOT"
        let red="H46_DOCK_01_RED_POINT_LIGHT"
        let redUpper="H46_UPPER_RED_-1_1_POINT"
        let scan="H46_SCAN_SPOT_09_KHR_SPOT"
        check(H55LightBalance580.budget==8,"PC fallback 8-light budget")
        check(H55LightBalance580.isRed(red) && H55LightBalance580.isRed(redUpper),
              "all source red lamp families")
        check(!H55LightBalance580.isRed(white) &&
              H55LightBalance580.isScanner(scan),
              "no false red classification")
        let r=H55LightBalance580.sourceFallbackColor(red)
        let s=H55LightBalance580.sourceFallbackColor(scan)
        let w=H55LightBalance580.sourceFallbackColor(white)
        check(approx(r.r,2.5) && approx(r.g,0.14) && approx(r.b,0.05) &&
              approx(s.r,0.45) && approx(s.g,2.4) &&
              approx(w.r,1.6) && approx(w.g,2.0),
              "source H55Renderer fallback palette")
        check(approx(H55LightBalance580.score(red,distanceSquared:0),
                     (2.5+0.14+0.05)/40),"PC exact relevance score")
        check(approx(H55LightBalance580.sceneIntensity(red,raw:180),
                     180*0.22*H55LightingProfile580.defaultRed) &&
              approx(H55LightBalance580.sceneIntensity(white,raw:2300),
                     2300*0.22),"source H46 non-red gain and new red default")
        check(H55LightBalance580.maxRedActive==2,
              "SceneKit H46 may not select more than two red lights")
        let candidates:[H55LightBalance580.Candidate] = [
            .init(name:red,distanceSquared:1),
            .init(name:redUpper,distanceSquared:2),
            .init(name:"H46_DOCK_02_RED_POINT",distanceSquared:3),
            .init(name:"H46_DOCK_03_RED_POINT",distanceSquared:4),
            .init(name:"H46_DOCK_04_RED_POINT",distanceSquared:5),
            .init(name:scan,distanceSquared:6),
            .init(name:white,distanceSquared:7),
            .init(name:"H46_GENERAL_SPOT_02_KHR_SPOT",distanceSquared:8),
            .init(name:"H46_GENERAL_SPOT_03_KHR_SPOT",distanceSquared:9),
            .init(name:"H46_GENERAL_SPOT_04_KHR_SPOT",distanceSquared:10),
            .init(name:"H46_GENERAL_SPOT_05_KHR_SPOT",distanceSquared:11),
            .init(name:"H46_GENERAL_SPOT_06_KHR_SPOT",distanceSquared:12)
        ]
        let selected=H55LightBalance580.selectedNames(candidates)
        check(selected.count==8 &&
              selected.filter {H55LightBalance580.isRed($0)}.count==2 &&
              selected.filter {!H55LightBalance580.isRed($0)}.count==6,
              "white/cyan H46 lights must remain available within eight slots")
        check(selected==H55LightBalance580.selectedNames(candidates.reversed()),
              "deterministic H46 balancing regardless of dictionary iteration")
        check(H55LightBalance580.selectedNames([
            .init(name:"H46_DOCK_RED",distanceSquared:Float.nan),
            .init(name:white,distanceSquared:Float.infinity)
        ]).isEmpty,"invalid distance inputs cannot activate lights")
        let clamped=H55LightingProfile580(fill:Float.infinity,red:-3)
        check(approx(clamped.fill,H55LightingProfile580.defaultFill) &&
              clamped.red==0,"invalid and negative persisted lighting values sanitized")
        let maxed=H55LightingProfile580(fill:99,red:88)
        check(maxed.fill==H55LightingProfile580.maximumFill &&
              maxed.red==H55LightingProfile580.maximumRed,
              "live lighting cannot exceed safe maximums")
        check(approx(H55LightBalance580.sceneIntensity(red,raw:180,redGain:0),0) &&
              approx(H55LightBalance580.sceneIntensity(red,raw:180,redGain:0.3),
                     180*0.22*0.3),"live red dimming is deterministic")
        check(H55LightBalance580.sceneIntensity(red,raw:-1)==0 &&
              H55LightBalance580.score(white,distanceSquared:Float.nan)==0,
              "invalid brightness never propagates")
        print("PASS H55 new touch mapping (4 axes, diagonal, camera view in 49 yaw headings, vertical look), source H46 family-aware eight-light balance, persisted neutral fill and red controls")
    }
}
