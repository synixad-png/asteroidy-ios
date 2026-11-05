import Foundation

// Authored morph target payload read from v556 Boreas glTF (node 0, mesh 0).
// Local model coordinates. This is an independently testable decode/sampling
// component, NOT wired into the Metal render loop yet.
struct BoreasMorph556 {
    enum MorphError: Error { case invalidHeader, invalidPayload, invalidAnimation }
    let base: [SIMD3<Float>]
    let deltas: [[SIMD3<Float>]]
    let times: [Float]
    let weights: [[Float]]
    var duration: Float { times.last ?? 0 }
    var vertexCount: Int { base.count }
    var targetCount: Int { deltas.count }

    init(data: Data) throws {
        guard data.count >= 20, Array(data.prefix(4)) == Array("ASMO".utf8) else { throw MorphError.invalidHeader }
        func uint(_ offset: Int) -> UInt32 {
            UInt32(data[offset]) | UInt32(data[offset + 1]) << 8 | UInt32(data[offset + 2]) << 16 | UInt32(data[offset + 3]) << 24
        }
        guard uint(4) == 1 else { throw MorphError.invalidHeader }
        let n = Int(uint(8)), targetCount = Int(uint(12)), keyCount = Int(uint(16))
        guard n > 0, n <= 2_000_000, targetCount > 0, targetCount <= 16,
              keyCount >= 2, keyCount <= 65536 else { throw MorphError.invalidHeader }
        let floatCount = n * 3 * (1 + targetCount) + keyCount * (1 + targetCount)
        guard data.count == 20 + floatCount * 4 else { throw MorphError.invalidPayload }
        func f(_ offset: Int) -> Float { Float(bitPattern: uint(offset)) }
        var offset = 20
        func readPositions(_ count: Int) throws -> [SIMD3<Float>] {
            var result: [SIMD3<Float>] = []
            result.reserveCapacity(count)
            for _ in 0..<count {
                let x = f(offset), y = f(offset + 4), z = f(offset + 8)
                guard x.isFinite && y.isFinite && z.isFinite else { throw MorphError.invalidPayload }
                result.append(SIMD3(x, y, z)); offset += 12
            }
            return result
        }
        let loadedBase = try readPositions(n)
        var loadedDeltas: [[SIMD3<Float>]] = []
        for _ in 0..<targetCount { loadedDeltas.append(try readPositions(n)) }
        var loadedTimes: [Float] = [], loadedWeights: [[Float]] = []
        for _ in 0..<keyCount {
            let time = f(offset); offset += 4
            var row: [Float] = []
            for _ in 0..<targetCount { row.append(f(offset)); offset += 4 }
            guard time.isFinite && row.allSatisfy({ $0.isFinite }) else { throw MorphError.invalidAnimation }
            loadedTimes.append(time); loadedWeights.append(row)
        }
        guard loadedTimes[0] == 0, loadedTimes.last! > 0,
              zip(loadedTimes, loadedTimes.dropFirst()).allSatisfy({ $0 < $1 }) else {
            throw MorphError.invalidAnimation
        }
        base = loadedBase; deltas = loadedDeltas; times = loadedTimes; weights = loadedWeights
    }

    // Keyframe interpolation exactly matching glTF LINEAR and looping every 5s.
    func sampleWeights(seconds: Double) -> [Float] {
        guard seconds.isFinite, duration > 0 else { return weights[0] }
        let t = Float(seconds.truncatingRemainder(dividingBy: Double(duration)) < 0
                      ? seconds.truncatingRemainder(dividingBy: Double(duration)) + Double(duration)
                      : seconds.truncatingRemainder(dividingBy: Double(duration)))
        if t <= 0 { return weights[0] }
        var low = 0, high = times.count - 1
        while high - low > 1 { let mid = (low + high) / 2; if times[mid] <= t { low = mid } else { high = mid } }
        let portion = (t - times[low]) / (times[high] - times[low])
        return (0..<targetCount).map { weights[low][$0] + (weights[high][$0] - weights[low][$0]) * portion }
    }

    func position(vertex: Int, seconds: Double) -> SIMD3<Float>? {
        guard base.indices.contains(vertex) else { return nil }
        let w = sampleWeights(seconds: seconds)
        var p = base[vertex]
        for i in 0..<targetCount { p += deltas[i][vertex] * w[i] }
        return p
    }
}
