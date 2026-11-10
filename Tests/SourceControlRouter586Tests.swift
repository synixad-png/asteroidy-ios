import Foundation

@main enum SourceControlRouter586Tests {
    static func check(_ value:@autoclosure ()->Bool,_ message:String) {
        precondition(value(),"FAILED: "+message)
    }
    static func main() {
        let profile=SourceControls586.Profile()
        var router=SourceControlRouter586()

        let bomb=SourceControls586.Snapshot(keys:[82])
        var tick=router.read(bomb,profile:profile)
        check(tick.bombPressed && tick.continuous.bomb,
              "first R key-down consumes exactly one bomb")
        tick=router.read(bomb,profile:profile)
        check(!tick.bombPressed,
              "held R does not auto-spend 60 bombs/second")
        _=router.read(.init(),profile:profile)
        tick=router.read(bomb,profile:profile)
        check(tick.bombPressed,"second distinct R press is a new bomb")

        let boost=SourceControls586.Snapshot(keys:[70])
        tick=router.read(boost,profile:profile)
        check(tick.boostPressed && !tick.continuous.shield,
              "F triggers boost not V hold")
        tick=router.read(boost,profile:profile)
        check(!tick.boostPressed,"held F never repeats boost consumption")

        let shield=SourceControls586.Snapshot(keys:[86])
        tick=router.read(shield,profile:profile)
        check(tick.continuous.shield && !tick.boostPressed,
              "V is continuously held active energy shield")
        tick=router.read(.init(),profile:profile)
        check(!tick.continuous.shield,
              "shield releases immediately with key-up")

        let pause=SourceControls586.Snapshot(keys:[80])
        tick=router.read(pause,profile:profile)
        check(tick.pausePressed,"first P pauses real mission")
        tick=router.read(pause,profile:profile)
        check(!tick.pausePressed,"P held must not repeatedly toggle pause")
        _=router.read(.init(),profile:profile)
        tick=router.read(pause,profile:profile)
        check(tick.pausePressed,"subsequent P press can resume mission")

        var custom=profile
        custom.keys[7]=66
        custom.keys[21]=89
        custom.keys[35]=72
        router.reset()
        tick=router.read(.init(keys:[66,89,72]),profile:custom)
        check(tick.bombPressed && tick.boostPressed &&
              tick.continuous.shield,
              "all three configured keys, not hardcoded PC defaults")

        var hangar=SourceControlRouter586()
        let h55=SourceControls586.Snapshot(keys:[87,69,32,160])
        var action=hangar.readHangar(h55,profile:profile)
        check(action.moveForward==1 && action.moveRight==0,
              "W walks forward in original H55 collision solver")
        check(action.jumpPressed && action.interactPressed && action.sprintHeld,
              "Space E Shift route to real H55 jump/interact/sprint")
        action=hangar.readHangar(h55,profile:profile)
        check(!action.jumpPressed && !action.interactPressed && action.sprintHeld,
              "H55 jump/talk are edge actions; sprint remains held")
        // A genuine device disconnect or scene teardown clears H55 edges.
        // Never call reset on pause: a held key must not toggle twice.
        hangar.reset()
        action=hangar.readHangar(h55,profile:profile)
        check(action.jumpPressed && action.interactPressed,
              "H55 jump/interact edges rearm after genuine device reset")
        action=hangar.readHangar(h55,profile:profile)
        check(!action.jumpPressed && !action.interactPressed,
              "H55 fires once per held press even after reset")
        let look=SourceControls586.Snapshot(axes:[0,0,0.7,-0.4,0,0])
        action=hangar.readHangar(look,profile:profile)
        check(abs(action.lookX-0.7)<0.0001 && abs(action.lookY+0.4)<0.0001,
              "right stick drives real H55 look with original deadzone")
        var remappedH55=profile
        remappedH55.pad[33]="A0+"
        remappedH55.pad[34]="A1-"
        let changed=SourceControls586.Snapshot(
            axes:[0.7,0.8,0,0,0,0])
        let mappedLook=hangar.readHangar(changed,profile:remappedH55)
        check(abs(mappedLook.lookX-0.7)<0.0001 &&
              abs(mappedLook.lookY+0.8)<0.0001,
              "H55 real camera follows user-mapped axes 33/34, not fixed A2/A3")
        let oldLook=hangar.readHangar(changed,profile:profile)
        check(oldLook.lookX==0 && oldLook.lookY==0,
              "H55 default axes ignore unmapped left-stick look")
        let drift=SourceControls586.Snapshot(axes:[0,0,0.12,0.18,0,0])
        action=hangar.readHangar(drift,profile:profile)
        check(action.lookX==0 && action.lookY==0,
              "30% deadzone prevents camera drift")

        print("PASS PC586: one routed gameplay path, keyboard/pad button edges, remapping, shield hold, pause and real H55 controls")
    }
}
