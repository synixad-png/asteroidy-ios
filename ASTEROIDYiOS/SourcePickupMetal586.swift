import Foundation
import MetalKit
import CryptoKit

/// One resident GPU resource per original PC586 pickup type.
/// The approved GLB is SHA-verified, then its mechanically lossless
/// preconverted 12-float triangle stream and embedded JPEG are consumed by
/// the SAME existing Metal gameplay command encoder. No frame-time GLB IO.
struct SourcePickupMetal586 {
    let kind:SourcePickupModels586.Kind
    let triangles:MTLBuffer
    let vertexCount:Int
    let skin:MTLTexture

    private static func expected(_ kind:SourcePickupModels586.Kind)
        ->(count:Int,mesh:String,jpg:String) {
        switch kind {
        case .shield:return (27567,
            "706a39a504ade3f6b51ffa49f439c25e737ee42d92173cc23029d3bb573a7c2e",
            "1612ebb5d9d8c79f0232f885fbbc52483ab6df8f5b22743b0ac2253b01713964")
        case .boost:return (27837,
            "087de160a554328b975306decf7527f0c9aa7b44f459135e2ccf360214b8f67e",
            "ae87f82d0bee71adaaa480ed5a520977a777ba1c1a09275a2d2947354d384bd2")
        case .energy:return (28692,
            "9795e046475988c504159b41f54c4600499bf250c479c181094759940d481663",
            "5457560331a6f61a3a9af518c595a2ecc03b8c8a74980b4f044c9cfed9266a6c")
        case .bomb:return (27750,
            "c6eb907b60b28889220be4d97076aa93a87f14d4ef701541a0afae6062ef7c58",
            "4228a05eee0cd83c6e36bd3cdbed67ff661129d4550f2a22089c5c28196481ff")
        }
    }
    private static func file(_ kind:SourcePickupModels586.Kind,
                             ext:String)->URL? {
        Bundle.main.url(forResource:kind.rawValue,withExtension:ext)
            ?? Bundle.main.url(forResource:kind.rawValue,withExtension:ext,
                               subdirectory:"Assets")
    }
    private static func sha(_ bytes:Data)->String {
        SHA256.hash(data:bytes).map{String(format:"%02x",$0)}.joined()
    }

    init?(kind:SourcePickupModels586.Kind,device:MTLDevice,
          textures:MTKTextureLoader) {
        guard SourcePickupModels586.verifiedBundledURL(kind) != nil,
              let meshURL=Self.file(kind,ext:"mesh"),
              let imageURL=Self.file(kind,ext:"jpg"),
              let bytes=try? Data(contentsOf:meshURL),
              let jpeg=try? Data(contentsOf:imageURL) else {return nil}
        let original=Self.expected(kind)
        guard bytes.count==40+original.count*48,
              bytes[0]==0x50,bytes[1]==0x35,bytes[2]==0x38,bytes[3]==0x36,
              (UInt32(bytes[4]) | UInt32(bytes[5])<<8
                | UInt32(bytes[6])<<16 | UInt32(bytes[7])<<24)
                    == original.count,
              Self.sha(bytes)==original.mesh,
              Self.sha(jpeg)==original.jpg,
              let dataSha=Data(hexString:kind.sha256),
              Data(bytes[8..<40])==dataSha else {return nil}
        let stream=Data(bytes.dropFirst(40))
        guard let buffer=stream.withUnsafeBytes({raw -> MTLBuffer? in
            guard let start=raw.baseAddress else{return nil}
            return device.makeBuffer(bytes:start,length:raw.count,options:[])
        }) else{return nil}
        let options:[MTKTextureLoader.Option:Any]=[
            .SRGB:false,.generateMipmaps:false,
            .origin:MTKTextureLoader.Origin.topLeft]
        guard let image=try? textures.newTexture(data:jpeg,options:options)
        else{return nil}
        self.kind=kind
        self.triangles=buffer
        self.vertexCount=original.count
        self.skin=image
    }
}

private extension Data {
    init?(hexString:String) {
        guard hexString.count%2==0 else{return nil}
        var output=[UInt8]()
        output.reserveCapacity(hexString.count/2)
        let text=Array(hexString.utf8)
        for i in stride(from:0,to:text.count,by:2) {
            func nibble(_ digit:UInt8)->UInt8? {
                if (48...57).contains(digit) {return digit-48}
                if (97...102).contains(digit) {return digit-87}
                return nil
            }
            guard let a=nibble(text[i]),let b=nibble(text[i+1])
            else{return nil}
            output.append(a<<4|b)
        }
        self.init(output)
    }
}
