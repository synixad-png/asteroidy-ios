import Foundation

/// Exact, non-combat PC v602 HomeFlight291 state transition using the
/// existing iOS Sphere67 geodesic frame and FlightDynamics298 implementation.
/// Source: Windows/src/HomeFlight291.cs, SphereCombat67.cs,
/// FlightDynamics298.cs, Campaign37.cs and Physics68.cs.
///
/// A working flight state is NOT an orbital scene: rendering, native touch
/// routing, belt collisions, projectiles and docking need independent work.
struct PC602HomeFlight291 {
    enum SourceError: Error {
        case invalidEquipment, missingSourceGeometry, invalidInput
    }

    enum Craft: Int, CaseIterable {
        case kestrel=0, vanguard=1, bastion=2
        case vanguardX=3, titan=4, mammoth=5
    }

    struct Equipment {
        let craft:Craft
        let engineLevel:Int
        let thrusterRank:Int
        let stabilizerLevel:Int
        let miningDetached:Bool

        init?(craft:Craft, engineLevel:Int=0, thrusterRank:Int=0,
              stabilizerLevel:Int=0, miningDetached:Bool=false) {
            guard engineLevel>=0,thrusterRank>=0,stabilizerLevel>=0 else{return nil}
            self.craft=craft;self.engineLevel=engineLevel
            self.thrusterRank=thrusterRank;self.stabilizerLevel=stabilizerLevel
            self.miningDetached=miningDetached && craft == .mammoth
        }

        // Campaign37 Acceleration/TopSpeed/TurnSpeed and Physics68 ShipMass68.
        private var accelerationFactor:Float {
            switch craft {
            case .kestrel:return 1.18
            case .vanguard:return 1
            case .bastion:return 0.82
            case .vanguardX:return 0.79
            case .titan:return 0.67
            case .mammoth:return miningDetached ? 1.30 : 0.60
            }
        }
        private var topSpeedFactor:Float {
            switch craft {
            case .kestrel:return 1.12
            case .vanguard:return 1
            case .bastion:return 0.86
            case .vanguardX:return 0.93
            case .titan:return 0.76
            case .mammoth:return miningDetached ? 1.16 : 0.70
            }
        }
        private var turningFactor:Float {
            switch craft {
            case .kestrel:return 1.12
            case .vanguard:return 1
            case .bastion:return 0.84
            case .vanguardX:return 0.55
            case .titan:return 0.42
            case .mammoth:return miningDetached ? 1.35 : 0.35
            }
        }
        var mass:Float {
            switch craft {
            case .kestrel:return 2.4
            case .vanguard:return 3.4
            case .bastion:return 5
            case .vanguardX:return 6.2
            case .titan:return 10
            case .mammoth:return miningDetached ? 1.5 : 12.5
            }
        }
        var acceleration:Float {
            245*accelerationFactor
                * (1+Float(engineLevel)*0.06)
                * (1+Float(thrusterRank)*0.045)
        }
        var topSpeed:Float {
            390*topSpeedFactor
                * (1+Float(engineLevel)*0.035)
                * (1+Float(thrusterRank)*0.025)
        }
        var surfaceSpeed:Float {topSpeed*0.40}
        var turnSpeed:Float {
            3.8*turningFactor*(1+Float(stabilizerLevel)*0.04)
        }
        var flightConfiguration:FlightDynamics556.Configuration {
            let massFactor=sqrt(3.4/mass)
            var c=FlightDynamics556.Configuration()
            c.control=(1+Float(stabilizerLevel)*0.12)
                * max(0.55,min(1.6,acceleration/245))*massFactor
            c.coastMassFactor=massFactor
            c.stabilizerLevel=Float(stabilizerLevel)
            c.cruiseSpeed=surfaceSpeed
            // Exact FlightDynamics298 response for each craft family.
            switch craft {
            case .vanguardX:
                c.coastRateMultiplier=0.75
                c.visualTurnRate=2.5
                c.visualResponse=3.5
                c.bankBuildRate=6.3*0.70
                c.bankRecoveryRate=3.8*0.70
                c.pitchResponse=3.3
            case .titan:
                c.coastRateMultiplier=0.57
                c.visualTurnRate=1.9
                c.visualResponse=2.4
                c.bankBuildRate=6.3*0.50
                c.bankRecoveryRate=3.8*0.50
                c.pitchResponse=2.5
            case .mammoth:
                c.coastRateMultiplier=miningDetached ? 1.25 : 0.48
                c.visualTurnRate=miningDetached ? 7.6 : 1.45
                c.visualResponse=miningDetached ? 8.0 : 1.95
                c.bankBuildRate=6.3*(miningDetached ? 1.1 : 0.42)
                c.bankRecoveryRate=3.8*(miningDetached ? 1.1 : 0.42)
                c.pitchResponse=miningDetached ? 6.2 : 2.0
            case .kestrel,.vanguard,.bastion:
                break
            }
            return c
        }
    }

