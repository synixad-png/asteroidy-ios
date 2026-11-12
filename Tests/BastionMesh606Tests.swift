import Foundation

/// The PC v606 Bastion 6061 baked stream uses the exact same 12-float
/// decoder as Vanguard431, with two source engine sockets.
@main struct BastionMesh606Tests {
    static func main() throws {
        var data=Data()
        func u32(_ x:UInt32) {
            data.append(UInt8(truncatingIfNeeded:x))
            data.append(UInt8(truncatingIfNeeded:x >> 8))
            data.append(UInt8(truncatingIfNeeded:x >> 16))
            data.append(UInt8(truncatingIfNeeded:x >> 24))
        }
        func f32(_ f:Float) {u32(f.bitPattern)}
        u32(6061);u32(2)
        for f in [Float(-0.26),(-1.48),(-0.02),0.28,(-1.48),(-0.02)] {
            f32(f)
        }
        u32(36) // Three corners, 12 Float32 each.
        for _ in 0..<3 {
            for f in [Float(1),2,3,0,0,1,0.8,0.8,0.8,1,0.2,0.3] {
                f32(f)
            }
        }
        u32(1) // One CPU preview triangle, three XYZ positions.
        for _ in 0..<9 {f32(0)}
        let ship=try SourceBakedShipMesh(data:data,expectedMagic:6061)
        precondition(ship.vertexCount==3 && ship.engines.count==2 &&
                     ship.cpuFaceCount==1 && ship.vertices.count==144)
        precondition(abs(ship.engines[0].y+1.48)<0.001)
        do {
            _=try SourceBakedShipMesh(data:data)
            preconditionFailure("Bastion accepted as Vanguard: bad magic")
        } catch SourceBakedShipMesh.FormatError.badMagic {}
        // No implicit substitution or 4311 remapping allowed.
        var invalid=data
        invalid[0]=0x03
        do {
            _=try SourceBakedShipMesh(data:invalid,expectedMagic:6061)
            preconditionFailure("Incorrect PC engine mesh marker accepted")
        } catch SourceBakedShipMesh.FormatError.badMagic {}
        print("PASS PC606 Bastion 6061: single shared GPU ABI, two engine sockets, no Vanguard fallback")
    }
}
