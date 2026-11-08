import Foundation

/// The exact user-supplied H55 GLB has ONE nonconforming glTF 2.0 accessor:
/// accessors[6329] is SCALAR with `"min":0,"max":10`, but these
/// values must be single-element arrays. GLTFKit2 0.5.15's cgltf
/// parser rejects the whole GLB with cgltf_result_invalid_gltf.
///
/// After an ORIGINAL SHA-256 identity check in H55Asset580, make a
/// compatibility copy without re-exporting geometry or serializing all JSON.
/// Only four JSON bytes are added; binary geometry, materials, images and
/// all 62 animation tracks remain BYTE-FOR-BYTE IDENTICAL. The original
/// user file in Files is NEVER modified.
///
/// The repaired result was validated on the genuine 126419336-byte upload
/// using the very same cgltf 1.15 header pinned by GLTFKit2 0.5.15:
/// cgltf_parse_file=success and cgltf_validate=success.
enum H55GLBCompatibility580 {
    enum RepairError: Error, LocalizedError {
        case invalidGLB, mismatchedSource, duplicateRecord, invalidLayout
        var errorDescription: String? {
            switch self {
            case .invalidGLB: return "Niepoprawna struktura wejściowa GLB 2.0."
            case .mismatchedSource: return "Nie znaleziono znanego błędnego rekord zakresu animacji."
            case .duplicateRecord: return "Niejednoznaczne dane akcesora GLB."
            case .invalidLayout: return "Uszkodzona długość sekcji BIN lub JSON."
            }
        }
    }

    private static let original = Data(
        "\"componentType\":5126,\"count\":51,\"type\":\"SCALAR\",\"min\":0,\"max\":10}".utf8)
    private static let repaired = Data(
        "\"componentType\":5126,\"count\":51,\"type\":\"SCALAR\",\"min\":[0],\"max\":[10]}".utf8)
    private static func word(_ data:Data,_ offset:Int)->UInt32 {
        UInt32(data[offset]) | (UInt32(data[offset+1]) << 8) |
        (UInt32(data[offset+2]) << 16) | (UInt32(data[offset+3]) << 24)
    }
    private static func put(_ value:UInt32,at offset:Int,in data:inout Data) {
        for i in 0..<4 {data[offset+i]=UInt8((value >> (i*8)) & 0xff)}
    }

    @discardableResult
    static func repair(original source:URL,to destination:URL) throws -> UInt64 {
        let input=try FileHandle(forReadingFrom:source)
        defer {try? input.close()}
        let header=try input.read(upToCount:20) ?? Data()
        guard header.count==20,word(header,0)==0x46546c67,
              word(header,4)==2,word(header,16)==0x4e4f534a,
              word(header,8)>=28 else {throw RepairError.invalidGLB}
        let total=UInt64(word(header,8))
        let length=Int(word(header,12))
        guard length>0,UInt64(length)+28<=total,
              length<32*1024*1024 else {throw RepairError.invalidLayout}
        let json=try input.read(upToCount:length) ?? Data()
        guard json.count==length else {throw RepairError.invalidLayout}
        guard let matched=json.range(of:original) else {
            throw RepairError.mismatchedSource
        }
        guard json.range(of:original,in:matched.upperBound..<json.endIndex)==nil else {
            throw RepairError.duplicateRecord
        }
        var corrected=json
        corrected.replaceSubrange(matched,with:repaired)
        guard corrected.count==json.count+4,corrected.count%4==0,
              total+4<=UInt64(UInt32.max) else {throw RepairError.invalidLayout}
        let binHeader=try input.read(upToCount:8) ?? Data()
        guard binHeader.count==8,word(binHeader,4)==0x004e4942,
              UInt64(word(binHeader,0))+UInt64(length)+28==total else {
            throw RepairError.invalidLayout
        }

        guard FileManager.default.createFile(atPath:destination.path,contents:nil) else {
            throw RepairError.invalidLayout
        }
        let output=try FileHandle(forWritingTo:destination)
        defer {try? output.close()}
        var correctedHeader=header
        put(UInt32(total+4),at:8,in:&correctedHeader)
        put(UInt32(corrected.count),at:12,in:&correctedHeader)
        try output.write(contentsOf:correctedHeader)
        try output.write(contentsOf:corrected)
        try output.write(contentsOf:binHeader)
        var remaining=UInt64(word(binHeader,0))
        while remaining>0 {
            let size=Int(min(remaining,1_048_576))
            guard let chunk=try input.read(upToCount:size),!chunk.isEmpty else {
                throw RepairError.invalidLayout
            }
            try output.write(contentsOf:chunk)
            remaining-=UInt64(chunk.count)
        }
        guard (try input.read(upToCount:1) ?? Data()).isEmpty else {
            throw RepairError.invalidLayout
        }
        return total+4
    }
}
