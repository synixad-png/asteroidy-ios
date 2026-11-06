import Foundation

/// Byte-for-byte map decoding and SurfaceRadius from Windows v568
/// `Carbonis277.cs` lines 43–46 and 56–65. This is a terrain-query primitive,
/// not a ship collider, flight controller, or completed mission.
struct CarbonisSurface277 {
    static let width = 512
    static let height = 256
    static let byteCount = 8 + width * height * MemoryLayout<Float>.size

    private let heights: [Float]

    init?(data: Data) {
        guard data.count == Self.byteCount else { return nil }
        var samples: [Float] = []
        samples.reserveCapacity(Self.width * Self.height)
        let valid = data.withUnsafeBytes { raw -> Bool in
            func int32(_ offset: Int) -> Int {
                Int(Int32(bitPattern: UInt32(littleEndian:
                    raw.loadUnaligned(fromByteOffset: offset, as: UInt32.self))))
            }
            guard int32(0) == Self.width, int32(4) == Self.height else {
                return false
            }
            for index in 0..<(Self.width * Self.height) {
                let bits = UInt32(littleEndian:
                    raw.loadUnaligned(fromByteOffset: 8 + index * 4, as: UInt32.self))
                let value = Float(bitPattern: bits)
                guard value.isFinite else { return false }
                samples.append(value)
            }
            return true
        }
        guard valid else { return nil }
        heights = samples
    }

    /// Original Carbonis277.SurfaceRadius(x, y, z): longitude wraps at
    /// the seam, latitude clamps at both poles, bilinear sample uses
    /// half-texel offsets. Units are original C279 normalized radii.
    func surfaceRadius(x: Float, y: Float, z: Float) -> Float {
        let length = sqrt(x*x + y*y + z*z)
        if length < 1e-7 { return 1 }
        let lon = atan2(z, x)
        let lat = asin(max(-1, min(1, y / length)))
        let u = (lon + Float.pi) / (Float.pi * 2) * Float(Self.width) - 0.5
        let v = (lat + Float.pi / 2) / Float.pi * Float(Self.height) - 0.5
        let ix = Int(floor(u)), iy = Int(floor(v))
        let a = u - Float(ix), b = v - Float(iy)
        let x0 = ((ix % Self.width) + Self.width) % Self.width
        let x1 = (x0 + 1) % Self.width
        let y0 = max(0, min(Self.height - 1, iy))
        let y1 = max(0, min(Self.height - 1, iy + 1))
        let r00 = heights[y0 * Self.width + x0]
        let r10 = heights[y0 * Self.width + x1]
        let r01 = heights[y1 * Self.width + x0]
        let r11 = heights[y1 * Self.width + x1]
        return (r00 + (r10 - r00) * a) * (1 - b)
             + (r01 + (r11 - r01) * a) * b
    }
}
