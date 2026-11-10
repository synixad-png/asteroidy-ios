import Foundation

/// Exact 60 stable PC v586 action indices from Windows/src/Controls.cs.
/// The extra five are settings, NOT playable actions. Keep indices fixed
/// for PC controls-v29.txt compatibility and future source engine ports.
enum SourceControls586 {
    static let actionCount=60
    static let extraCount=5
    static let rowCount=65
    static let labels:[String]=[
        "LEWO / SKRĘT W ATLASIE",
        "PRAWO / SKRĘT W ATLASIE",
        "GÓRA / CIĄG W ATLASIE",
        "DÓŁ / HAMULEC W ATLASIE",
        "STRAFE W LEWO",
        "STRAFE W PRAWO",
        "STRZAŁ",
        "BOMBY / UŻYJ",
        "ZMIEŃ BROŃ",
        "PAUZA",
        "PROM WIERTNICZY: ODŁĄCZ / DOKUJ",
        "H55: SKOK / DRUGI SKOK",
        "H55: INTERAKCJA",
        "H55: TRYB CHODZENIA",
        "H55: WYJŚCIE Z CHODZENIA",
        "ATLAS: WEJŚCIE DO HANGARU",
        "OTWÓRZ DEV",
        "ZAPIS GRY",
        "WCZYTAJ GRĘ",
        "ATLAS: WZNOSZENIE",
        "ATLAS: OPADANIE",
        "OSŁONY / AKTYWUJ TARCZĘ",
        "ATLAS: CENTRUJ KAMERĘ",
        "ATLAS: POCHYL W GÓRĘ",
        "ATLAS: POCHYL W DÓŁ",
        "ATLAS: TRYB MYSZY",
        "DRZEWKO TALENTÓW",
        "USTAWIENIA",
        "H55: TRYB FOTO",
        "POŚWIATA / GLOW",
        "PEŁNY EKRAN",
        "DŹWIĘK WŁ./WYŁ.",
        "POMIAR FPS",
        "PAD: OBRÓT KAMERY LEWO/PRAWO",
        "PAD: OBRÓT KAMERY GÓRA/DÓŁ",
        "DOPALACZ / PRZYSPIESZENIE",
        "KOOPERACJA: W LEWO",
        "KOOPERACJA: W PRAWO",
        "KOOPERACJA: DO PRZODU",
        "KOOPERACJA: DO TYŁU",
        "KOOPERACJA: STRZAŁ",
        "KOOPERACJA: DOPALACZ",
        "KOOPERACJA: BOMBA",
        "KOOPERACJA: ZMIEŃ BROŃ",
        "CELOWANIE: W LEWO",
        "CELOWANIE: W PRAWO",
        "CELOWANIE: W GÓRĘ",
        "CELOWANIE: W DÓŁ",
        "KOOPERACJA: CEL W LEWO",
        "KOOPERACJA: CEL W PRAWO",
        "KOOPERACJA: CEL W GÓRĘ",
        "KOOPERACJA: CEL W DÓŁ",
        "H55: WIDOK PIERWSZOOSOBOWY",
        "H55: WIDOK TRZECIOOSOBOWY",
        "MUZYKA: WŁĄCZ / WYŁĄCZ",
        "MUZYKA: GŁOŚNIEJ",
        "MUZYKA: CISZEJ",
        "KOOPERACJA: STRAFE W LEWO",
        "KOOPERACJA: STRAFE W PRAWO",
        "H55: BIEG / SPRINT"
    ]
    static let defaultKeys:[Int]=[
        65,68,87,83,81,69,32,82,9,80,74,32,69,117,27,72,113,116,120,33,34,86,67,73,75,9,84,79,70,71,122,77,114,0,0,70,37,39,38,40,163,96,161,165,74,76,73,75,100,102,104,98,49,50,78,187,189,188,190,160
    ]
    static let defaultPad:[String]=[
        "A0-;B13",        "A0+;B14",        "A1-;B11;B2",        "A1+;B12;A4+",        "B9;A2-",        "B10;A2+",        "B0;A5+",        "B3",        "B8",        "B6",        "B9+B3",        "B2",        "B0",        "B8",        "B1",        "B0",        "B7",        "",        "",        "B10",        "B9",        "B7",        "B7",        "",        "",        "B8",        "B3",        "B4",        "",        "",        "",        "",        "",        "A2+",        "A3+",        "B7",        "",        "",        "",        "",        "",        "",        "",        "",        "",        "",        "",        "",        "",        "",        "",        "",        "",        "",        "",        "",        "",        "",        "",        "B9"
    ]
    static let extraLabels=[
        "MARTWA STREFA DRĄŻKÓW",
        "LEWY DRĄŻEK: GÓRA / DÓŁ (PLANETA)",
        "MYSZ W ATLASIE",
        "CZUŁOŚĆ MYSZY W ATLASIE",
        "MYSZ: GÓRA / DÓŁ (ATLAS)"
    ]

