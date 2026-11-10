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
    static let widgetIDs=["ion.icon","bomb.icon",
                          "shield_charge.icon","boost.icon"]
    // Fallback for pure geometry tests. All live Metal calls provide the
    // validated layout widget; never decode JSON in the draw loop.
    private static let defaultLayout600=HudLayout600.defaults()
    static func sample(index:Int,time:Float,pose:HudMotion600.Pose,
                       drawableWidth:Float,drawableHeight:Float,
                       widget:HudLayout600.Widget? = nil,
                       viewport:CombatHUDViewport568? = nil)->Sample? {
        guard (0..<4).contains(index),time.isFinite,
              drawableWidth.isFinite,drawableHeight.isFinite,
              drawableWidth>1,drawableHeight>1 else{return nil}
        let phase=time*0.60+Float(index)*1.71
        let secondary=time*0.37+Float(index)*0.83
        let decay=pose.iconStrength
        let yaw=sin(phase)*0.080+cos(secondary)*0.026
            +max(-0.13,min(0.13,pose.x*0.0030*decay))
        let pitch=sin(secondary*1.17)*0.059
            +max(-0.09,min(0.09,pose.y*0.004*decay))
        let roll=sin(phase*0.72)*0.041
            +max(-0.065,min(0.065,pose.roll*0.012*decay))
        // SwiftUI and Metal must use the same four-corner origin, actual
        // UIWindow safe margins and PC v600 top-left scaling. In adaptive
        // phone mode the drawable can be downscaled independently of points.
        let screen=viewport ?? CombatHUDViewport568(
            width:Double(drawableWidth),height:Double(drawableHeight))
        let defaultID=widgetIDs[index]
        let icon=widget ?? defaultLayout600.widget(defaultID)
        guard let icon,
              let source=HudWidgetPlacement600.frame(icon,sourceWidth:50,
                  sourceHeight:50,anchor:.bottomRight,viewport:screen),
              let pixel=HudWidgetPlacement600.pixels(source,viewport:screen,
                  drawableWidth:Double(drawableWidth),
                  drawableHeight:Double(drawableHeight)) else{return nil}
        let pixelPerPointX=Double(drawableWidth)/screen.width
        let pixelPerPointY=Double(drawableHeight)/screen.height
        let x=Float(pixel.centerX+
            Double(pose.x)*0.78*screen.scale*pixelPerPointX)
        let y=Float(pixel.centerY+
            Double(pose.y)*0.78*screen.scale*pixelPerPointY)
        let pulse=1+pose.widgetPulse(widgetIDs[index])
        let iconSize=Float(min(pixel.width,pixel.height)*0.9)*pulse
        return Sample(x:x,y:y,
                      yaw:yaw+Float(widget?.yaw ?? 0)*Float.pi/180,
                      pitch:pitch+Float(widget?.pitch ?? 0)*Float.pi/180,
                      roll:roll+Float(widget?.roll ?? 0)*Float.pi/180,
                      size:iconSize)
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
