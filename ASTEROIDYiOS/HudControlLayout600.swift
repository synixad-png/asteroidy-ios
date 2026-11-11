import Foundation

/// Five native touch controls, independent from the approved 46 PC v602 HUD
/// widgets. Source x/y are additive offsets (1280x720 units) from each
/// control's original iOS position; scale changes the REAL touch hitbox.
struct HudControlLayout600:Codable,Equatable {
    struct Control:Codable,Equatable,Identifiable {
        var id:String
        var x:Double
        var y:Double
        var scale:Double
    }

    struct Frame:Equatable {
        let centerX:Double
        let centerY:Double
        let width:Double
        let height:Double
    }

    var schema:Int
    var controls:[Control]

    private static let key="asteroidy.ios.hud.function-controls.v1"
    static let ids=["control.pause","control.bomb","control.shield",
                    "control.boost","control.options"]

    static func defaults()->HudControlLayout600 {
        HudControlLayout600(schema:1,controls:ids.map {
            Control(id:$0,x:0,y:0,scale:1)
        })
    }

    var isValid:Bool {
        schema==1 && controls.count==Self.ids.count &&
        Set(controls.map(\.id))==Set(Self.ids) &&
        controls.allSatisfy {
            $0.x.isFinite && $0.y.isFinite && $0.scale.isFinite &&
            (-1500...1500).contains($0.x) && (-900...900).contains($0.y) &&
            (0.65...3.5).contains($0.scale)
        }
    }

    static func load()->HudControlLayout600 {
        guard let data=UserDefaults.standard.data(forKey:key),
              let value=try? JSONDecoder().decode(Self.self,from:data),
              value.isValid else {return defaults()}
        return value
    }
    @discardableResult func save()->Bool {
        guard isValid,let data=try? JSONEncoder().encode(self) else{return false}
        UserDefaults.standard.set(data,forKey:Self.key)
        return true
    }
    static func restoreDefaults()->HudControlLayout600 {
        UserDefaults.standard.removeObject(forKey:key)
        return defaults()
    }

    func control(_ id:String)->Control? {controls.first{$0.id==id}}
    mutating func change(_ id:String,_ edit:(inout Control)->Void) {
        guard let index=controls.firstIndex(where:{$0.id==id}) else{return}
        let previous=controls[index]
        edit(&controls[index])
        if !isValid {controls[index]=previous}
    }
    static func title(_ id:String)->String {
        switch id {
        case "control.pause":return "PAUZA"
        case "control.bomb":return "BOMBA"
        case "control.shield":return "TARCZA"
        case "control.boost":return "DOPALACZ"
        case "control.options":return "OPCJE / USTAWIENIA"
        default:return id
        }
    }

    /// Physical screen placement used by both UIKit F6 hit testing and the
    /// real SwiftUI controls. No invisible secondary static hit targets.
    static func frame(_ control:Control,viewport:CombatHUDViewport568,
                      compact:Bool)->Frame {
        let centerX=viewport.pauseCenterX
        let pauseY=viewport.pauseCenterY
        let baselineY:Double
        let nativeWidth:Double
        switch control.id {
        case "control.pause":
            baselineY=pauseY;nativeWidth=compact ? 64:78
        case "control.bomb":
            baselineY=pauseY+45;nativeWidth=compact ? 95:115
        case "control.shield":
            baselineY=pauseY+90;nativeWidth=compact ? 115:138
        case "control.boost":
            baselineY=pauseY+135;nativeWidth=compact ? 130:158
        default:
            // Reference rectangle for the OPTIONS control shown only in
            // pause menu. The modal uses the SAME offset and scale.
            baselineY=viewport.height/2+(compact ? 2:12)
            nativeWidth=compact ? 210:285
        }
        let w=max(44,nativeWidth*control.scale)
        let h=max(44,(compact ? 42:48)*control.scale)
        return Frame(
            centerX:centerX+control.x*viewport.scale,
            centerY:baselineY+control.y*viewport.scale,
            width:w,height:h)
    }

    static func limits(_ id:String,viewport:CombatHUDViewport568,
                       compact:Bool,scale:Double)
        ->(x:ClosedRange<Double>,y:ClosedRange<Double>) {
        let prototype=Control(id:id,x:0,y:0,scale:scale)
        let base=frame(prototype,viewport:viewport,compact:compact)
        let unit=max(0.001,viewport.scale)
        let halfW=base.width/2,halfH=base.height/2
        // Keep buttons within actual safe screen bounds. A wide button
        // still has a reachable hit target on a narrow iPhone.
        let minX=viewport.left+halfW
        let maxX=viewport.width-viewport.right-halfW
        let minY=viewport.top+halfH
        let maxY=viewport.height-viewport.bottom-halfH
        let xr=(min(minX,maxX)-base.centerX)/unit...(max(minX,maxX)-base.centerX)/unit
        let yr=(min(minY,maxY)-base.centerY)/unit...(max(minY,maxY)-base.centerY)/unit
        return (max(-1500,xr.lowerBound)...min(1500,xr.upperBound),
                max(-900,yr.lowerBound)...min(900,yr.upperBound))
    }

    mutating func move(_ id:String,from original:Control,
                       deltaX:Double,deltaY:Double,
                       viewport:CombatHUDViewport568,compact:Bool) {
        guard deltaX.isFinite,deltaY.isFinite,
              viewport.scale.isFinite,viewport.scale>0 else{return}
        let ranges=Self.limits(id,viewport:viewport,compact:compact,
                               scale:original.scale)
        change(id){control in
            control.x=min(ranges.x.upperBound,
                          max(ranges.x.lowerBound,
                              original.x+deltaX/viewport.scale))
            control.y=min(ranges.y.upperBound,
                          max(ranges.y.lowerBound,
                              original.y+deltaY/viewport.scale))
        }
    }
    mutating func zoom(_ id:String,originalScale:Double,factor:Double,
                       viewport:CombatHUDViewport568,compact:Bool) {
        guard originalScale.isFinite,factor.isFinite,
              originalScale>0,factor>0 else{return}
        change(id){control in
            let next=min(3.5,max(0.65,originalScale*factor))
            let ranges=Self.limits(id,viewport:viewport,compact:compact,
                                   scale:next)
            control.scale=next
            control.x=min(ranges.x.upperBound,
                          max(ranges.x.lowerBound,control.x))
            control.y=min(ranges.y.upperBound,
                          max(ranges.y.lowerBound,control.y))
        }
    }
}
