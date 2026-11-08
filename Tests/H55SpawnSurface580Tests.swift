import Foundation

@main struct H55SpawnSurface580Tests {
    static func main() {
        typealias S=H55FloorRule580.Sample
        func check(_ b:Bool,_ msg:String){precondition(b,msg)}
        // PROVEN from real user H55 GLB mesh 37 (02_floor_plates__floor)
        // at PC candidate (6,15): top Y .085 with face normal (0,-1,0),
        // underside Y .005 and normal (0,+1,0). Source v580 accepts
        // both and returns the HIGHEST real support.
        let actual=[S(x:6,y:0.085,z:15,normalX:0,normalY:-1,normalZ:0),
                    S(x:6,y:0.005,z:15,normalX:0,normalY:1,normalZ:0)]
        check(H55FloorRule580.highest(actual,low:-0.25,high:0.45)==0.085,
              "original GLB top must NOT be rejected due to reversed winding")
        check(H55FloorRule580.accepts(normalX:0,normalY:-1,normalZ:0,
                                     floor:0.085,low:-0.25,high:0.45),
              "PC v580 accepts floor facing down")
        check(H55FloorRule580.accepts(normalX:0,normalY:1,normalZ:0,
                                     floor:0.005,low:-0.25,high:0.45),
              "PC v580 accepts floor facing up")
        check(!H55FloorRule580.accepts(normalX:1,normalY:0,normalZ:0,
                                     floor:0.1,low:-0.25,high:0.45),
              "walls are never floor")
        check(!H55FloorRule580.accepts(normalX:0,normalY:1,normalZ:0,
                                     floor:2,low:-0.25,high:0.45),
              "upper catwalk not reachable from source spawn")
        check(!H55FloorRule580.accepts(normalX:Float.nan,normalY:1,
                                     normalZ:0,floor:0,low:-0.25,high:0.45),
              "reject nonfinite normals")
        print("PASS: original GLB H55 floor at 6,15, Y=0.085, normal=-Y, source highest support, wall filtering")
    }
}
