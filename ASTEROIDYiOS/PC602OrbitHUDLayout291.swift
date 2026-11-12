import Foundation

/// Independent H290 overlay editor. The previously approved combat HUD v600
/// and touch-control positions are never mutated by orbit edits.
struct PC602OrbitHUDLayout291:Codable,Equatable {
    struct Element:Codable,Equatable,Identifiable {
        let id:String
        var x:Double
        var y:Double
        var scale:Double
        var visible:Bool

        init(id:String,x:Double=0,y:Double=0,scale:Double=1,
             visible:Bool=true) {
            self.id=id;self.x=x;self.y=y;self.scale=scale
            self.visible=visible
        }
        private enum CodingKeys:String,CodingKey {
            case id,x,y,scale,visible
        }
        // Existing H290 layouts predating visibility remain readable.
        init(from decoder:Decoder)throws {
            let data=try decoder.container(keyedBy:CodingKeys.self)
            id=try data.decode(String.self,forKey:.id)
            x=try data.decode(Double.self,forKey:.x)
            y=try data.decode(Double.self,forKey:.y)
            scale=try data.decode(Double.self,forKey:.scale)
            visible=try data.decodeIfPresent(Bool.self,forKey:.visible) ?? true
        }
    }
    /// The first 11 IDs are the original H290 layout and remain stable.
    /// Leaf IDs let the player select each *actual* on-screen text, just as
    /// the 46 independent widgets in HudLayoutEditor600 (mission F6).
    static let legacyIDs=[
        "hud.mission","hud.telemetry","hud.atlas-grid","hud.dock",
        "hud.entry-label","hud.navigation",
        "control.options","control.atlas","control.next",
        "control.pause","control.enter"
    ]
    static let ids=legacyIDs+[
        "hud.mission.heading","hud.mission.target",
        "hud.mission.distance","hud.mission.course",
        "hud.mission.completed","hud.mission.locked",
        "hud.telemetry.progress","hud.telemetry.zone",
        "hud.telemetry.altitude","hud.telemetry.speed",
        "hud.dock.distance","hud.dock.status","hud.dock.hint",
        "hud.navigation.label","hud.warning","hud.error"
    ]
    private static let key="asteroidy.ios.pc602.orbit-hud-layout291.v1"
    var schema:Int=1
    var elements:[Element]

    private enum CodingKeys:String,CodingKey {
        case schema,elements
    }
    init(schema:Int=1,elements:[Element]) {
        self.schema=schema
        self.elements=elements
    }
    /// Existing saved 11-element H290 JSON is migrated without changing
    /// ANY original group position, scale or visibility. New atomic labels
    /// default to identity transforms within the existing group container.
    init(from decoder:Decoder)throws {
        let c=try decoder.container(keyedBy:CodingKeys.self)
        schema=try c.decode(Int.self,forKey:.schema)
        let incoming=try c.decode([Element].self,forKey:.elements)
        let names=incoming.map(\.id)
        guard names.count==Set(names).count else{throw LayoutError.invalid}
        let present=Set(names)
        if present==Set(Self.legacyIDs) {
            elements=incoming+Self.ids.filter{!present.contains($0)}.map{
                Element(id:$0)
            }
        } else {
            elements=incoming
        }
    }

    static func defaults()->Self {
        Self(elements:ids.map{Element(id:$0)})
    }
    var valid:Bool {
        schema==1 && elements.count==Self.ids.count &&
        Set(elements.map(\.id))==Set(Self.ids) &&
        elements.allSatisfy {
            $0.x.isFinite && $0.y.isFinite && $0.scale.isFinite &&
            (-600...600).contains($0.x) && (-360...360).contains($0.y) &&
            Self.scaleRange(for:$0.id).contains($0.scale) &&
            (!$0.id.hasPrefix("control.") || $0.visible)
        }
    }
    static func load(defaults:UserDefaults = .standard)->Self {
        guard let bytes=defaults.data(forKey:key),
              let data=try? JSONDecoder().decode(Self.self,from:bytes),
              data.valid else {return .defaults()}
        return data
    }
    static func decodeJSON(_ bytes:Data)throws->Self {
        let value=try JSONDecoder().decode(Self.self,from:bytes)
        guard value.valid else {throw LayoutError.invalid}
        return value
    }
    enum LayoutError:Error {case invalid}

