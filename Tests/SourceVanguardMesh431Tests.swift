import Foundation

/// Executable parser tests for the native v4311 source mesh.
/// The original 9.7 MB PC fixture is independently audited by
/// Tools/verify_original_vanguard_assets.py on its source ZIP.
@main struct SourceVanguardMesh431Tests {
    static func push(_ v:UInt32,_ d:inout Data) {
        var word=v.littleEndian
        Swift.withUnsafeBytes(of:&word) { d.append(contentsOf:$0) }
    }
    static func push(_ v:Float,_ d:inout Data) {
        push(v.bitPattern,&d)
    }
    static func fixture() -> Data {
        var data=Data()
        push(UInt32(4311),&data)
        push(UInt32(2),&data)
        for v:Float in [-0.44299397,-1.588713,-0.16747972,
                         0.44578472,-1.5894305,-0.18300314] {
            push(v,&data)
        }
        push(UInt32(36),&data) // exactly 3 triangle corners
        let values:[Float]=[
            -0.4158024,0.51597285,-0.1668883,
            -0.3400004,0.5343006,-0.77390087,
            1,1,1,1,0.38674918,0.47415537,
            1,0,0, 0,0,1, 1,1,1,1, 0,0,
            0,1,0, 0,0,1, 1,1,1,1, 1,1
        ]
        for v in values { push(v,&data) }
        push(UInt32(1),&data)  // one source CPU triangle
        for v:Float in [0,0,0,1,0,0,0,1,0] { push(v,&data) }
        return data
    }
    static func main() throws {
        let data=fixture()
        let parsed=try SourceVanguardMesh431(data:data)
        precondition(parsed.vertexCount==3)
        precondition(parsed.vertices.count==3*48)
        precondition(parsed.cpuFaceCount==1)
        precondition(parsed.engines.count==2)
        precondition(abs(parsed.engines[0].x+0.44299397)<1e-6)
        precondition(abs(parsed.engines[1].y+1.5894305)<1e-6)
        func packedFloat(_ pos:Int)->Float {
            let bytes=parsed.vertices
            let n=UInt32(bytes[pos]) |
                  (UInt32(bytes[pos+1])<<8) |
                  (UInt32(bytes[pos+2])<<16) |
                  (UInt32(bytes[pos+3])<<24)
            return Float(bitPattern:n)
        }
        precondition(abs(packedFloat(0)+0.4158024)<1e-6)
        precondition(abs(packedFloat(10*4)-0.38674918)<1e-6)
        precondition(abs(packedFloat(11*4)-0.47415537)<1e-6)

        func rejects(_ bytes:Data)->Bool {
            do { _=try SourceVanguardMesh431(data:bytes);return false }
            catch { return true }
        }
        var bad=fixture()
        bad.replaceSubrange(0..<4,with:[0,0,0,0])
        precondition(rejects(bad),"wrong source version accepted")
        bad=fixture()
        bad.replaceSubrange(4..<8,with:[3,0,0,0])
        precondition(rejects(bad),"wrong engine count accepted")
        bad=fixture()
        bad.replaceSubrange(32..<36,with:[1,0,0,0])
        precondition(rejects(bad),"invalid vertex stride accepted")
        bad=fixture()
        bad.removeLast()
        precondition(rejects(bad),"truncated CPU preview accepted")
        bad=fixture()
        bad.append(0xFF)
        precondition(rejects(bad),"appended source garbage accepted")
        bad=fixture()
        bad.replaceSubrange(8..<12,with:[0,0,0xC0,0x7F])
        precondition(rejects(bad),"NaN engine socket accepted")
        precondition(SourceVanguardMesh431.bytesPerVertex==48)
        precondition(SourceVanguardMesh431.floatsPerVertex==12)
        print("PASS: authentic Vanguard v4311 packet parser: two sockets,")
        print("      12-float UV+normal GPU vertices, exact original float bits,")
        print("      CPU face trailer and malformed asset rejection")
    }
}
