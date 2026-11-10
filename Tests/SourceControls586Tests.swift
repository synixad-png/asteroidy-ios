import Foundation

@main enum SourceControls586Tests {
    static func check(_ condition:@autoclosure ()->Bool,_ label:String) {
        precondition(condition(),"FAILED: "+label)
    }
    static func main() {
        let c=SourceControls586.self
        let initial=c.Profile()
        check(c.labels.count==60 && c.defaultKeys.count==60 &&
              c.defaultPad.count==60 && c.extraLabels.count==5,
              "source 60 action IDs, exactly five extra controls")
        check(initial.keys.count==60 && initial.pad.count==60,
              "all original IDs preserved")
        check(initial.keys[7]==82 && initial.pad[7]=="B3","Bomb R/Y")
        check(initial.keys[21]==86 && initial.pad[21]=="B7","Shield V/B7")
        check(initial.keys[35]==70 && initial.pad[35]=="B7","Boost F/B7")
        check(initial.keys[11]==32 && initial.pad[11]=="B2","H55 jump")
        check(initial.keys[12]==69 && initial.pad[12]=="B0","H55 talk")
        check(initial.keys[33]==0 && initial.pad[33]=="A2+","pad camera axis 33")
        check(initial.keys[34]==0 && initial.pad[34]=="A3+","pad camera axis 34")
        check(initial.pad[10]=="B9+B3","original drill combo")
        check(initial.deadZone==30 && initial.mouseSensitivity==100,
              "original deadzone and mouse sensitivity")
        check(c.defaultPad.allSatisfy(c.validPad),
              "all 60 original PC pad tokens accepted (not modified)")
        check(!c.validPad("A2++") && !c.validPad("B9+X") &&
              !c.validPad("B55") && !c.validPad("A9-"),
              "reject malformed and out-of-bound gamepad assignments")
        let utf8=initial.exportPCText()
        let imported=c.Profile.importPCText(utf8)
        check(imported == initial,"PC v2 controls 60 action roundtrip")
        var pcV1Lines=["ASTEROIDY_CONTROLS_1","42"]
        pcV1Lines.append(contentsOf:(0..<10).map{
            String(initial.keys[$0])+"|"+initial.pad[$0]
        })
        pcV1Lines.append("1")
        let pcV1=pcV1Lines.joined(separator:"\r\n")
        let legacy=c.Profile.importPCText(pcV1)
        check(legacy != nil && legacy!.keys==initial.keys &&
              legacy!.pad==initial.pad && legacy!.deadZone==42 &&
              legacy!.invertOrbitPitch,
              "original v1 ten actions migrate keeping remaining 50 defaults")
        var cutLines=["ASTEROIDY_CONTROLS_2","30","0","10"]
        cutLines.append(contentsOf:(0..<10).map{
            String(initial.keys[$0])+"|"+initial.pad[$0]
        })
        let cut=cutLines.joined(separator:"\n")
        let ten=c.Profile.importPCText(cut)
        check(ten != nil && ten!.keys==initial.keys && ten!.pad==initial.pad,
              "source v2 with ten rows does not break next 50 indices")
        check(c.Profile.importPCText(utf8.replacingOccurrences(
              of:"82|B3",with:"-100|B3")) == nil,
              "invalid imported profile is rejected atomically")
        var pcMouse=initial
        pcMouse.orbitMouse=true
        pcMouse.mouseSensitivity=175
        pcMouse.invertMouse=true
        let companion=pcMouse.exportPCFlight67Text()
        let reconstructed=c.Profile.importFlight67Text(companion,into:initial)
        check(reconstructed == pcMouse,
              "original PC MouseFlight67 companion migrates all 3 mouse fields")
        check(c.Profile.importFlight67Text(
            "ASTEROIDY_FLIGHT_67\n1\n999\n0\n",into:initial)==nil,
              "unsafe mouse sensitivity is rejected rather than clamped silently")
        let isolated="pc586-controls-tests-"+UUID().uuidString
        guard let store=UserDefaults(suiteName:isolated) else {
            fatalError("Missing isolated preferences")
        }
        defer {store.removePersistentDomain(forName:isolated)}
        var modified=initial
        modified.keys[7]=66
        modified.pad[21]="B11"
        modified.deadZone=200
        modified.mouseSensitivity=0
        modified.save(store)
        let restored=c.Profile.load(store)
        check(restored.keys[7]==66 && restored.pad[21]=="B11",
              "keyboard and controller rebinding persists")
        check(restored.deadZone==60 && restored.mouseSensitivity==25,
              "original PC input setting constraints apply on load")
        store.set(Data("NOT_JSON".utf8),forKey:c.Profile.storageKey)
        check(c.Profile.load(store)==initial,
              "corrupted settings fall back to source defaults")
        let bomb=c.Snapshot(keys:[82])
        check(bomb.held(7,profile:initial) &&
              !bomb.held(21,profile:initial),
              "keyboard R is bomb not active shield")
        let shield=c.Snapshot(keys:[86])
        check(shield.combat(profile:initial).shield,
              "keyboard V is actual held shield")
        let controller=c.Snapshot(buttons:[3])
        check(controller.held(7,profile:initial) &&
              !controller.held(10,profile:initial),
              "single B3 is bomb, not B9+B3 docking")
        let combo=c.Snapshot(buttons:[3,9])
        check(combo.held(10,profile:initial),
              "PC B9+B3 combo only when both are held")
        let stick=c.Snapshot(axes:[-0.8,0,0,0,0,0])
        check(stick.held(0,profile:initial),
              "original analog left stick routes left")
        let dead=c.Snapshot(axes:[-0.1,0,0,0,0,0])
        check(!dead.held(0,profile:initial),
              "30% deadzone blocks stick drift")
        let trigger=c.Snapshot(axes:[0,0,0,0,0,0.9])
        check(trigger.held(6,profile:initial),
              "right analog trigger A5+ fires at source threshold")
        let movement=c.Snapshot(keys:[87,68]).combat(profile:initial).move
        check(movement.x>0.5 && movement.y < -0.5,
              "W/D diagonal maps through one normalized gameplay vector")
        let rightStickAim=c.Snapshot(axes:[0,0,0.80,-0.55,0,0])
            .combat(profile:initial).aim
        check(rightStickAim.x>0.65 && rightStickAim.y < -0.45,
              "existing right-stick controls actual CARBONIS iOS aim")
        // Actual action 33/34 rebinding must change the aim axis.
        var remappedStick=initial
        remappedStick.pad[33]="A0+"
        remappedStick.pad[34]="A1-"
        let changedAim=c.Snapshot(axes:[0.75,0.55,0.20,0.30,0,0])
            .combat(profile:remappedStick).aim
        check(abs(changedAim.x-0.75)<0.0001 &&
              abs(changedAim.y+0.55)<0.0001,
              "remapped original PC axes 33/34 actually drive camera aim")
        let previousAim=c.Snapshot(axes:[0.75,0.55,0.20,0.30,0,0])
            .combat(profile:initial).aim
        check(previousAim.x==0 && abs(previousAim.y-0.30)<0.0001,
              "original A2/A3 are ignored after user mapping changed")
        check(c.context(for:33)==(.combat) &&
              c.context(for:34)==(.combat),
              "menu marks genuinely remappable controller aim as playable")
        let noDrift=c.Snapshot(axes:[0,0,0.05,0.04,0,0])
            .combat(profile:initial).aim
        check(noDrift.x==0 && noDrift.y==0,
              "original PC deadzone blocks analog aiming noise")
        let unported=c.Snapshot(keys:[163])
        check(c.context(for:40)==(.other) &&
              c.context(for:7)==(.combat) &&
              c.context(for:12)==(.hangar) &&
              !unported.combat(profile:initial).shooting,
              "co-op key cannot silently fire solo weapon")
        var conflict=initial
        conflict.keys[35]=conflict.keys[21]
        check(c.conflictingActions(35,profile:conflict).contains(21),
              "live conflicting same-context active actions visible")
        check(!c.conflictingActions(11,profile:initial).contains(6),
              "cross-context H55 jump vs combat fire is permitted")
        print("PASS PC586: 60 exact source controls, 5 extras, keyboard/pad including combos+axes, game actions, conflict separation, v1/v2 migration and persistence")
    }
}
