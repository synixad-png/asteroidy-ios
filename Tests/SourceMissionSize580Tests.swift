import Foundation

@main struct SourceMissionSize580Tests {
    static func main() {
        func check(_ ok:Bool,_ message:String) {precondition(ok,message)}
        let source=SourceMissionSize580()
        check(source.enemyPercent==77 && source.rockPercent==78,"v580 source defaults")
        check(source.enemyFactor>0.7699 && source.enemyFactor<0.7701,"enemy factor")
        check(source.rockFactor>0.7799 && source.rockFactor<0.7801,"rock factor")
        var a=source
        a.setEnemy(160);a.setRock(20)
        check(a.enemyPercent==150 && a.rockPercent==40,"independent v580 limits")
        a.setEnemy(30);a.setRock(150)
        check(a.enemyPercent==30 && a.rockPercent==150,"independent source bounds")
        let name="synixad.missionsize580.\(UUID().uuidString)"
        let defaults=UserDefaults(suiteName:name)!
        defer{defaults.removePersistentDomain(forName:name)}
        a.save(defaults)
        check(SourceMissionSize580.load(defaults)==a,"separate persisted sliders")
        var corrupted=a
        corrupted.enemyPercent = -100;corrupted.rockPercent = 2000
        corrupted.save(defaults)
        let safe=SourceMissionSize580.load(defaults)
        check(safe.enemyPercent==30 && safe.rockPercent==150,"corrupt values clamped")
        check(SourceMissionSize580.load(UserDefaults(suiteName:"synixad.unused580.\(UUID().uuidString)")!)==source,"absent saved settings keep source defaults")
        print("PASS v580 independent enemy and asteroid visual size settings")
    }
}
