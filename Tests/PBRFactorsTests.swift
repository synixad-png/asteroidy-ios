import Foundation
@main struct PBRFactorsTests {
  static func main() throws {
    let root = CommandLine.arguments[1]
    let boreas = try Data(contentsOf: URL(fileURLWithPath: root + "/Boreas556.as3d"))
    let vanguard = try Data(contentsOf: URL(fileURLWithPath: root + "/Vanguard556.as3d"))
    precondition(boreas[4] == 3 && vanguard[4] == 1)
    let b = try AssetMesh(data: boreas)
    let v = try AssetMesh(data: vanguard)
    precondition(b.vertices.count == 31355 && v.vertices.count == 50026)
    precondition(b.vertices.allSatisfy { (0...1).contains($0.material.x) && (0.04...1).contains($0.material.y) })
    precondition(b.vertices.allSatisfy { abs($0.material.z - 0.86) < 0.001 && abs($0.material.w - 0.048) < 0.001 })
    precondition(v.vertices.allSatisfy { $0.material.x == 0 && $0.material.y == 1 })
    // Prove we actually imported high-metallicity and polished glTF material factors.
    precondition(b.vertices.contains { $0.material.x > 0.9 && $0.material.y < 0.1 })
    var malformed = boreas
    // First metallic factor (offset 16 header + 32 bytes of vertex position/color) > 1.
    let invalid: [UInt8] = [0,0,0,64]
    malformed.replaceSubrange(48..<52, with: invalid)
    do { _ = try AssetMesh(data:malformed); preconditionFailure("Invalid metallic factor accepted") }
    catch AssetMesh.ParseError.invalidHeader { }
    var broken = boreas
    broken.removeLast()
    do { _ = try AssetMesh(data:broken); preconditionFailure("Truncated v3 accepted") }
    catch AssetMesh.ParseError.truncated { }
    print("PASS: AS3D v1 compatibility, v3 glTF PBR + clearcoat factors, malformed/truncated rejection")
  }
}
