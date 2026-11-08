import Foundation

@main struct H55Airlocks580Tests {
    static func check(_ ok:Bool,_ msg:String) {
        precondition(ok,"H07: "+msg)
    }
    static func near(_ a:Float,_ b:Float,_ tol:Float=0.00003)->Bool {
        abs(a-b)<=tol
    }
    static func push32(_ d:inout Data,_ v:UInt32) {
        for k in 0..<4 {d.append(UInt8((v >> (k*8)) & 255))}
    }
    static func floats(_ numbers:[Float])->Data {
        var data=Data()
        for f in numbers {push32(&data,f.bitPattern)}
        return data
    }
    static func fixture() throws -> URL {
        // Real H70 topology, four SCALAR/VEC3 accessors and exactly 2 x 2
        // glTF translation channels; nodes use actual H70 names/indices.
        var nodes=[[String:Any]]()
        for i in 0...1203 {
            let name=i>=1200
                ? H55AirlockController580.leafNames[(i-1200)/2][(i-1200)%2]
                : "fixture_node_\(i)"
            nodes.append(["name":name])
        }
        var binary=Data()
        var views=[[String:Any]](),accessors=[[String:Any]]()
        var animations=[[String:Any]]()
        let times:[Float]=[0,0.85,1.85,8]
        for gate in 0..<2 {
            var samplers=[[String:Any]](),channels=[[String:Any]]()
            for side in 0..<2 {
                let timeIndex=accessors.count
                let timeBytes=floats(times)
                let timeOffset=binary.count
                binary.append(timeBytes)
                views.append(["buffer":0,"byteOffset":timeOffset,"byteLength":timeBytes.count])
                accessors.append(["bufferView":views.count-1,"componentType":5126,
                                  "type":"SCALAR","count":times.count])
                let x:Float=gate==0 ? 24.36 : 30.46
                let z:Float=side==0 ? 4.67 : 9.63
                let closed:Float=side==0 ? 6.355 : 7.945
                let poses:[Float]=[x,1.65,z,x,1.65,z,
                                   x,1.65,closed,x,1.65,z]
                let outBytes=floats(poses)
                let valueOffset=binary.count
                binary.append(outBytes)
                views.append(["buffer":0,"byteOffset":valueOffset,"byteLength":outBytes.count])
                accessors.append(["bufferView":views.count-1,"componentType":5126,
                                  "type":"VEC3","count":times.count])
                samplers.append(["input":timeIndex,"output":accessors.count-1,
                                 "interpolation":"LINEAR"])
                channels.append(["sampler":side,
                                 "target":["node":1200+gate*2+side,
                                           "path":"translation"]])
            }
            animations.append(["name":H55AirlockController580.clipNames[gate],
                               "samplers":samplers,"channels":channels])
        }
        let json:[String:Any]=["asset":["version":"2.0"],"scene":0,
                 "scenes":[["nodes":[0]]],"nodes":nodes,"animations":animations,
                 "bufferViews":views,"accessors":accessors,
                 "buffers":[["byteLength":binary.count]]]
        var jsonBytes=try JSONSerialization.data(withJSONObject:json,options:[.sortedKeys])
        while jsonBytes.count%4 != 0 {jsonBytes.append(32)}
        while binary.count%4 != 0 {binary.append(0)}
        var glb=Data()
        push32(&glb,0x46546C67);push32(&glb,2)
        push32(&glb,UInt32(12+8+jsonBytes.count+8+binary.count))
        push32(&glb,UInt32(jsonBytes.count));push32(&glb,0x4E4F534A)
        glb.append(jsonBytes)
        push32(&glb,UInt32(binary.count));push32(&glb,0x004E4942)
        glb.append(binary)
        let url=FileManager.default.temporaryDirectory
            .appendingPathComponent("h07-source-glb-\(UUID().uuidString).glb")
        try glb.write(to:url,options:.atomic)
        return url
    }
    static func floor()->H55SpatialSupport580 {
        let triangles:[Float]=[
            -28,0,-18, 56,0,-18, -28,0,20,
             56,0,-18, 56,0,20, -28,0,20
        ]
        return H55SpatialSupport580(geometry:
            H55CollisionGeometry580.Geometry(
                triangles:triangles,objects:[],sourceTriangles:2,
                proxyTriangles:0,sceneNodes:1,
                minX:-30,maxX:60,minZ:-20,maxZ:22))
    }

