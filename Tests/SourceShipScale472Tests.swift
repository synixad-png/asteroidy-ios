import Foundation

@main struct SourceShipScale472Tests {
    static func main() {
        var count=0
        func check(_ ok:Bool,_ message:String) {
            precondition(ok,message); count+=1
        }
        let initial=SourceShipScale472()
        check(initial.missionPercent==100 && initial.orbitPercent==100,
              "source default 100% both contexts")
        check(initial.missionFactor==1 && initial.orbitFactor==1,
              "100% multiplier equals one")
        check(SourceShipScale472.snapped(-50)==70 &&
              SourceShipScale472.snapped(900)==150,
              "source option range 70-150%")
        check(SourceShipScale472.snapped(102)==100 &&
              SourceShipScale472.snapped(103)==105,
              "source increments 5%")
        let name="synixad.ship472.tests.\(UUID().uuidString)"
        let defaults=UserDefaults(suiteName:name)!
        defer {defaults.removePersistentDomain(forName:name)}
        var v=initial
        v.setMission(140)
        v.setOrbit(85)
        v.save(defaults)
        check(defaults.integer(forKey:SourceShipScale472.revisionKey)==1,
              "first saved scale change triggers live Metal renderer")
        let copy=SourceShipScale472.load(defaults)
        check(copy==v,"two independent original options persisted")
        check(abs(copy.missionFactor-1.4)<0.00001 &&
              abs(copy.orbitFactor-0.85)<0.00001,
              "float ratios equal original percent /100")
        var malicious=copy
        malicious.missionPercent = -900
        malicious.orbitPercent = 9000
        malicious.save(defaults)
        check(defaults.integer(forKey:SourceShipScale472.revisionKey)==2,
              "new scale change invalidates live mission and H290 caches")
        let safe=SourceShipScale472.load(defaults)
        check(safe.missionPercent==70 && safe.orbitPercent==150,
              "untrusted persisted values clamp")
        print("PASS \(count) original v568 independent visual ship scale options")
    }
}