    enum Context:String,Codable {case combat,hangar,other}
    /// A registered binding is not automatically a functional game action.
    /// CARBONIS 01 implements the listed combat actions; H55 has the two
    /// explicit walking interactions. Other PC actions require their own
    /// actual engine implementation and are NEVER dispatched as no-ops.
    static func context(for action:Int)->Context {
        switch action {
        case 0...7,9,21,33,34,35,44...47:return .combat
        case 11,12,59:return .hangar
        default:return .other
        }
    }
    static func label(_ index:Int)->String {
        guard (0..<rowCount).contains(index) else{return "NIEZNANA AKCJA"}
        return index<actionCount ? labels[index] : extraLabels[index-actionCount]
    }
    static func keyName(_ code:Int)->String {
        if code==0{return "BRAK"}
        if (96...105).contains(code){return "NUM \(code-96)"}
        if (160...165).contains(code) {
            return ["L SHIFT","R SHIFT","L CTRL","R CTRL","L ALT","R ALT"][code-160]
        }
        switch code {
        case 32:return "SPACJA"
        case 187,107:return "+"
        case 189,109:return "-"
        case 188:return ","
        case 190:return "."
        case 9:return "TAB"
        case 13:return "ENTER"
        case 27:return "ESC"
        case 37...40:return ["←","↑","→","↓"][code-37]
        case 112...123:return "F\(code-111)"
        default:
            if (33...126).contains(code),
               let scalar=UnicodeScalar(code) {return String(Character(scalar))}
            return "KLAWISZ \(code)"
        }
    }

    struct Profile:Codable,Equatable {
        static let storageKey="ASTEROIDY.iOS.PC586.Controls"
        var version=2
        var keys=SourceControls586.defaultKeys
        var pad=SourceControls586.defaultPad
        var deadZone=30
        var invertOrbitPitch=false
        var orbitMouse=false
        var mouseSensitivity=100
        var invertMouse=false

        init() {}

        private enum CodingKeys:String,CodingKey {
            case version,keys,pad,deadZone,invertOrbitPitch
            case orbitMouse,mouseSensitivity,invertMouse
        }

        /// Upgrade existing iOS JSON profiles without discarding genuine
        /// user bindings when early builds saved only 10–59 actions or
        /// omitted settings that PC586 added later.
        init(from decoder:Decoder) throws {
            let c=try decoder.container(keyedBy:CodingKeys.self)
            version=try c.decodeIfPresent(Int.self,forKey:.version) ?? 1
            keys=try c.decodeIfPresent([Int].self,forKey:.keys)
                ?? SourceControls586.defaultKeys
            pad=try c.decodeIfPresent([String].self,forKey:.pad)
                ?? SourceControls586.defaultPad
            deadZone=try c.decodeIfPresent(Int.self,forKey:.deadZone) ?? 30
            invertOrbitPitch=try c.decodeIfPresent(Bool.self,
                forKey:.invertOrbitPitch) ?? false
            orbitMouse=try c.decodeIfPresent(Bool.self,
                forKey:.orbitMouse) ?? false
            mouseSensitivity=try c.decodeIfPresent(Int.self,
                forKey:.mouseSensitivity) ?? 100
            invertMouse=try c.decodeIfPresent(Bool.self,
                forKey:.invertMouse) ?? false
            if version<1 || version>2 {
                throw DecodingError.dataCorruptedError(
                    forKey:.version,in:c,
                    debugDescription:"Unsupported PC586 controls profile version")
            }
            normalize()
        }

