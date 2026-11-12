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
    static let ids=[
        "hud.mission","hud.telemetry","hud.atlas-grid","hud.dock",
        "hud.entry-label","hud.navigation",
        "control.options","control.atlas","control.next",
        "control.pause","control.enter"
    ]
    private static let key="asteroidy.ios.pc602.orbit-hud-layout291.v1"
    var schema:Int=1
    var elements:[Element]

    static func defaults()->Self {
        Self(elements:ids.map{Element(id:$0)})
    }
    var valid:Bool {
        schema==1 && elements.count==Self.ids.count &&
        Set(elements.map(\.id))==Set(Self.ids) &&
        elements.allSatisfy {
            $0.x.isFinite && $0.y.isFinite && $0.scale.isFinite &&
            (-600...600).contains($0.x) && (-360...360).contains($0.y) &&
            (0.55...2.5).contains($0.scale) &&
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
    static func title(_ id:String)->String {
        switch id {
        case "hud.mission":return "HUD / CEL, KURS, ODLEGŁOŚĆ"
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