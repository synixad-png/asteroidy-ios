import Foundation

@main struct H55Mechanic580Tests {
    static func main() {
        func check(_ ok:Bool,_ name:String) {precondition(ok,name)}
        check(H55Mechanic580.routeX.count==28 &&
              H55Mechanic580.routeZ.count==28,"28 source v580 waypoints")
        check(H55Mechanic580.workshopIndex==11,"verified workshop index")
        var npc=H55Mechanic580()
        check(npc.phase == .idle,"original mechanic initially idle")
        let free:(Float,Float)->Bool={_,_ in true}
        for _ in 0..<600 {
            npc.step(dt:1/60,playerX:0,playerZ:0,canWalk:free)
        }
        check(npc.phase == .idle && npc.distance==0,
              "approaching alone or elapsed time must never start NPC")
        npc.finishConversation()
        for _ in 0..<120 {
            npc.step(dt:1/60,playerX:npc.x+1,playerZ:npc.z,
                     canWalk:free)
        }
        check(npc.phase == .idle,"player must leave 2.5m proximity")
        var arrived=false
        var held=0
        for _ in 0..<8000 {
            npc.step(dt:1/60,playerX:-30,playerZ:-30,
                     canWalk:free)
            if npc.phase == .workshop {
                arrived=true
                held+=1
            }
            if npc.phase == .completed {break}
        }
        check(arrived && held>=300 && held<=305,
              "workshop requires exact five-second stop")
        check(npc.phase == .completed,"verified route returns to start")
        check(abs(npc.x-9.9248)<0.001 && abs(npc.z-12.155)<0.001,
              "return position from source GLB")
        check(npc.distance>85 && npc.distance<92,
              "source outbound and return path physically traversed")
        let lastDistance=npc.distance
        for _ in 0..<100 {
            npc.step(dt:1/60,playerX:-30,playerZ:-30,canWalk:free)
        }
        check(npc.distance==lastDistance,
              "no automatic patrol restart without conversation")
        var blocked=H55Mechanic580()
        blocked.finishConversation()
        for _ in 0..<100 {
            blocked.step(dt:1/60,playerX:-30,playerZ:-30,
                         canWalk:{_,_ in false})
        }
        check(blocked.distance==0 && blocked.phase == .blocked,
              "blocked GLB route does not penetrate geometry")
        print("PASS v580 NPC 28 route, conversation start, player departure, 5s workshop, return, no restart and collision stop")
    }
}