    struct Input {
        var move=Vec2(x:0,y:0)
        var aim=Vec2(x:0,y:0)
        var padAimActive=false
        var keyboardMovement=false
    }

    let home:PC602NewHome290
    private(set) var dockPosition:SIMD3<Float>
    private(set) var equipment:Equipment
    private(set) var flight=SphereFlight67()
    private(set) var orbitPosition=SIMD3<Float>(repeating:0)
    private(set) var orbitForward=SIMD3<Float>(repeating:0)
    private(set) var orbitRight=SIMD3<Float>(repeating:0)
    private(set) var orbitVelocity=SIMD3<Float>(repeating:0)
    private(set) var orbitCamera=SIMD3<Float>(repeating:0)
    private(set) var orbitSpeed:Float=0
    private(set) var orbitBank:Float=0
    private(set) var orbitTime:Float=0
    private(set) var orbitDistance:Float=0
    private(set) var dockDistance:Float=0
    private(set) var thrusting=false
    private(set) var sideThrust:Float=0
    private(set) var target:Int=1
    private(set) var completedMask:Int=0
    private var padHeadingLocked=false

    private static let worldUp=SphereVector3(x:0,y:1,z:0)
    private static func world(_ p:SphereVector3)->SIMD3<Float> {
        SIMD3(p.x,p.y,p.z)
    }
    private static func source(_ p:SIMD3<Float>)->SphereVector3 {
        SphereVector3(x:p.x,y:p.y,z:p.z)
    }
    private static func length(_ p:SIMD3<Float>)->Float {
        sqrt(p.x*p.x+p.y*p.y+p.z*p.z)
    }
    private static func finite(_ p:Vec2)->Bool {
        p.x.isFinite && p.y.isFinite
    }

    static func completed(_ level:Int,mask:Int)->Bool {
        (1...26).contains(level) && (mask & (1 << (level-1))) != 0
    }
    static func unlocked(_ level:Int,mask:Int)->Bool {
        guard (1...26).contains(level) else{return false}
        return level==1 || completed(level,mask:mask) ||
            completed(level==26 ? 24 : level-1,mask:mask)
    }

    init(home:PC602NewHome290,equipment:Equipment,
         completedMask:Int=0) throws {
        self.home=home
        guard let originalWreck=home.wreckPosition() else {
            throw SourceError.missingSourceGeometry
        }
        dockPosition=originalWreck
        self.equipment=equipment
        self.completedMask=completedMask & ((1 << 26)-1)
        target=(1...26).first {
            Self.unlocked($0,mask:self.completedMask) &&
                !Self.completed($0,mask:self.completedMask)
        } ?? 1
        try resetToTarget()
    }

