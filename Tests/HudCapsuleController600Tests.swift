import Foundation

@main enum HudCapsuleController600Tests {
    static func check(_ condition: @autoclosure () -> Bool, _ description: String) {
        precondition(condition(), description)
    }
    static func main() {
        var controller = HudCapsuleController600()
        controller.advance(hull: 1, armor: 0.5, shield: 0, seconds: 1)
        check(controller.snapshot.level(0) == 1, "initial full hull")
        check(controller.snapshot.level(1) == 0.5, "initial half armor")
        check(controller.snapshot.level(2) == 0, "initial empty shield")
        controller.advance(hull: 0, armor: 0.5, shield: 0,
                           seconds: 1.016, hullPulse: 1)
        check(controller.snapshot.level(0) > 0 && controller.snapshot.level(0) < 1,
              "loss interpolates rather than snapping")
        check(controller.snapshot.flash(0) == 1, "damage pulse lights hull only")
        check(controller.snapshot.flash(1) == 0, "armor flash is independent")
        let previous = controller.snapshot.level(0)
        controller.advance(hull: 1, armor: 0.5, shield: 0, seconds: 1.032)
        check(controller.snapshot.level(0) > previous, "recovery interpolates")
        check(controller.snapshot.flash(0) < 1, "flash decays")
        controller.advance(hull: -2, armor: 8, shield: .nan, seconds: 3)
        check(controller.snapshot.levels == [0, 1, 0], "invalid levels clamp on discontinuity")
        check(controller.snapshot.flashes == [0, 0, 0], "discontinuity clears flashes")
        print("PASS HUD capsule v600 smoothing, flash, clamp and timestamp reset")
    }
}