        mutating func normalize() {
            // Preserve existing action IDs exactly. Legacy 10-action
            // profiles receive ONLY the missing defaults (indices 10..59).
            guard (10...SourceControls586.actionCount).contains(keys.count),
                  (10...SourceControls586.actionCount).contains(pad.count)
            else {
                self=Self()
                return
            }
            if keys.count<SourceControls586.actionCount {
                keys.append(contentsOf:SourceControls586.defaultKeys[keys.count...])
            }
            if pad.count<SourceControls586.actionCount {
                pad.append(contentsOf:SourceControls586.defaultPad[pad.count...])
            }
            for i in keys.indices {keys[i]=max(0,min(65535,keys[i]))}
            for i in pad.indices where !SourceControls586.validPad(pad[i]) {
                pad[i]=SourceControls586.defaultPad[i]
            }
            deadZone=max(10,min(60,deadZone))
            mouseSensitivity=max(25,min(200,mouseSensitivity))
            version=2
        }

        static func load(_ store:UserDefaults = .standard)->Self {
            guard let data=store.data(forKey:storageKey),
                  var profile=try? JSONDecoder().decode(Self.self,from:data)
            else{return Self()}
            profile.normalize()
            return profile
        }
        func save(_ store:UserDefaults = .standard) {
            var value=self
            value.normalize()
            if let data=try? JSONEncoder().encode(value) {
                store.set(data,forKey:Self.storageKey)
            }
        }
        /// Original PC v389 controls-v29.txt, v1 ten actions and v2
        /// count-prefixed action rows. Invalid imports leave settings
        /// untouched; callers must not partially mutate a live profile.
        static func importPCText(_ raw:String)->Self? {
            var lines=raw.replacingOccurrences(of:"\r\n",with:"\n")
                .replacingOccurrences(of:"\r",with:"\n")
                .components(separatedBy:"\n")
            if lines.last=="" {lines.removeLast()}
            guard !lines.isEmpty else{return nil}
            lines[0]=lines[0].replacingOccurrences(of:"\u{FEFF}",with:"")
            var output=Self()
            if lines[0]=="ASTEROIDY_CONTROLS_1" {
                guard (lines.count==12 || lines.count==13),
                      let deadZone=Int(lines[1]) else{return nil}
                for i in 0..<10 {
                    let parts=lines[2+i].components(separatedBy:"|")
                    guard parts.count==2,let key=Int(parts[0]),
                          (0...65535).contains(key),validPad(parts[1])
                    else{return nil}
                    output.keys[i]=key
                    output.pad[i]=parts[1]
                }
                output.deadZone=deadZone
                output.invertOrbitPitch=lines.count==13 && lines[12]=="1"
            } else if lines[0]=="ASTEROIDY_CONTROLS_2" {
                guard lines.count>=4,let deadZone=Int(lines[1]),
                      ["0","1"].contains(lines[2]),
                      let count=Int(lines[3]),(10...60).contains(count),
                      lines.count==count+4 else{return nil}
                for i in 0..<count {
                    let parts=lines[4+i].components(separatedBy:"|")
                    guard parts.count==2,let key=Int(parts[0]),
                          (0...65535).contains(key),validPad(parts[1])
                    else{return nil}
                    output.keys[i]=key
                    output.pad[i]=parts[1]
                }
                output.deadZone=deadZone
                output.invertOrbitPitch=lines[2]=="1"
            } else {return nil}
            output.normalize()
            return output
        }