    /// Orbit50.EnterOrbit50(reset:true) followed by InitializeHomeFlight291.
    mutating func resetToTarget() throws {
        guard let beacon=home.beacon(target) else {
            throw SourceError.missingSourceGeometry
        }
        let n=Self.source(beacon).normalized
        let tangent=SphereVector3.cross(Self.worldUp,n).normalized
        let startDirection=(n-tangent*0.20).normalized
        guard let start=home.spawnPosition(Self.world(startDirection)),
              let physicalHeight=home.surface(Self.world(startDirection))
        else {throw SourceError.missingSourceGeometry}
        let spawnNormal=Self.source(start).normalized
        let sourceForward=tangent * -1
        // NewHome290.InitializeHomeFlight291 discards old orbit altitude and
        // restores exactly terrain +12 m at the canonical Sphere67 point.
        orbitPosition=Self.world(spawnNormal)*(physicalHeight+12)
        flight=SphereFlight67()
        flight.position=Sphere67.coordinates(spawnNormal)
        let projection=sourceForward - spawnNormal * SphereVector3.dot(sourceForward,spawnNormal)
        let tangentForward=Sphere67.components(flight.position,projection)
        flight.heading=tangentForward.lengthSquared>0.0001
            ? atan2(tangentForward.y,tangentForward.x) : -Float.pi/2
        flight.flight.configuration=equipment.flightConfiguration
        flight.camera=SphereCamera67(at:flight.position)
        let f=Sphere67.vector(flight.position,Vec2(
            x:cos(flight.heading),y:sin(flight.heading))).normalized
        orbitForward=Self.world(f)
        orbitRight=Self.world(SphereVector3.cross(f,spawnNormal).normalized)
        orbitCamera=Self.world(flight.camera.focus*400)
        orbitVelocity=SIMD3<Float>(repeating:0)
        orbitSpeed=0
        orbitBank=0
        thrusting=false;sideThrust=0;padHeadingLocked=false
        orbitDistance=home.distanceToSector(orbitPosition,level:target) ?? 0
        dockDistance=Self.length(orbitPosition-dockPosition)
    }

    /// Game.Campaign37.EngineLevel/StabilizerLevel/ThrusterRank97 are live
    /// properties on PC602; when a player purchases a level in H55, the
    /// source DirectMotion298 reads the new values on the next flight tick.
    /// Only Vanguard is currently usable in the iOS world, never silently
    /// substitute Vanguard for another selected ship.
    ///
    /// Keep position, velocity, heading, camera, elapsed time and projectile
    /// state unchanged; replace only the source FlightDynamics298 settings.
    @discardableResult
    mutating func adoptVanguardEquipment(_ next:Equipment)->Bool {
        guard (equipment.craft == .vanguard ||
               equipment.craft == .bastion),
              (next.craft == .vanguard || next.craft == .bastion),
              !next.miningDetached,
              (0...2).contains(next.engineLevel),
              (0...2).contains(next.thrusterRank),
              (0...2).contains(next.stabilizerLevel)
        else{return false}
        equipment=next
        flight.flight.configuration=next.flightConfiguration
        return true
    }

    /// SaveManager61.LoadSlot61: accept only its previously verified
    /// orbit vector, rebind the same Sphere67 pilot and reset velocity,
    /// camera inertia and nonpersistent projectiles. The PC source calls
    /// InitializeHomeFlight291 after assigning the saved world vectors.
    mutating func restoreOrbit61(
        position:SIMD3<Float>,forward:SIMD3<Float>,
        target savedTarget:Int,completedMask savedMask:Int) throws {
        guard (1...26).contains(savedTarget),
              Self.unlocked(savedTarget,mask:savedMask),
              [position.x,position.y,position.z,
               forward.x,forward.y,forward.z].allSatisfy({$0.isFinite}),
              Self.length(position)>100,Self.length(position)<1000,
              Self.length(forward)>0.9,Self.length(forward)<1.1
        else{throw SourceError.invalidInput}
        let storedForward=Self.source(forward)
        let n=Self.source(position).normalized
        guard let surface=home.surface(Self.world(n)) else {
            throw SourceError.missingSourceGeometry
        }
        completedMask=savedMask
        target=savedTarget
        orbitPosition=Self.world(n)*(surface+12)
        flight=SphereFlight67()
        flight.position=Sphere67.coordinates(n)
        let plane=storedForward-n*SphereVector3.dot(storedForward,n)
        let tangent=Sphere67.components(flight.position,plane)
        guard tangent.lengthSquared>0.01 else{throw SourceError.invalidInput}
        flight.heading=atan2(tangent.y,tangent.x)
        flight.flight.configuration=equipment.flightConfiguration
        flight.camera=SphereCamera67(at:flight.position)
        let f=Sphere67.vector(flight.position,Vec2(
            x:cos(flight.heading),y:sin(flight.heading))).normalized
        orbitForward=Self.world(f)
        orbitRight=Self.world(SphereVector3.cross(f,n).normalized)
        orbitCamera=Self.world(flight.camera.focus*400)
        orbitVelocity=SIMD3<Float>(repeating:0)
        orbitSpeed=0
        orbitBank=0
        orbitTime=0
        thrusting=false
        sideThrust=0
        padHeadingLocked=false
        guard let arc=home.distanceToSector(orbitPosition,level:target)
        else{throw SourceError.missingSourceGeometry}
        orbitDistance=arc
        dockDistance=Self.length(orbitPosition-dockPosition)
    }

