import Foundation
import CryptoKit
import MetalKit

/// One byte-verified GPU allocation for the original PC v602 NewHome290 H290
/// geometry (172208 GLB triangles), base JPEG and source-generated lava map.
/// W3 menu preview and orbital gameplay share these SAME immutable GPU buffers.
/// No replacement meshes, duplicated GPU uploads or run-time conversions.
final class SourceNewHome290MetalAssets {
    enum SourceError:Error {case missing,invalid,metal}
    // Reuse this exact MTLDevice object for both source-planet views;
    // a separate MTLCreateSystemDefaultDevice() wrapper could defeat the
    // per-device identity cache and duplicate the 24.8 MB geometry.
    static let defaultDevice:MTLDevice? = MTLCreateSystemDefaultDevice()
    static let geometrySHA256="e93a0bbafc9bb50a25726a828ada81f36675bf88d802c5a8f985b89b6dc96c1b"
    static let baseSHA256="4987f35cd6f021fd98794f406c641f4853c538a82b10625e6b79e860c8a787c0"
    static let glowSHA256="6f1debd175f52b7ce1fbc687e9977597335ee432858d7d6d6e47cf66b5f9aa39"
    static let terrainVertices=514176
    static let armorVertices=2448
    static let vertexStride=48
    private static let lock=NSLock()
    private static var cached:[ObjectIdentifier:SourceNewHome290MetalAssets]=[:]

    let vertices:MTLBuffer
    let base:MTLTexture
    let glow:MTLTexture

    private static func checkedResource(_ name:String,_ ext:String,_ hash:String)
        throws -> Data {
        guard let url=Bundle.main.url(forResource:name,withExtension:ext)
            ?? Bundle.main.url(forResource:name,withExtension:ext,subdirectory:"Assets"),
              let data=try? Data(contentsOf:url)
        else {throw SourceError.missing}
        let digest=SHA256.hash(data:data)
            .map {String(format:"%02x",$0)}.joined()
        guard digest==hash else {throw SourceError.invalid}
        return data
    }

    private init(device:MTLDevice) throws {
        let mesh=try Self.checkedResource("W3HomePlanet290OriginalGPU","bin",
                                         Self.geometrySHA256)
        guard mesh.count == (Self.terrainVertices + Self.armorVertices) * Self.vertexStride
        else {throw SourceError.invalid}
        guard let buffer=mesh.withUnsafeBytes({ raw in
            raw.baseAddress.flatMap {
                device.makeBuffer(bytes:$0,length:mesh.count,options:[])
            }
        }) else {throw SourceError.metal}
        vertices=buffer
        let loader=MTKTextureLoader(device:device)
        let options:[MTKTextureLoader.Option:Any]=[
            .SRGB:false,.generateMipmaps:false,
            .origin:MTKTextureLoader.Origin.topLeft]
        base=try loader.newTexture(data:Self.checkedResource(
            "W3HomePlanet290Base","dat",Self.baseSHA256),options:options)
        glow=try loader.newTexture(data:Self.checkedResource(
            "W3HomePlanet293Glow","dat",Self.glowSHA256),options:options)
    }

    static func shared(device:MTLDevice) throws -> SourceNewHome290MetalAssets {
        lock.lock()
        defer {lock.unlock()}
        let key=ObjectIdentifier(device)
        if let existing=cached[key] {return existing}
        let original=try SourceNewHome290MetalAssets(device:device)
        cached[key]=original
        return original
    }
}
