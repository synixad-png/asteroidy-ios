import Foundation

/// Faithful PC v580 Windows/src/HubWalk375.cs:130-150,
/// HubWalkPlaceAtEntry380, and Hub90.cs:36-68 (StepHub90).
///
/// All physical queries are from the authentic H02/H03/H04 GLB triangles,
/// not visual SceneKit raycasts; the original six source candidates,
/// four clearance samples and 3.25s arrival are immutable source rules.
enum H55Entry580 {
    struct Position:Equatable {
        var x:Float
        var feet:Float
        var z:Float
    }
    static let candidates:[(x:Float,z:Float)] = [
        (2,14),(3,14),(-2,14),(4,15),(-4,15),(6,15)
    ]
    static let overhead:[Float]=[0,0.55,1.15,4.50]
    static let arrivalSeconds:Float=3.25

    static func find(using collision:H55SpatialSupport580)->Position? {
        // DO NOT replace with the old (0,12.5) copper-embedded spawn.
        // The original source returns the FIRST fully clear candidate,
        // not the one nearest the camera or the map origin.
        for position in candidates {
            let x=position.x,z=position.z
            guard let floor=collision.support(x,z,low:-0.25,high:0.45)
            else {continue}
            var clear=true
            for offset in overhead {
                if !collision.bodyClear379(x,feet:floor+offset,z) {
                    clear=false
                    break
                }
            }
            if clear {return Position(x:x,feet:floor,z:z)}
        }
        // Original fail-closed: never teleport into embedded GLB geometry.
        return nil
    }
}

/// Source Hub90.StepHub90 uses dt capped to .06, enables walk after
/// 3.25s exactly once, unless spawn failed. No automatic skip.
struct H55Arrival580 {
    private(set) var time:Float=0
    private(set) var started=false
    private(set) var walking=false
    let spawnClear:Bool
    init(spawnClear:Bool) {self.spawnClear=spawnClear}

    var arriving:Bool {time<H55Entry580.arrivalSeconds}
    mutating func advance(dt:Float) {
        guard dt.isFinite else{return}
        let frame=min(0.06,max(0,dt))
        time+=frame
        if time>=H55Entry580.arrivalSeconds && !started {
            started=true
            walking=spawnClear
        }
    }
    /// Exact PC Hub90.SkipHubArrival92: player explicitly skips.
    mutating func skip() {
        if arriving {
            time=H55Entry580.arrivalSeconds
            // StepHub90 still owns activation, on the next frame.
        }
    }
}
