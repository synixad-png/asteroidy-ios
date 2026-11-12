import Foundation

/// Exact geometry from Windows/src/GpuPlanet.cs AtmosphereVertex/DrawAtmosphere47
/// and Windows/src/GpuPlanetAnimation.cs GlowVertex/DrawPlanetGlow, v568.
enum SourcePlanetAtmosphere568 {
    static let carbonisTint:(Float,Float,Float)=(236/255,78/255,25/255)
    static let homeTint:(Float,Float,Float)=(145/255,188/255,232/255)
    static let radius:Float=1.34
    static let atmosphereRings=24
    static let segments=96
    static let glowRings=12
    static let atmosphereVertexStride=7
    static let glowVertexStride=6
    static func haze(_ r:Float)->Float {
        let q=(r-1.055)/0.125
        let edge=max(0,min(1,(radius-r)/0.18))
        return (0.058+0.33*exp(-q*q))*edge*edge*(3-2*edge)
    }
    static func glowAlpha(_ r:Float,_ angle:Float)->Float {
        let q=(r-1.066)/0.074
        return exp(-q*q)*0.40*(0.78+0.22*cos(angle+2.1))
    }
    static func atmosphere(tint:(Float,Float,Float))->[Float] {
        var result=[Float]()
        result.reserveCapacity(atmosphereRings*segments*6*atmosphereVertexStride)
        func vertex(_ r:Float,_ angle:Float) {
            let z=sqrt(max(0,radius*radius-r*r))
            result.append(contentsOf:[r*cos(angle),r*sin(angle),z,
                                      tint.0,tint.1,tint.2,haze(r)])
        }
        for ring in 0..<atmosphereRings {
            for i in 0..<segments {
                let r=Float(ring)*radius/Float(atmosphereRings)
                let s=Float(ring+1)*radius/Float(atmosphereRings)
                let a=Float(i)*Float.pi/48
                let b=Float(i+1)*Float.pi/48
                vertex(r,a);vertex(s,a);vertex(s,b)
                vertex(r,a);vertex(s,b);vertex(r,b)
            }
        }
        return result
    }
    // Original GL blending: additive ONE/ONE with preweighted vertex RGB.
    static func glow(tint:(Float,Float,Float))->[Float] {
        var result=[Float]()
        result.reserveCapacity(glowRings*segments*6*glowVertexStride)
        func vertex(_ r:Float,_ angle:Float) {
            let q=(r-1.066)/0.074
            let alpha=exp(-q*q)*0.40
            let light:Float=0.78+0.22*cos(angle+2.1)
            result.append(contentsOf:[r*cos(angle),r*sin(angle),
                                      tint.0*alpha*light,tint.1*alpha*light,
                                      tint.2*alpha*light,alpha])
        }
        for ring in 0..<glowRings {
            for i in 0..<segments {
                let r:Float=0.94+Float(ring)*0.0275
                let s=r+0.0275
                let a=Float(i)*Float.pi/48
                let b=Float(i+1)*Float.pi/48
                vertex(r,a);vertex(r,b);vertex(s,b)
                vertex(r,a);vertex(s,b);vertex(s,a)
            }
        }
        return result
    }
}

/// Windows/src/Menu139.cs, source menu ids #2 (Glow / POSTPROCES),
/// #55/#56/#57 (PLANETY: sunlight, speed, night brightness).
struct SourcePlanetGraphicsSettings568:Codable,Equatable {
    static let key="ASTEROIDY.v568.PlanetAtmosphere47.Glow256.Light436.Night437"
    /// Live settings revision: the Metal renderer reads an integer every
    /// frame and decodes the profile only when the original options change.
    static let revisionKey=key+".orbit-options-revision"
    var glowEnabled=true
    var planetLightEnabled=true
    var planetLightSpeed=100
    var planetNightBrightness=160
    /// Renderer.cs options 12/13, both enabled by default in original PC602.
    var nebulaEnabled=true
    var solarRaysEnabled=true

    init() {}

    /// Existing iOS profiles predate source options #12/#13.
    /// Restore those profiles without losing #2 / #55–57 values.
    private enum CodingKeys:String,CodingKey {
        case glowEnabled,planetLightEnabled,planetLightSpeed,
             planetNightBrightness,nebulaEnabled,solarRaysEnabled
    }
    init(from decoder:Decoder) throws {
        let data=try decoder.container(keyedBy:CodingKeys.self)
        glowEnabled=try data.decodeIfPresent(Bool.self,
                                             forKey:.glowEnabled) ?? true
        planetLightEnabled=try data.decodeIfPresent(Bool.self,
                                                    forKey:.planetLightEnabled) ?? true
        planetLightSpeed=try data.decodeIfPresent(Int.self,
                                                  forKey:.planetLightSpeed) ?? 100
        planetNightBrightness=try data.decodeIfPresent(Int.self,
                                                       forKey:.planetNightBrightness) ?? 160
        nebulaEnabled=try data.decodeIfPresent(Bool.self,
                                               forKey:.nebulaEnabled) ?? true
        solarRaysEnabled=try data.decodeIfPresent(Bool.self,
                                                  forKey:.solarRaysEnabled) ?? true
        clampAll()
    }

    mutating func clampAll() {
        planetLightSpeed=max(0,min(400,Int((Double(planetLightSpeed)/5).rounded())*5))
        planetNightBrightness=max(0,min(400,Int((Double(planetNightBrightness)/5).rounded())*5))
    }
    func save(_ defaults:UserDefaults = .standard) {
        var value=self;value.clampAll()
        if let data=try? JSONEncoder().encode(value) {
            defaults.set(data,forKey:Self.key)
            defaults.set(defaults.integer(forKey:Self.revisionKey) &+ 1,
                         forKey:Self.revisionKey)
        }
    }
    static func load(_ defaults:UserDefaults = .standard)->Self {
        guard let data=defaults.data(forKey:key),
              var setting=try? JSONDecoder().decode(Self.self,from:data)
        else {return Self()}
        setting.clampAll()
        return setting
    }
    func sourceSun(_ elapsed:Float)->(Float,Float,Float,Float) {
        let angle:Float=2.3+max(0,elapsed)*0.025*Float(planetLightSpeed)/100
        return (cos(angle)*0.9,0.4,sin(angle)*0.9,
                planetLightEnabled ? Float(planetNightBrightness)/400 : 1)
    }
}
