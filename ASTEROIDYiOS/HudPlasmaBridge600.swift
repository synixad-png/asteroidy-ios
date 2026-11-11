import Foundation

/// Screen-space elastic connection: original authored damage capsule socket
/// at one end, live PC602 energy gauge terminal at the other. Both anchors
/// are projected through the SAME HUD pose as their owners each display tick.
/// No new game mechanics, no GLB changes and no mutations of the 46 F6 widgets.
enum HudPlasmaBridge600 {
    struct Point:Equatable {
        let x:Double
        let y:Double
    }
    struct Segment {
        let start:Point
        let end:Point
        let length:Double        // source PC602 illuminated width (0...146)
        let thickness:Double     // F6 bar scale * viewport scale
        let sourceX:Double       // RendererHudEnergy x + 1
        let centerY:Double      // RendererHudEnergy y + 4.5

        /// Bend the existing PC602 five ribbon layers to two live endpoints.
        /// This preserves the ORIGINAL sampled wave coordinates and colors;
        /// only its geometric baseline becomes a live segment.
        func project(_ source:HudEnergy600.Point)->Point {
            let directionX=end.x-start.x
            let directionY=end.y-start.y
            let distance=hypot(directionX,directionY)
            guard distance>0.000001,length>0 else{return start}
            let fraction=(source.x-sourceX)/length
            let normalOffset=(source.y-centerY)*thickness
            return Point(
                x:start.x+fraction*directionX-normalOffset*directionY/distance,
                y:start.y+fraction*directionY+normalOffset*directionX/distance)
        }
        func project(x:Double,y:Double)->Point {
            project(HudEnergy600.Point(x:x,y:y))
        }
    }
    // Names and exact source-space translations of the three root-level
    // DAMAGE_*_FILL_SOCKET nodes in the SHA-verified PC v602 planetarium.glb.
    // These nodes have no authored animation channel; the rest of the
    // model may animate independently without changing the joint.
    private static let sockets:[(id:String,x:Double,y:Double,z:Double)] = [
        ("hull.bar",3.18,1.28,0),
        ("armor.bar",3.18,0,0),
        ("shield.bar",3.18,-1.28,0)
    ]
    private static let width=148.0
    private static let sourceX=192.0

    static func segment(id:String,layout:HudLayout600,
                        pose:HudMotion600.Pose,
                        viewport:CombatHUDViewport568,
                        fill:Double)->Segment? {
        guard let spec=sockets.first(where:{$0.id==id}),
              let widget=layout.widget("hud.planetarium"),widget.visible,
              let bar=layout.widget(id),bar.visible,
              bar.scale>0,bar.scale.isFinite,
              fill.isFinite,fill>0,
              let dims=HudWidgetGeometry600.size(widget.id),
              let placement=HudWidgetPlacement600.frame(
                  widget,sourceWidth:dims.width,sourceHeight:dims.height,
                  anchor:.bottomLeft,viewport:viewport),
              let projection=HudPlanetariumProjection.make(
                  placement:placement,viewport:viewport,widget:widget,
                  modelRadius:HudPlanetariumAsset600.pc602ModelRadius),
              let pivot=HudPlanetariumPlasmaAnchor600.screenCenter(
                  widget:widget,layout:layout,pose:pose,viewport:viewport)
        else{return nil}

        // Match HudPlanetariumMetal600.hudMatrix: Yaw * Pitch * Roll,
        // scale 0.44*250*F6 scale/radius and original glTF centre.
        let a=(widget.roll ?? 0)+Double(
            HudPlanetariumPlasmaAnchor600.visualRoll(pose:pose))
        let b=widget.pitch ?? -20
        let c=widget.yaw ?? 0
        let roll=a*Double.pi/180
        let pitch=b*Double.pi/180
        let yaw=c*Double.pi/180
        let dx=spec.x-Double(HudPlanetariumAsset600.pc602ModelCenterX)
        let dy=spec.y-Double(HudPlanetariumAsset600.pc602ModelCenterY)
        let dz=spec.z-Double(HudPlanetariumAsset600.pc602ModelCenterZ)
        let xx=dx*cos(roll)-dy*sin(roll)
        let yy=dx*sin(roll)+dy*cos(roll)
        let yPitch=yy*cos(pitch)-dz*sin(pitch)
        let zPitch=yy*sin(pitch)+dz*cos(pitch)
        let xYaw=xx*cos(yaw)+zPitch*sin(yaw)
        let start=Point(
            x:pivot.x+projection.pixelsPerModelUnit*xYaw,
            y:pivot.y-projection.pixelsPerModelUnit*yPitch)

        // The other end follows the *actual* lighted plasma fraction.
        // The dark 148px guide remains at its original F6 location.
        let litLength=(width-2)*min(1,max(0,fill))
        let logicalX=bar.x+bar.scale*(1+litLength)
        let logicalY=bar.y+bar.scale*4.5
        let corrected=HudMotionProject600.project(
            x:logicalX,y:logicalY,pose:pose,widget:id)
        let end=Point(x:viewport.x(corrected.x,at:.bottomLeft),
                      y:viewport.y(corrected.y,at:.bottomLeft))
        return Segment(start:start,end:end,length:litLength,
                       thickness:bar.scale*viewport.scale,
                       sourceX:sourceX,centerY:4.5)
    }
}