    @discardableResult func save(defaults:UserDefaults = .standard)->Bool {
        guard valid,let data=try? JSONEncoder().encode(self) else{return false}
        defaults.set(data,forKey:Self.key)
        return true
    }
    func item(_ id:String)->Element {
        elements.first{$0.id==id} ?? Element(id:id)
    }
    mutating func change(_ id:String,_ edit:(inout Element)->Void) {
        guard let index=elements.firstIndex(where:{$0.id==id}) else{return}
        let old=elements[index]
        edit(&elements[index])
        if !valid {elements[index]=old}
    }
    /// UIKit and the SwiftUI screen share the SAME validated physical
    /// rectangles. Like HudEditorGeometry.hit, smaller overlapping widgets
    /// win; all five controls take precedence over passive HUD text.
    static func scaleRange(for id:String)->ClosedRange<Double> {
        // Same constraints as the working F6/HudControlLayout600:
        // 2D HUD 0.25–3; function buttons 0.65–3.5; PAUZA at top is
        // intentionally capped at 1.5 to keep the pause escape route.
        if id=="control.options" {return 0.65...1.5}
        if id.hasPrefix("control.") {return 0.65...3.5}
        return 0.25...3
    }
    /// Exactly like HudEditorGeometry.Rect: source geometry uses Double
    /// rather than UIKit/CoreGraphics, so the model is testable on
    /// macOS and Linux while the game renders with native UIKit.
    struct Rect:Equatable {
        let x:Double
        let y:Double
        let width:Double
        let height:Double
        var minX:Double{x}
        var maxX:Double{x+width}
        var minY:Double{y}
        var maxY:Double{y+height}
        var midX:Double{x+width/2}
        var midY:Double{y+height/2}
        func contains(_ px:Double,_ py:Double)->Bool {
            px>=minX && px<=maxX && py>=minY && py<=maxY
        }
    }
    static func touchFrame(_ rect:Rect)->Rect? {
        guard rect.x.isFinite,rect.y.isFinite,
              rect.width.isFinite,rect.height.isFinite,
              rect.width>0,rect.height>0 else{return nil}
        let w=max(44.0,rect.width)
        let h=max(44.0,rect.height)
        return Rect(x:rect.midX-w/2,y:rect.midY-h/2,width:w,height:h)
    }
    static func hit(x:Double,y:Double,
                    frames:[String:Rect],layout:Self)->String? {
        for id in Self.ids.reversed() where id.hasPrefix("control.") {
            guard let box=frames[id].flatMap(touchFrame),
                  box.contains(x,y) else{continue}
            return id
        }
        var chosen:String?
        var smallest=Double.infinity
        for id in Self.ids.reversed() where id.hasPrefix("hud.") {
            guard layout.item(id).visible,
                  let raw=frames[id],let box=touchFrame(raw),
                  box.contains(x,y) else{continue}
            let area=raw.width*raw.height
            if area<smallest {
                smallest=area
                chosen=id
            }
        }
        return chosen
    }

    /// The same source constraints as HudEditorGeometry.move and
    /// HudControlLayout600.limits. Functional buttons stay fully reachable;
    /// HUD text keeps at least 12 points on screen.
    static func constrainedDrag(_ id:String,deltaX:Double,deltaY:Double,
                                frame:Rect,viewportWidth:Double,
                                viewportHeight:Double,
                                safeInsets:(left:Double,right:Double,
                                            top:Double,bottom:Double) =
                                (0,0,0,0))->(x:Double,y:Double) {
        guard deltaX.isFinite,deltaY.isFinite,
              let box=touchFrame(frame),
              viewportWidth.isFinite,viewportHeight.isFinite,
              viewportWidth>0,viewportHeight>0 else{return (0,0)}
        let control=id.hasPrefix("control.")
        let visible=control ? 0.0:12.0
        let left=safeInsets.left+visible
        let right=viewportWidth-safeInsets.right-visible
        let top=safeInsets.top+visible
        let bottom=viewportHeight-safeInsets.bottom-visible
        let minX=left-(control ? box.minX:box.maxX)
        let maxX=right-(control ? box.maxX:box.minX)
        let minY=top-(control ? box.minY:box.maxY)
        let maxY=bottom-(control ? box.maxY:box.minY)
        func clamp(_ value:Double,_ lower:Double,_ upper:Double)->Double {
            lower>upper ? (lower+upper)*0.5 : min(upper,max(lower,value))
        }
        return (clamp(deltaX,minX,maxX),clamp(deltaY,minY,maxY))
    }

    static func title(_ id:String)->String {
        switch id {
        case "hud.mission":return "HUD / GRUPA MISJI"
        case "hud.mission.heading":return "HUD / TYTUŁ ATLASU"
        case "hud.mission.target":return "HUD / NAZWA CELU"
        case "hud.mission.distance":return "HUD / ODLEGŁOŚĆ OD CELU"
        case "hud.mission.course":return "HUD / KURS"
        case "hud.mission.completed":return "HUD / UKOŃCZONA"
        case "hud.mission.locked":return "HUD / BLOKADA MISJI"
        case "hud.telemetry.progress":return "HUD / POSTĘP"
        case "hud.telemetry.zone":return "HUD / STREFA"
        case "hud.telemetry.altitude":return "HUD / PUŁAP"
        case "hud.telemetry.speed":return "HUD / PRĘDKOŚĆ"
        case "hud.dock.distance":return "HUD / ODLEGŁOŚĆ HANGARU"
        case "hud.dock.status":return "HUD / STATUS DOKOWANIA"
        case "hud.dock.hint":return "HUD / POMOC STEROWANIA"
        case "hud.navigation.label":return "HUD / NAPIS PRZY STRZAŁCE"
        case "hud.warning":return "HUD / OSTRZEŻENIE MISJI"
        case "hud.error":return "HUD / KOMUNIKAT BŁĘDU"
        case "hud.telemetry":return "HUD / POSTĘP, STREFA, PUŁAP, PRĘDKOŚĆ"
        case "hud.atlas-grid":return "HUD / SIATKA 26 MISJI"
        case "hud.dock":return "HUD / INFORMACJE HANGARU"
        case "hud.entry-label":return "HUD / OPIS WEJŚCIA"
        case "hud.navigation":return "HUD / STRZAŁKA NAWIGACYJNA"
        case "control.options":return "PRZYCISK / PAUZA (GÓRA)"
        case "control.atlas":return "PRZYCISK / ATLAS"
        case "control.next":return "PRZYCISK / CEL +"
        case "control.pause":return "PRZYCISK / PAUZA"
        case "control.enter":return "PRZYCISK / WEJDŹ"
        default:return id
        }
    }
}