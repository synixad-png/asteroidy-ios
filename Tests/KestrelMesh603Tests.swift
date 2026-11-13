import Foundation

/// Source PC v603 KESTREL, baked GPU 6031 geometry. The existing same
/// 12-Float32 reader used for Vanguard431 and Bastion606 must accept 6031.
@main struct KestrelMesh603Tests {
    static func main() throws {
        var data=Data()
        func u32(_ x:UInt32) {
            data.append(UInt8(truncatingIfNeeded:x))
            data.append(UInt8(truncatingIfNeeded:x >> 8))
            data.append(UInt8(truncatingIfNeeded:x >> 16))
            data.append(UInt8(truncatingIfNeeded:x >> 24))
        }
        func f32(_ f:Float) {u32(f.bitPattern)}
        u32(6031);u32(2)
        for f in [Float(-0.27111337),-1.1866529,0.11115501,
                  0.28042188,-1.18763208,0.1036826] {f32(f)}
        u32(36)
        for _ in 0..<3 {
            for f in [Float(1),2,3,0,0,1,1,1,1,1,0.2,0.3] {f32(f)}
        }
        u32(1)
        for _ in 0..<9 {f32(0)}
        let ship=try SourceBakedShipMesh(data:data,expectedMagic:6031)
        precondition(ship.vertexCount==3 && ship.engines.count==2 &&
                     ship.cpuFaceCount==1 && ship.vertices.count==144)
        precondition(abs(ship.engines[0].y+1.1866529)<0.001)
        for magic in [4311,6061] {
            do {
                _=try SourceBakedShipMesh(data:data,expectedMagic:magic)
                preconditionFailure("KESTREL was incorrectly loaded as another ship")
            } catch SourceBakedShipMesh.FormatError.badMagic {}
        }
        var invalid=data
        invalid[0]=0x00
        do {
            _=try SourceBakedShipMesh(data:invalid,expectedMagic:6031)
            preconditionFailure("Invalid KESTREL magic accepted")
        } catch SourceBakedShipMesh.FormatError.badMagic {}
        print("PASS PC609 KESTREL603: shared GPU ABI, 2 real engines, no Vanguard/Bastion substitution")
    }
}
