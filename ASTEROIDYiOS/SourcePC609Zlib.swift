import Foundation
import Compression

/// Decodes the ORIGINAL PC609 .kestrel/.bastion pack payload. Python
/// zlib.compress produces RFC1950 (2-byte header + raw RFC1951 DEFLATE
/// + 4-byte Adler32); Apple's COMPRESSION_ZLIB consumes only raw DEFLATE.
/// The exact source pack SHA256 and inflated mesh SHA256 remain enforced
/// by SourceKestrel603 / SourceBastion606 on either side of this decoder.
enum SourcePC609Zlib {
    static func inflateRFC1950(_ input:Data,exactBytes:Int)->Data? {
        guard input.count>=7,exactBytes>0,exactBytes<=24_000_000 else {
            return nil
        }
        let cmf=Int(input[0]),flg=Int(input[1])
        guard cmf&0x0F==8,cmf>>4<=7,(cmf*256+flg)%31==0,
              (flg&0x20)==0 else { return nil }
        let deflate=Data(input[2..<(input.count-4)])
        var output=Data(count:exactBytes)
        let written=output.withUnsafeMutableBytes { dst -> Int in
            deflate.withUnsafeBytes { src -> Int in
                guard let d=dst.baseAddress?.assumingMemoryBound(to:UInt8.self),
                      let s=src.baseAddress?.assumingMemoryBound(to:UInt8.self)
                else{return 0}
                return compression_decode_buffer(
                    d,exactBytes,s,deflate.count,nil,COMPRESSION_ZLIB)
            }
        }
        return written==exactBytes ? output : nil
    }
}
