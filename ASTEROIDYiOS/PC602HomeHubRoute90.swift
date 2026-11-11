import Foundation

/// Original Windows/src/Hub90.cs lines 34–68, PC v602.
/// Owns ONLY navigation between authored orbital world and the EXISTING
/// H55ScenePage580. It does not substitute a hangar mesh, reset campaign,
/// bypass collision checks or create a second H55 arrival simulator.
struct PC602HomeHubRoute90 {
    enum Location:Equatable {
        case orbit
        case menu
        case hangarFromOrbit
        case hangarFromMenu
    }
    enum Exit:Equatable {case orbit,menu}

    private(set) var location:Location
    private(set) var transitions:Int=0

    init(start:Location = .orbit) {
        // A fresh router can only begin outside the hangar; using menu or
        // orbit prevents an uninitialized mid-arrival NPC/spawn state.
        location = start == .menu ? .menu : .orbit
    }

    /// Hub90.EnterHub90. Only the REAL flight and the REAL original
    /// CanDock90 condition can authorize an H55 arrival.
    @discardableResult
    mutating func enterFromOrbit(_ flight:PC602HomeFlight291,
                                 context:PC602HomeFlight291.DockContext)->Bool {
        enterFromOrbit(distance:flight.dockDistance,
                       miningDetached:flight.equipment.miningDetached,
                       context:context)
    }

    /// Typed source gate, used by the flight entry and native regression tests.
    /// The UI integration must pass the CURRENT flight snapshot, never
    /// invent a near-wreck distance or skip the gate for the H55 view.
    @discardableResult
    mutating func enterFromOrbit(distance:Float,miningDetached:Bool,
                                 context:PC602HomeFlight291.DockContext)->Bool {
        guard location == .orbit,
              PC602HomeFlight291.canDock90(distance:distance,
                       miningDetached:miningDetached,context:context)
        else {return false}
        location = .hangarFromOrbit
        transitions+=1
        return true
    }

    /// Hub90.EnterMenuHangar397 is a showroom visit to the SAME GLB,
    /// but must never materialize an orbital flight or change progression.
    @discardableResult
    mutating func enterFromMenu(sceneBusy:Bool)->Bool {
        guard location == .menu,!sceneBusy else {return false}
        location = .hangarFromMenu
        transitions+=1
        return true
    }

    /// Hub90.ExitHub90. Exit destination comes ONLY from the way H55
    /// was entered. A menu showroom exit cannot resume/save orbital flight.
    mutating func exitHangar()->Exit? {
        switch location {
        case .hangarFromOrbit:
            location = .orbit
            transitions+=1
            return .orbit
        case .hangarFromMenu:
            location = .menu
            transitions+=1
            return .menu
        case .menu,.orbit:
            return nil
        }
    }

    /// The host must instantiate the ALREADY IMPLEMENTED source H55
    /// scene on entry and use its existing spawn/3.25s arrival clock.
    var mustDisplayPhysicalH55:Bool {
        location == .hangarFromOrbit || location == .hangarFromMenu
    }
    var returnsToOrbitOnExit:Bool {location == .hangarFromOrbit}
    var mayCaptureOrbitResumeOnExit:Bool {location == .hangarFromOrbit}
}