        /// Source Windows/src/MouseFlight67.cs stores the last three
        /// input options in a separate controls-v29.txt.flight67 file.
        /// Importing the main controls-v29.txt alone cannot recover them.
        static func importFlight67Text(_ raw:String,
                                       into input:Self)->Self? {
            var lines=raw.replacingOccurrences(of:"\r\n",with:"\n")
                .replacingOccurrences(of:"\r",with:"\n")
                .components(separatedBy:"\n")
            if lines.last=="" {lines.removeLast()}
            guard lines.count==4 else{return nil}
            lines[0]=lines[0].replacingOccurrences(of:"\u{FEFF}",with:"")
            guard lines[0]=="ASTEROIDY_FLIGHT_67",
                  (lines[1]=="0" || lines[1]=="1"),
                  let sensitivity=Int(lines[2]),
                  (25...200).contains(sensitivity),
                  (lines[3]=="0" || lines[3]=="1")
            else{return nil}
            var result=input
            result.orbitMouse=lines[1]=="1"
            result.mouseSensitivity=sensitivity
            result.invertMouse=lines[3]=="1"
            result.normalize()
            return result
        }

        func exportPCFlight67Text()->String {
            var safe=self
            safe.normalize()
            return ["ASTEROIDY_FLIGHT_67",
                    safe.orbitMouse ? "1":"0",
                    String(safe.mouseSensitivity),
                    safe.invertMouse ? "1":"0"]
                .joined(separator:"\n")+"\n"
        }

        func exportPCText()->String {
            var safe=self
            safe.normalize()
            let head=["ASTEROIDY_CONTROLS_2",String(safe.deadZone),
                      safe.invertOrbitPitch ? "1":"0","60"]
            return (head+zip(safe.keys,safe.pad).map{
                String($0.0)+"|"+$0.1
            }).joined(separator:"\n")+"\n"
        }
    }

    static func validPad(_ raw:String)->Bool {
        if raw.isEmpty{return true}
        for binding in raw.split(separator:";",omittingEmptySubsequences:false) {
            if binding.isEmpty{return false}
            let atoms=String(binding).split(separator:"+",omittingEmptySubsequences:false)
            if binding.first=="A" {
                // A2+ is an axis with a sign, NOT a button combination.
                let text=String(binding)
                guard let sign=text.last,sign=="+" || sign=="-",
                      let n=Int(text.dropFirst().dropLast()),(0...7).contains(n)
                else{return false}
            } else if atoms.count>1 {
                // B9+B3 is a combination; every part must be a button.
                guard atoms.count>=2 && atoms.allSatisfy({
                    $0.first=="B" && Int($0.dropFirst()).map{
                        (0...31).contains($0)
                    } == true
                }) else{return false}
            } else if binding.first=="B" {
                guard let n=Int(binding.dropFirst()),(0...31).contains(n)
                else{return false}
            } else {return false}
        }
        return true
    }

    struct Snapshot {
        var keys:Set<Int>=[]
        var buttons:Set<Int>=[]
        /// PC SDL axes A0..A5: leftX,leftY,rightX,rightY,LT,RT.
        var axes:[Float]=Array(repeating:0,count:6)
        init(keys:Set<Int>=[],buttons:Set<Int>=[],
             axes:[Float]=Array(repeating:0,count:6)) {
            self.keys=keys;self.buttons=buttons;self.axes=axes
        }
        func axis(_ index:Int)->Float {
            index<axes.count && index>=0 ? max(-1,min(1,axes[index])):0
        }
        func held(_ action:Int,profile:Profile)->Bool {
            guard (0..<actionCount).contains(action) else{return false}
            let key=profile.keys[action]
            if key != 0 && keys.contains(key){return true}
            // Original C# KeyHeld includes WASD => arrows fallbacks.
            switch action {
            case 0 where key==65 && keys.contains(37):return true
            case 1 where key==68 && keys.contains(39):return true
            case 2 where key==87 && keys.contains(38):return true
            case 3 where key==83 && keys.contains(40):return true
            default:break
            }
            let threshold=Float(profile.deadZone)/100
            for binding in profile.pad[action].split(separator:";") {
                let token=String(binding)
                if token.contains("+B") {
                    let buttonIDs=token.split(separator:"+").compactMap{
                        $0.first=="B" ? Int($0.dropFirst()):nil
                    }
                    if buttonIDs.count==token.split(separator:"+").count &&
                       buttonIDs.allSatisfy({buttons.contains($0)}) {return true}
                } else if token.first=="B",
                          let number=Int(token.dropFirst()),
                          buttons.contains(number) {return true}
                else if token.first=="A",let sign=token.last,
                        let n=Int(token.dropFirst().dropLast()) {
                    let value=axis(n)
                    let limit=n>=4 ? Float(6000)/32767 : threshold
                    if sign=="+" && value>limit ||
                       sign=="-" && value < -limit {return true}
                }
            }
            return false
        }
        /// Resolve the analog axis selected in the ORIGINAL PC action
        /// mapping. Positive/negative axis values both remain continuous;
        /// the '+'/'-' direction on the binding determines orientation.
        /// Rebinding 33/34 must affect gameplay, not only the settings UI.
        func boundAnalog(_ action:Int,profile:Profile)->Float {
            guard (0..<SourceControls586.actionCount).contains(action)
            else{return 0}
            for binding in profile.pad[action].split(separator:";") {
                let text=String(binding)
                guard text.first=="A",let sign=text.last,
                      (sign=="+" || sign=="-"),
                      let n=Int(text.dropFirst().dropLast()),
                      (0..<axes.count).contains(n) else{continue}
                // Keep both signed components. The original 30% deadzone
                // applies to the vector MAGNITUDE, not each axis alone:
                // 0.25/0.25 must still produce a diagonal camera motion.
                return axis(n)*(sign=="-" ? -1:1)
            }
            return held(action,profile:profile) ? 1:0
        }

