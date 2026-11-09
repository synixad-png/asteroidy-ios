import Foundation

/// Executable PC v580 HangarDrone451/H71DroneImports461 source regression.
/// A synthetic open physical world tests the original navigation decisions;
/// it does NOT claim parity on the user's inaccessible 126MB GLB or iOS GPU.
@main struct H55Drone580Tests {
    static var checks=0
    static func check(_ value:Bool,_ reason:String) {
        precondition(value,"H12 H71: "+reason)
        checks+=1
    }
    static func node(_ name:String,_ x:Float,_ y:Float,_ z:Float,
                     imported:Bool=true,origin:String="Hangar drone",
                     prefab:String="TEST",
                     children:[Int]=[0])->[String:Any] {
        var matrix:[Float]=[
            1,0,0,0,0,1,0,0,0,0,1,0,x,y,z,1
        ]
        // Swift inferred [Float] avoids losing exact glTF matrix position.
        matrix[15]=1
        return ["name":name,"matrix":matrix,
            "children":children,
            "extras":["hangarLabImported":imported,
                      "hangarLabImportName":origin,
                      "hangarLabPrefabId":prefab]]
    }
    static func main() throws {
        check(!H55H12FeatureFlags580.autonomousDronesEnabled,
              "H71 autonomous flight is explicitly postponed; no accidental runtime activation")
        let mechanic: [String:Any] = [
            "name":"HL_Import_Mechanik_XX",
            "matrix":[1,0,0,0,0,1,0,0,0,0,1,0,
                      10.194016,0.0,12.696275,1.0]
        ]
        let a=node("H71_DRONE_A",8.8,0.05,12.4,
                   prefab:"H71_IMPORTED_1")
        let b=node("H71_DRONE_B",11.0,0.05,12.5,
                   prefab:"H71_IMPORTED_2")
        let c=node("H71_DRONE_SPARE",15.9,0.05,10.9,
                   prefab:"H71_STATIC_3")
        let invalid=node("H71_FALSE",10.5,0.05,12.2,imported:false)
        let far=node("H71_REMOTE",34,0.05,7.0)
        let unrelated=node("H71_OTHER",10.4,0.05,12.2,origin:"machine")
        let selected=H55DroneImports580.select(from:[
            "nodes":[mechanic,a,b,c,invalid,far,unrelated]
        ])
        check(selected.count==2,"exactly two imported drone roots are dynamic")
        check(Set(selected.map{$0.name})==Set(["H71_DRONE_A","H71_DRONE_B"]),
              "nearest eligible roots, leave third and remote static")
        check(selected[0].prefab=="H71_IMPORTED_2" &&
              selected[1].prefab=="H71_IMPORTED_1",
              "source distance sort is stable, not prefab list order")
        check(H55DroneImports580.select(from:["nodes":[mechanic,a]]).isEmpty,
              "one eligible drone cannot trigger fabricated second drone")
        check(H55DroneImports580.select(from:[
            "nodes":[mechanic,a,node("H71_NO_CHILDREN",11,0.05,12.5,
                                         children:[])]
        ]).isEmpty,"without a real prefab hierarchy no drone actor")

        let open=H55DroneNavigation580(clearance:{_,_,_,_ in true})
        check(open.nodes.count==37*16*3+4,"PC fixed 2m lattice plus 4 dogleg nodes")
        check(open.openCount>100 && open.reachable>100,
              "open simulated hangar must have navigable components")
        check(H55DroneNavigation580.interior(10,12) &&
              H55DroneNavigation580.interior(25,7) &&
              H55DroneNavigation580.interior(42,7) &&
              !H55DroneNavigation580.interior(60,7),
              "PC main hall / connector / annex limits")
        check(!open.clear(0,2.8,0) && !open.clear(5,0.6,3,takeoff:true) &&
              open.clear(10,0.8,12,takeoff:true),
              "central ship and source minimum takeoff clearance enforced")
        check(open.airspace(10,2.8,12),"verified safe source patrol airspace")
        let begin=SIMD3<Float>(10,2.8,12)
        let end=SIMD3<Float>(14,2.8,12)
        check(open.segment(begin,end),"swept body flight along a safe aisle")
        check(!open.segment(begin,SIMD3<Float>(60,2.8,12)),
              "no jumps across exterior scene boundaries")
        let start=open.closest(to:begin)
        let destination=open.closest(to:end)
        check(start != nil && destination != nil,
              "nearest collision-verified source nodes exist")
        if let start,let destination {
            let route=open.route(from:start,to:destination)
            check(route.first==start && route.last==destination,
                  "BFS returns ordered route including source start/end")
            for pair in zip(route,route.dropFirst()) {
                check(open.nodes[pair.0].edges.contains(pair.1) &&
                      open.segment(open.position(pair.0),open.position(pair.1)),
                      "every edge in route is a verified physical flight segment")
            }
        }
        check(open.launch(SIMD3<Float>(8.8,0.05,12.4)) != nil &&
              open.launch(SIMD3<Float>(11.0,0.05,12.5)) != nil,
              "two author-rooted vertical rises and connected egress")
        check(open.launch(SIMD3<Float>(10,5.4,12)) == nil,
              "unsafe author elevation rejected without fabricating location")

        let blocked=H55DroneNavigation580(clearance:{x,_,_,_ in x<14})
        check(blocked.openCount<open.openCount &&
              !blocked.segment(begin,end),
              "real cameraClear collision callback can block a flight segment")

        guard let flight=H55DroneFlight580(navigation:open,spawns:selected)
        else{preconditionFailure("H71 two original drone spawns must pass safe launch")}
        check(flight.pilots.count==2 && flight.pilots.allSatisfy{$0.takeoff},
              "both aircraft start from their own GLB-authored takeoff points")
        check(H55DroneFlight580(navigation:open,spawns:[])==nil,
              "no fallback or procedural drone without selected GLB meshes")
        let idlePlayer=H55DroneFlight580.Player(
            walking:false,position:SIMD3<Float>(30,0,0),yaw:0)
        for _ in 0..<1200 {
            flight.advance(dt:1/60,player:idlePlayer)
            for p in flight.pilots where p.active && p.rescuePhase==0 {
                check(open.clear(p.position.x,p.position.y,p.position.z,
                                 takeoff:p.takeoff),
                      "the two real drone positions always satisfy collision")
            }
        }
        check(flight.pilots.allSatisfy{$0.position.y>2.0},
              "both drones physically rise above floor before patrolling")
        check(flight.pilots.allSatisfy{$0.active},
              "both original drones remain active in an open 20s arena")

        guard let at60=H55DroneFlight580(navigation:open,spawns:selected),
              let at120=H55DroneFlight580(navigation:open,spawns:selected)
        else{preconditionFailure("drone fixtures")}
        for _ in 0..<600 {at60.advance(dt:1/60,player:idlePlayer)}
        for _ in 0..<1200 {at120.advance(dt:1/120,player:idlePlayer)}
        for i in 0..<2 {
            check(H55DroneFlight580.distance(
                at60.pilots[i].position,at120.pilots[i].position)<0.3,
                "fixed 10ms drone physics remains 60/120Hz consistent")
            check(abs(at60.pilots[i].yaw-at120.pilots[i].yaw)<3,
                "body-relative bank/yaw remain stable across frame rates")
        }
        print("PASS \(checks) H12/H71 source imported GLB selection, real 2m lattice, safe two-drone launches, collision-checked flight, recovery-ready pilots, 60/120Hz parity")
        print("LIMIT: GLB asset not included in this test; real H55 drone launch/navigation and SceneKit visual test remain unverified")
    }
}
