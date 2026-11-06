import Foundation

@main struct CarbonisSurface277Tests {
    static func main() throws {
        guard CommandLine.arguments.count == 2 else {
            fatalError("Usage: carbonis-surface-tests Sector01CarbonisHeightMap.dat")
        }
        let bytes = try Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[1]))
        guard let terrain = CarbonisSurface277(data: bytes) else {
            fatalError("The source 512x256 C279 map was rejected")
        }
        var checks = 0
        func equal(_ actual: Float, _ expected: Float, _ reason: String, tolerance: Float = 0.00002) {
            precondition(actual.isFinite && abs(actual - expected) < tolerance,
                         "\(reason): got \(actual), expected \(expected)")
            checks += 1
        }
        // Independent reference samples from raw Carbonis279.Mesh C# map,
        // decoded using Carbonis277.cs bilinear longitude/latitude equations.
        let points: [(Float, Float, Float, Float)] = [
            (1,0,0,1.0104186534881592),
            (-1,0,0,1.0128928422927856),
            (0,1,0,1.0115394592285156),
            (0,-1,0,1.0011619329452515),
            (0,0,1,1.0119817852973938),
            (0,0,-1,1.0124308466911316),
            (1,1,1,0.9394325539613517),
            (1,-1,1,1.0188382570071393),
            (-0.48,0.87,-0.20,0.9954343083879276),
            (0,0,0,1),
        ]
        for (x,y,z,expect) in points {
            equal(terrain.surfaceRadius(x:x,y:y,z:z),expect,"source point")
            equal(terrain.surfaceRadius(x:x*5,y:y*5,z:z*5),expect,"direction scale")
        }
        // Longitude seam on the negative X-axis and exact poles.
        equal(terrain.surfaceRadius(x:-1,y:0,z:0.000001),
              terrain.surfaceRadius(x:-1,y:0,z:-0.000001),"dateline seam")
        equal(terrain.surfaceRadius(x:0,y:5,z:0),
              terrain.surfaceRadius(x:0,y:1,z:0),"north pole")
        equal(terrain.surfaceRadius(x:0,y:-5,z:0),
              terrain.surfaceRadius(x:0,y:-1,z:0),"south pole")
        precondition(CarbonisSurface277(data: Data()) == nil)
        checks += 1
        var damaged = bytes
        damaged[0] = 255
        precondition(CarbonisSurface277(data: damaged) == nil)
        checks += 1
        damaged = bytes
        damaged[4] = 255
        precondition(CarbonisSurface277(data: damaged) == nil)
        checks += 1
        damaged = bytes
        // A source float NaN must be rejected (to avoid silent invalid heights).
        damaged.replaceSubrange(8..<12, with: [0,0,192,127])
        precondition(CarbonisSurface277(data: damaged) == nil)
        checks += 1
        print("PASS: \(checks) checks of source C279 512x256 surface lookup, wrap, poles and input safety")
        print("LIMIT: map sampling only; live Carbonis flight/contact/mission Wave remain unported")
    }
}