        /// Only meaningful actions are routed. Keep PC IDs stable even
        /// if later sectors and the missing PC co-op are not implemented.
        func combat(profile:Profile)->Combat {
            let a:(Int)->Bool={held($0,profile:profile)}
            let horizontal = (a(1) ? 1 : 0) + (a(5) ? 1 : 0) - (a(0) ? 1 : 0) - (a(4) ? 1 : 0)
            let vertical = (a(3) ? 1 : 0) - (a(2) ? 1 : 0)
            let move=Vector2(x:Float(horizontal),y:Float(vertical))
            let keyboardAim=Vector2(
                x:Float((a(45) ? 1:0)-(a(44) ? 1:0)),
                y:Float((a(47) ? 1:0)-(a(46) ? 1:0)))
            // iOS playable CARBONIS orbit: the right controller stick
            // also provides real aim, matching touch's right drag.
            // Deadzone is the original PC pad option (action row 60).
            let stick=Vector2(x:boundAnalog(33,profile:profile),
                              y:boundAnalog(34,profile:profile))
            let useStick=sqrt(stick.x*stick.x+stick.y*stick.y)
                > Float(profile.deadZone)/100
            let aim=keyboardAim.hasInput ? keyboardAim :
                (useStick ? stick:Vector2(x:0,y:0))
            return Combat(move:move.clamped(),aim:aim.clamped(),
                          shooting:a(6),shield:a(21),
                          bomb:a(7),boost:a(35),pause:a(9))
        }
    }

    struct Vector2:Equatable {
        var x:Float
        var y:Float
        func clamped()->Self {
            let magnitude=sqrt(x*x+y*y)
            return magnitude>1 ? Self(x:x/magnitude,y:y/magnitude):self
        }
        var hasInput:Bool {x != 0 || y != 0}
    }
    struct Combat {
        let move:Vector2
        let aim:Vector2
        let shooting:Bool
        let shield:Bool
        let bomb:Bool
        let boost:Bool
        let pause:Bool
    }

    /// Context-aware conflict detection; duplicates from original PC are
    /// legitimate between H55 / atlas / combat and must NOT be deleted.
    static func conflictingActions(_ action:Int,profile:Profile)->[Int] {
        guard (0..<actionCount).contains(action),
              context(for:action) != .other else{return []}
        let thisContext=context(for:action)
        let key=profile.keys[action]
        let pad=profile.pad[action]
        return (0..<actionCount).filter{
            $0 != action && context(for:$0)==thisContext &&
            ((key != 0 && profile.keys[$0]==key) ||
             (!pad.isEmpty && profile.pad[$0]==pad))
        }
    }
}