    /// No fabricated mission successes. Only the real settlement updates
    /// this saved-mask snapshot and the source's next-target selection.
    mutating func applyCompletedMask(_ mask:Int) {
        completedMask=mask & ((1 << 26)-1)
        // Orbit50.EnterOrbit50(reset:false) advances a completed target
        // to the first unlocked unfinished mission, without fabricating a
        // reward, changing other campaign entries or changing ship position.
        if !Self.unlocked(target,mask:completedMask) || Self.completed(target,mask:completedMask) {
            if let next=(1...26).first(where:{
                Self.unlocked($0,mask:completedMask) &&
                    !Self.completed($0,mask:completedMask)
            }) {target=next}
            else if !Self.unlocked(target,mask:completedMask) {target=1}
        }
        orbitDistance=home.distanceToSector(orbitPosition,level:target) ?? 0
    }
    @discardableResult mutating func select(_ level:Int)->Bool {
        guard Self.unlocked(level,mask:completedMask) else{return false}
        target=level
        orbitDistance=home.distanceToSector(orbitPosition,level:level) ?? 0
        return true
    }
    mutating func cycleTarget() {
        for offset in 1...26 {
            let next=(target-1+offset)%26+1
            if Self.unlocked(next,mask:completedMask) {
                _=select(next)
                break
            }
        }
    }

