import Foundation

/// Exact original PC v602 HomeFlight291.cs:144-158 fighter transform,
/// composed from the SAME live Sphere67/DirectFlight298 state as orbital
/// movement. No fake flight camera, no substitute ship or saved-location guess.
/// Model type 1 (Vanguard431) is the only original orbit fighter with
/// SHA-verified geometry+skin already present in the iOS asset bundle.
/// Do NOT silently show it for types 0 or 2–5.
enum PC602HomeShipPose291 {
    // Game.ShipContactRadius=10*1.12; GpuSphere67.WorldUnitScale=
    // (100*GpuPlanetGltf463.HomeOuterRadius523+15)/(Game.H/Game.PI).
    // HomeScene291 scales 0.65*1.35 and then OrbitShipScale472.
    static let sourceContactRadius:Float=11.2
    static let sourceHomeWorldOuterRadius:Float=144.19674
    static let originalWorldScale:Float=
        (sourceHomeWorldOuterRadius+15)/(720/Float.pi)
    static let sourceShipScale:Float=
        sourceContactRadius*originalWorldScale*0.65*1.35

    struct Pose {
        // OpenGL source sphereMatrix67: unrotated 4x4 column-major basis.
        // Source Y is the craft's forward/nose, Z is dorsal.
        let basis:[Float]
        let bankDegrees:Float
        let pitchDegrees:Float
        let orbitScale:Float
    }

    /// Reproduces HomeScene291 with the real current visual heading,
    /// normal, terrain altitude, bank and pitch. Not the raw combat angle.
    static func vanguard(_ flight:PC602HomeFlight291,
                         orbitScale:Float=1)->Pose? {
        guard flight.equipment.craft == .vanguard,
              orbitScale.isFinite,orbitScale>0,
              flight.flight.flight.visualBank.isFinite,
              flight.flight.flight.visualPitch.isFinite
        else {return nil}
        let source=flight.flight.position
        let normal=Sphere67.normal(source)
        let visual=flight.flight.flight.visualInitialized
            ? flight.flight.flight.visualHeading : flight.flight.heading
        let heading=Sphere67.vector(source,
            Vec2(x:cos(visual),y:sin(visual))).normalized
        let right=SphereVector3.cross(heading,normal).normalized
        guard heading.length>0.999, right.length>0.999,
              let altitude=flight.home.surface(
                SIMD3(normal.x,normal.y,normal.z))
        else {return nil}
        let body=normal*(altitude+12)
        let size=sourceShipScale*orbitScale
        let matrix:[Float]=[
            right.x*size,right.y*size,right.z*size,0,
            heading.x*size,heading.y*size,heading.z*size,0,
            normal.x*size,normal.y*size,normal.z*size,0,
            body.x,body.y,body.z,1
        ]
        guard matrix.allSatisfy({$0.isFinite}) else{return nil}
        return Pose(basis:matrix,
                    bankDegrees:flight.flight.flight.visualBank,
                    pitchDegrees:flight.flight.flight.visualPitch,
                    orbitScale:orbitScale)
    }
}
