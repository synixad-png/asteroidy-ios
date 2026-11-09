import Foundation

@main struct H55NpcDialogue580Tests {
    static func test(_ value:Bool,_ label:String){
        precondition(value,"H10 PC v580 source: "+label)
    }
    static func main() {
        var d=H55NpcDialogue580()
        test(!d.isOpen && d.finished==0,"initial 526 counter")
        test(H55NpcDialogue580.spokenLine=="WSZYSTKO W PORZADKU.",
             "exact only PC authored utterance, no invented options")
        test(H55NpcDialogue580.openNotice ==
             "MECHANIK: WSZYSTKO W PORZADKU. E / ENTER / ESC - ZAKONCZ ROZMOWE.",
             "exact original HubNotice90 while talking")
        test(H55NpcDialogue580.closeNotice=="MECHANIK: DO ZOBACZENIA.",
             "exact original closing notice")

        // PC 3.25s arrival and HubWalkStarted gates.
        test(d.interact(walking:false,playerX:9.9248,playerZ:12.155,
                        npcX:9.9248,npcZ:12.155) == .ignored,
             "conversation cannot start during dock arrival")
        test(!d.isOpen && d.finished==0,"failed open is side-effect free")
        test(d.interact(walking:true,playerX:0,playerZ:0,
                        npcX:9.9248,npcZ:12.155) == .ignored,
             "out-of-range tap never starts patrol")
        test(d.interact(walking:true,playerX:2.7,playerZ:0,
                        npcX:0,npcZ:0) == .opened,
             "PC source inclusive 2.7 meter radius")
        test(d.isOpen && d.finished==0 &&
             d.notice==H55NpcDialogue580.openNotice,
             "opening emits source text but does not arm patrol")
        // Source closing ignores distance; ESC/E can end dialog at any point.
        test(d.interact(walking:true,playerX:500,playerZ:500,
                        npcX:0,npcZ:0) == .closed,"close even if player moved")
        test(!d.isOpen && d.finished==1 &&
             d.notice==H55NpcDialogue580.closeNotice,
             "exactly one completion on close")
        test(d.interact(walking:true,playerX:2.701,playerZ:0,
                        npcX:0,npcZ:0) == .ignored,"strict outer limit")
        test(d.finished==1,"ignored taps never increment counter")
        test(d.interact(walking:true,playerX:0,playerZ:0,
                        npcX:0,npcZ:0) == .opened,"can reopen after close")
        test(d.interact(walking:true,playerX:0,playerZ:0,
                        npcX:0,npcZ:0) == .closed,"touch exit mirrors ESC/E")
        test(d.finished==2,"two complete conversations = counter two")
        test(!H55NpcDialogue580.inRange(playerX:.nan,playerZ:0,
                      npcX:0,npcZ:0),"reject NaN coordinates")
        d.reset()
        test(!d.isOpen && d.finished==0 && d.notice.isEmpty,
             "scene reopen resets PC v526 lifecycle")

        // H08 integration: only source completion arms patrol and actual
        // departure >2.5m activates; physics and H09 not modified.
        var mechanic=H55Mechanic580()
        mechanic.configureSpawn(x:9.9248,y:0.1095,z:12.155,foot:0.10)
        mechanic.calibrate(anatomicalHeading:-2.32326389)
        for _ in 0..<40 {
            mechanic.step(dt:1/60,playerX:2,playerZ:14,canWalk:{_,_ in true})
        }
        test(mechanic.phase == .idle,"proximity alone never starts the NPC")
        test(d.interact(walking:true,playerX:9.9248,playerZ:12.155,
                        npcX:mechanic.x,npcZ:mechanic.z) == .opened,
             "H10 dialogue opens at moving GLB root")
        for _ in 0..<40 {
            mechanic.step(dt:1/60,playerX:2,playerZ:14,canWalk:{_,_ in true})
        }
        test(mechanic.phase == .idle,"even far player cannot start patrol before closing")
        test(d.interact(walking:true,playerX:9.9248,playerZ:12.155,
                        npcX:mechanic.x,npcZ:mechanic.z) == .closed,
             "source dialogue close event")
        mechanic.finishConversation()
        for _ in 0..<40 {
            mechanic.step(dt:1/60,playerX:mechanic.x+0.7,
                          playerZ:mechanic.z,canWalk:{_,_ in true})
        }
        test(mechanic.phase == .idle,"NPC waits until player moves >2.5m")
        mechanic.step(dt:1/60,playerX:2,playerZ:14,canWalk:{_,_ in true})
        test(mechanic.phase == .walking,"NPC H08 starts only after completed dialog and departure")
        print("PASS H10: authentic PC526 single-line, arrival+2.7m gates, E/ESC/touch close, counters, reset, source H08 patrol trigger")
    }
}