    /// C# StepHomeFlight291: DirectFlight67 -> MoveShip67 ->
    /// UpdateSphereCamera67 -> world visual/docking state. Does not claim
    /// StepHomeWeaponTest292 or physical asteroid/dock collision is wired yet.
    mutating func step(_ raw:Input,dt frame:Float) throws {
        guard frame.isFinite,frame>=0,Self.finite(raw.move),
              Self.finite(raw.aim)
        else {throw SourceError.invalidInput}
        let dt=min(0.05,frame)
        orbitTime+=dt
        let magnitude=sqrt(raw.move.lengthSquared)
        let move=magnitude>1
            ? raw.move*(1/magnitude) : raw.move
        // PC DirectFlight67 retains the raw magnitude for exhaust power even
        // after normalizing diagonal movement to a unit screen vector.
        let length=magnitude
        // DirectMotion298: screen-projected controls, source cruise limit,
        // mass, upgrades, heavy-craft inertia and non-powered glide.
        let desired=flight.camera.screenVector(at:flight.position,
            screen:move)*equipment.surfaceSpeed
        let acceleration=flight.flight.motion(
            velocity:&flight.velocity,desired:desired,
            inputLength:length,dt:dt)

        let aimLength=sqrt(raw.aim.lengthSquared)
        if raw.padAimActive && aimLength>0.15 {
            padHeadingLocked=true
        } else if aimLength>0.15 || raw.keyboardMovement {
            padHeadingLocked=false
        }
        let direction:Vec2
        if aimLength>0.15 {
            direction=flight.camera.screenVector(
                at:flight.position,screen:raw.aim)
        } else if padHeadingLocked {
            direction=Vec2(x:cos(flight.heading),y:sin(flight.heading))
        } else if length>0.01 {
            direction=flight.camera.screenVector(
                at:flight.position,screen:move)
        } else {
            direction=Vec2(x:cos(flight.heading),y:sin(flight.heading))
        }
        if direction.lengthSquared>0.0001 {
            let desiredHeading=atan2(direction.y,direction.x)
            if equipment.craft == .vanguardX {
                // Source CustomShipType368: real shot axis turns gradually.
                let error=FlightDynamics556.wrapAngle(
                    desiredHeading-flight.heading)
                let maxStep=equipment.turnSpeed*0.71*dt
                let smooth=error*(1-exp(-dt*4.2))
                flight.heading=FlightDynamics556.wrapAngle(
                    flight.heading+max(-maxStep,min(maxStep,smooth)))
            } else {
                flight.heading=desiredHeading
            }
        }
        // The original DirectAttitude298 executes before MoveShip67, and
        // initialization keeps its first frame's angular velocity at zero.
        if !flight.flight.visualInitialized {
            flight.flight.visualHeading=flight.heading
            flight.flight.visualInitialized=true
        }
        flight.flight.attitude(angle:flight.heading,
            velocity:flight.velocity,acceleration:acceleration,dt:dt)
        let old=flight.position
        let previous=Sphere67.normal(old)
        let oldHeading=Sphere67.vector(old,Vec2(
            x:cos(flight.heading),y:sin(flight.heading)))
        flight.position=Sphere67.advance(old,
            velocity:&flight.velocity,dt:dt)
        let now=Sphere67.normal(flight.position)
        let moved=Sphere67.transport(oldHeading,from:previous,to:now)
        let components=Sphere67.components(flight.position,moved)
        flight.heading=atan2(components.y,components.x)
        flight.camera.update(target:flight.position,dt:dt)

        guard let h=home.surface(Self.world(now)) else {
            throw SourceError.missingSourceGeometry
        }
        orbitPosition=Self.world(now)*(h+12)
        orbitVelocity=Self.world(Sphere67.vector(
            flight.position,flight.velocity))
        orbitSpeed=sqrt(flight.velocity.lengthSquared)
        let forward=Sphere67.vector(flight.position,
            Vec2(x:cos(flight.heading),y:sin(flight.heading))).normalized
        orbitForward=Self.world(forward)
        orbitRight=Self.world(SphereVector3.cross(forward,now).normalized)
        orbitBank=flight.flight.visualBank*Float.pi/180
        orbitCamera=Self.world(flight.camera.focus*400)
        // Source explicitly uses original unsaturated MoveX67/Y67 here.
        thrusting=raw.move.lengthSquared>0.0016
        sideThrust=raw.move.x
        if !Self.unlocked(target,mask:completedMask) {
            target=(1...26).first {
                Self.unlocked($0,mask:completedMask) &&
                    !Self.completed($0,mask:completedMask)
            } ?? 1
        }
        guard let arc=home.distanceToSector(
            orbitPosition,level:target) else {
            throw SourceError.missingSourceGeometry
        }
        orbitDistance=arc
        let delta=orbitPosition-dockPosition
        dockDistance=Self.length(delta)
    }

    /// Exact PC v602 Hub90.CanDock90 gate. H55 transition remains owned by
    /// the existing hub controller; proximity alone never enters the hangar.
    struct DockContext {
        var planetHub:Bool
        var orbitMode:Bool
        var sceneBusy:Bool=false
        var talentOpen:Bool=false
    }
    static func canDock90(distance:Float,miningDetached:Bool,
                          context:DockContext)->Bool {
        distance.isFinite && distance>=0 && !miningDetached &&
        context.planetHub && context.orbitMode && !context.sceneBusy &&
        distance<=PC602NewHome290.dockRadius295 && !context.talentOpen
    }
    func canDock90(context:DockContext)->Bool {
        Self.canDock90(distance:dockDistance,
                       miningDetached:equipment.miningDetached,
                       context:context)
    }

    var entryMission:Int {
        if Self.unlocked(target,mask:completedMask) &&
            home.isInMissionArea(orbitPosition,level:target) {
            return target
        }
        for level in 1...26 {
            if Self.unlocked(level,mask:completedMask) &&
                home.isInMissionArea(orbitPosition,level:level) {
                return level
            }
        }
        return 0
    }
}
