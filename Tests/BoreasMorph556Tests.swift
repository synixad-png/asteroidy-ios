import Foundation
@main struct BoreasMorph556Tests {
    static func main() throws {
        let path = CommandLine.arguments[1]
        let original = try Data(contentsOf: URL(fileURLWithPath: path))
        let model = try BoreasMorph556(data: original)
        precondition(model.vertexCount == 27035 && model.targetCount == 6)
        precondition(model.times.count == 126 && model.duration == 5)
        precondition(model.sampleWeights(seconds: 0) == model.sampleWeights(seconds: 5))
        precondition(model.sampleWeights(seconds: 1.25) == model.sampleWeights(seconds: 6.25))
        precondition(model.sampleWeights(seconds: -3.75) == model.sampleWeights(seconds: 1.25))
        let t = (Double(model.times[4]) + Double(model.times[5])) / 2
        let mid = model.sampleWeights(seconds: t)
        for i in 0..<6 {
            let expected = (model.weights[4][i] + model.weights[5][i]) / 2
            precondition(abs(mid[i] - expected) < 0.0001)
        }
        let p0 = model.position(vertex: 42, seconds: 0)!
        let p1 = model.position(vertex: 42, seconds: 1.25)!
        precondition(p0.x.isFinite && p1.y.isFinite)
        precondition(model.position(vertex: -1, seconds: 0) == nil)
        // prove at least one real morphing position changes within the cycle
        precondition((0..<model.vertexCount).contains { idx in
            guard let a = model.position(vertex: idx, seconds: 0),
                  let b = model.position(vertex: idx, seconds: 1.25) else { return false }
            let d = a - b
            return d.x*d.x + d.y*d.y + d.z*d.z > 0.000001
        })
        var broken = original; broken.removeLast()
        do { _ = try BoreasMorph556(data: broken); preconditionFailure("truncated accepted") }
        catch BoreasMorph556.MorphError.invalidPayload { }
        var invalid = original
        // NaN first base position (20...24)
        invalid.replaceSubrange(20..<24, with: [0,0,192,127])
        do { _ = try BoreasMorph556(data: invalid); preconditionFailure("NaN accepted") }
        catch BoreasMorph556.MorphError.invalidPayload { }
        print("PASS Boreas: 27035 vertices, 6 morph targets, 126 keyframes, 5s loop, interpolation and corruption checks")
    }
}