    static func main() throws {
        let url=try fixture()
        defer {try? FileManager.default.removeItem(at:url)}
        let keys=try H55AirlockTracks580.load(from:url)
        check(keys.nodes.count==4,"both authentic H70 leaf pairs read")
        for gate in 0..<2 {
            for side in 0..<2 {
                let name=H55AirlockController580.leafNames[gate][side]
                let open=keys.sample(leaf:name,time:0.85)!
                let closed=keys.sample(leaf:name,time:1.85)!
                let mid=keys.sample(leaf:name,time:1.35)!
                check(near(open.z,side==0 ? 4.67:9.63),
                      "authored OPEN translation "+name)
                check(near(closed.z,side==0 ? 6.355:7.945),
                      "authored CLOSED translation "+name)
                check(near(mid.z,(open.z+closed.z)/2),
                      "original LINEAR interpolation "+name)
            }
        }
        var gate=H55AirlockController580()
        check(gate.blockingGate(fromX:23,fromZ:7.15,
                 toX:24.4,toZ:7.15)==0,"source gate0 closed collision")
        check(gate.blockingGate(fromX:29.7,fromZ:7.15,
                 toX:30.2,toZ:7.15)==1,"source gate1 closed collision")
        check(gate.blockingGate(fromX:23,fromZ:2,
                 toX:25,toZ:2)==nil,"source Z throat guard")
        check(near(H55AirlockController580.clipTime(for:0),1.85) &&
              near(H55AirlockController580.clipTime(for:1),0.85),
              "source H70 reversed clip timing")
        gate.step(playerX:19,playerZ:7.15,playerPresent:true,
                  npcX:0,npcZ:0,npcPresent:false,dt:0.1)
        check(near(gate.openness[0],0.1/0.85),
              "source .85 second opening")
        for _ in 0..<8 {
            gate.step(playerX:19,playerZ:7.15,playerPresent:true,
                      npcX:0,npcZ:0,npcPresent:false,dt:0.1)
        }
        check(gate.openness[0]>=0.9 &&
              gate.blockingGate(fromX:23,fromZ:7.15,
                toX:24.4,toZ:7.15)==nil,"90% leaf release threshold")
        gate.step(playerX:31.1,playerZ:7.15,playerPresent:true,
                  npcX:0,npcZ:0,npcPresent:false,dt:0.1)
        check(gate.playerHeld[0],"outer radius holds after inner exit")
        gate.step(playerX:50,playerZ:50,playerPresent:true,
                  npcX:24.36,npcZ:7.15,npcPresent:true,dt:0.1)
        check(!gate.playerHeld[0] && gate.npcHeld[0],
              "npc sensor independently holds open when player leaves")
        for _ in 0..<18 {
            gate.step(playerX:50,playerZ:50,playerPresent:false,
                      npcX:50,npcZ:50,npcPresent:false,dt:0.1)
        }
        check(near(gate.openness[0],0) &&
              gate.blockingGate(fromX:23,fromZ:7.15,
                toX:25,toZ:7.15)==0,
              "source 1.15 second closing and restored solid barrier")

        let p=floor()
        var player=H55Walk580()
        player.x=23.3;player.z=7.15;player.placeAtSpawn(feet:0)
        for _ in 0..<140 {
            player.step(dt:1/60,forward:0,right:1,sprint:true,
                collision:p,doorBlocks:{ax,az,bx,bz in
                    gate.blockingGate(fromX:ax,fromZ:az,toX:bx,toZ:bz) != nil
                })
        }
        check(player.x<=24.06 && p.bodyClear379(player.x,feet:player.y,player.z),
              "H06 substeps do NOT walk through a closed H70 leaf")

        for _ in 0..<10 {
            gate.step(playerX:player.x,playerZ:player.z,playerPresent:true,
                      npcX:50,npcZ:50,npcPresent:false,dt:0.1)
        }
        check(gate.openness[0]>=0.9,"sensor opens for player")
        for _ in 0..<80 {
            player.step(dt:1/60,forward:0,right:1,sprint:true,
                collision:p,doorBlocks:{ax,az,bx,bz in
                    gate.blockingGate(fromX:ax,fromZ:az,toX:bx,toZ:bz) != nil
                })
        }
        check(player.x>24.36,"same H06 movement crosses OPEN gate")

        var npc=H55Mechanic580()
        npc.calibrate(anatomicalHeading:0)
        npc.finishConversation()
        for _ in 0..<300 {
            npc.step(dt:0.05,playerX:50,playerZ:50,
                     canWalk:{_,_ in true},
                     doorBlocking:{_,_,_,_ in 0})
        }
        check(npc.doorFailure==0 && npc.detoursBuilt==0,
              "PC v544 2.5s closed door abort, no NPC A* bypass")
        check(!npc.isPatrolling,"stopped NPC does not keep airlock sensor active")
        print("PASS H07: source v393/v544 two H70 clips, 4 GLB channels, exact times, independent sensors, 0.90 barrier, source NPC abort and player sweep")
    }
}
