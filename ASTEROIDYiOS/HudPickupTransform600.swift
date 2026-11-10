import Foundation
import simd

/// HUD-only transform for existing PC586 Metal pickup buffers.
/// Exactly four objects, independent low-angle oscillation, no 360° spin.
/// Screen anchoring agrees with CombatHUDViewport568 bottom-right group.
enum HudPickupTransform600 {
    struct Sample {
        let x:Float,y:Float
        let yaw:Float,pitch:Float,roll:Float
        let size:Float
    }
    static let order:[SourcePickupModels586.Kind] = [
        .energy,.bomb,.shield,.boost
    ]
    static func sample(index:Int,time:Float,pose:HudMotion600.Pose,
                       drawableWidth:Float,drawableHeight:Float,
                       widget:HudLayout600.Widget? = nil)->Sample? {
        guard (0..<4).contains(index),time.isFinite,
              drawableWidth.isFinite,drawableHeight.isFinite,
              drawableWidth>1,drawableHeight>1 else{return nil}
        let scale=max(0.001,min(drawableWidth/1280,drawableHeight/720))
        let phase=time*0.60+Float(index)*1.71
        let secondary=time*0.37+Float(index)*0.83
        let decay=pose.iconStrength
        let yaw=sin(phase)*0.080+cos(secondary)*0.026
            +max(-0.13,min(0.13,pose.x*0.0030*decay))
        let pitch=sin(secondary*1.17)*0.059
            +max(-0.09,min(0.09,pose.y*0.004*decay))
        let roll=sin(phase*0.72)*0.041
            +max(-0.065,min(0.065,pose.roll*0.012*decay))
        // Original PC source icons: 920 + 100*i, y=628 on 1280x720.
        // Clamp the decorative element into the physical screen, never
        // move/crop touch regions or the stable aiming reticle.
        let sourceX=Float(widget?.x ?? Double(895+index*100))+25
        let x=drawableWidth-10*scale-(1280-sourceX)*scale
              +pose.x*0.78*scale
        let sourceY=Float(widget?.y ?? 603)+25
        let y=drawableHeight-9*scale-(720-sourceY)*scale
              +pose.y*0.78*scale
        return Sample(x:max(22*scale,min(drawableWidth-22*scale,x)),
                      y:max(22*scale,min(drawableHeight-22*scale,y)),
                      yaw:yaw+Float(widget?.yaw ?? 0)*Float.pi/180,
                      pitch:pitch+Float(widget?.pitch ?? 0)*Float.pi/180,
                      roll:roll+Float(widget?.roll ?? 0)*Float.pi/180,
                      size:45*scale*Float(widget?.scale ?? 1))
    }
    static func model(_ s:Sample)->simd_float4x4 {
        let rotate=simd_float4x4(simd_quatf(angle:s.yaw,axis:SIMD3<Float>(0,1,0))
            * simd_quatf(angle:s.pitch,axis:SIMD3<Float>(1,0,0))
            * simd_quatf(angle:s.roll,axis:SIMD3<Float>(0,0,1)))
        var lift=matrix_identity_float4x4
        lift.columns.3.y = -0.5
        return rotate*lift
    }
    static func mvp(_ s:Sample,width:Float,height:Float)->simd_float4x4 {
        var translation=matrix_identity_float4x4
        translation.columns.3=SIMD4<Float>(2*s.x/width-1,
                                             1-2*s.y/height,0,1)
        var stretch=matrix_identity_float4x4
        stretch.columns.0.x=2*s.size/width
        stretch.columns.1.y=2*s.size/height
        stretch.columns.2.z=0.15
        return translation*stretch*model(s)
    }
}
