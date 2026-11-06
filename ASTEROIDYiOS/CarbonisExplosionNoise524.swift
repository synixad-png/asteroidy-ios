import Foundation

/// Windows/src/Explosion524.cs:147-153, exact 262144-byte 64³ R8
/// texture with C# uint xorshift32 seed 0x47D6A2C3. Generated once
/// for all player/enemy/asteroid volume detonations, not a stock texture.
enum CarbonisExplosionNoise524 {
    static let dimension=64
    static let sampleCount=dimension*dimension*dimension
    static func originalBytes()->[UInt8] {
        var bytes=[UInt8](repeating:0,count:sampleCount)
        var value:UInt32=0x47D6A2C3
        for i in bytes.indices {
            value ^= value << 13
            value ^= value >> 17
            value ^= value << 5
            bytes[i]=UInt8(truncatingIfNeeded:value)
        }
        return bytes
    }
    // Source values verified against original .NET unchecked uint
    // arithmetic. Full SHA256 expected:
    // c871908c11577720bcb4e9af0dd3549d09cb03096c14cb4f7ebfce97f65051a2
}
