import Foundation

@main struct H55NpcDetour580Tests {
    typealias P=H55NpcDetour580.Point
    static func main() {
        func check(_ condition:Bool,_ message:String) {
            precondition(condition,message)
        }
        let open:(Float,Float)->Bool={_,_ in true}
        let start=P(x:0,z:0),goal=P(x:3,z:0),player=P(x:1.5,z:0)
        check(!H55NpcDetour580.segmentClear(from:start,to:goal,player:player,
                                           walkable:open),
              "direct segment must not intersect player 0.97m avoidance buffer")
        guard let route=H55NpcDetour580.plan(start:start,join:goal,
                                             player:player,walkable:open) else {
            preconditionFailure("real PC v532 A* must avoid stationary player")
        }
        check(route.count>1 && route.count<=32,
              "valid nontrivial source route with <=32 checked corners")
        var previous=start
        for next in route {
            check(H55NpcDetour580.segmentClear(from:previous,to:next,
                                               player:player,walkable:open),
                  "all smoothed segments remain clear of player")
            previous=next
        }
        check(hypot(previous.x-goal.x,previous.z-goal.z)<0.001,
              "route must rejoin genuine goal")
        let wall:(Float,Float)->Bool={x,z in
            !(x>1.0 && x<2.0 && abs(z)<4.0)
        }
        check(H55NpcDetour580.plan(start:start,join:goal,
                                   player:P(x:100,z:100),walkable:wall)==nil,
              "full collision wall cannot be bypassed by smoothing")
        let tooFar=H55NpcDetour580.plan(
            start:start,join:P(x:100,z:100),player:P(x:200,z:200),
            walkable:open)
        check(tooFar==nil,"PC source 3000-cell limit blocks excessive A*")
        let originInside=P(x:1.65,z:0)
        let away=P(x:3.0,z:0)
        check(H55NpcDetour580.segmentClear(from:originInside,to:away,
                                           player:player,walkable:open),
              "PC source allows only outward escape if already inside buffer")
        let sourceX:[Float]=[3,3.5,4,4.5,5,5.5,6,6.5,7,7.5,8,8.5]
        let sourceZ:[Float]=Array(repeating:Float(0),count:sourceX.count)
        let by=H55NpcDetour580.bypass(
            start:start,player:player,goal:goal,goalIndex:0,
            workshopIndex:11,routeX:sourceX,routeZ:sourceZ,walkable:open)
        check(by != nil,"source bypass may rejoin approved corridor")
        print("PASS PC v580 NPC v532 A* stationary player, no wall tunneling, segment smoothing, grid cap and route rejoin")
    }
}
