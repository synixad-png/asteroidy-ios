import Foundation

/// PC v580 NpcWalkCycleMeters527, NpcBlendTime525, NpcBindPhysics528 and
/// NpcSecondaryPhysics528. Works on the 80 actual NPC525 glTF joint poses,
/// independent from SceneKit and the H08 collision/route simulation.
final class H55NpcMotion580 {
    typealias Pose=H55NpcTracks580.Pose
    typealias Q=H55NpcTracks580.Quaternion
    static let walkCycleMeters:Float=4.01
    static let bodyMass:Float=110
    static let blendSeconds:Float=0.25
    static let landingSpring:Float=18000
    static let landingDamping:Float=2050
    struct Link {
        let bone:Int
        let mass:Float,stiffness:Float,cap:Float
        var q:Q = .identity
        var angularVelocity=SIMD3<Float>.zero
    }
    let rig:H55NpcTracks580.Rig
    private(set) var poses:[Pose]
    private(set) var playingWalk=false
    private(set) var clipTime:Float=0
    private(set) var gaitTime:Float=0
    private(set) var blendElapsed:Float=0.25
    private(set) var links:[Link]
    private(set) var pelvis:Int
    private let spineLow:Int,spineHigh:Int
    private var previousPoses:[Pose]
    private var initiated=false
    private var idleClock:Float=0
    private var lateralLock:Float=0
    private var leanPitch:Float=0,leanSide:Float=0,previousSpeed:Float=0
    private(set) var landingDrop:Float=0,landingVelocity:Float=0

    init(rig:H55NpcTracks580.Rig)throws {
        self.rig=rig
        poses=rig.bones.map{$0.base}
        previousPoses=poses
        let suffixes=["_pelvis","_spine_01","_spine_03","_spine_05","_head",
                      "_upperarm_l","_lowerarm_l","_upperarm_r","_lowerarm_r",
                      "_thigh_l","_calf_l","_foot_l","_thigh_r","_calf_r","_foot_r"]
        let masses:[Float]=[22,12,10,8,6,5,3,5,3,11,6,1,11,6,1]
        let springs:[Float]=[3000,1800,1500,1200,1200,520,330,520,330,4300,2300,1300,4300,2300,1300]
        let caps:[Float]=[0.032,0.062,0.062,0.07,0.095,0.15,0.15,0.15,0.15,0.028,0.027,0.010,0.028,0.027,0.010]
        var l=[Link](),sum:Float=0
        for i in suffixes.indices {
            guard let bone=rig.named(suffixes[i]) else{throw H55NpcTracks580.Invalid.bone}
            l.append(Link(bone:bone,mass:masses[i],stiffness:springs[i],cap:caps[i]))
            sum+=masses[i]
        }
        guard abs(sum-Self.bodyMass)<0.001,
              let pelvis=rig.named("_pelvis"),
              let low=rig.named("_spine_01"),let high=rig.named("_spine_03") else {
            throw H55NpcTracks580.Invalid.bone
        }
        self.links=l;self.pelvis=pelvis;self.spineLow=low;self.spineHigh=high
    }
    private func clamp(_ x:Float,_ a:Float,_ b:Float)->Float {max(a,min(b,x))}
    private func length(_ v:SIMD3<Float>)->Float {sqrt(v.x*v.x+v.y*v.y+v.z*v.z)}
    private func turn(_ a:Q,_ b:Q,_ fraction:Float)->Q {Q.slerp(a,b,fraction)}
    private func tilted(_ q:Q,_ pitch:Float,_ roll:Float)->Q {
        let hp=pitch*0.5,hr=roll*0.5
        let tilt=Q(x:sin(hp)*cos(hr),y:-sin(hp)*sin(hr),
                   z:cos(hp)*sin(hr),w:cos(hp)*cos(hr))
        return (q*tilt).normalized()
    }
    /// Never zero distance at an idle/walk switch: PC v527 preserves gait phase.
    @discardableResult
    func step(dt raw:Float,moving:Bool,distance:Float,speed measuredSpeed:Float,
              yawRate:Float)->[Pose] {
        let dt=clamp(raw,0,0.07)
        if !initiated {initiated=true;playingWalk=false}
        if moving != playingWalk {
            previousPoses=poses
            playingWalk=moving
            idleClock=0
            blendElapsed=0
        }
        idleClock+=dt
        let duration=moving ? rig.walk.duration : rig.idle.duration
        if moving {
            let totalDistance=max(0,distance)
            // 2.375 seconds per 4.01 real metres, not wall-clock animation.
            gaitTime=(totalDistance/Self.walkCycleMeters*rig.walk.duration)
                        .truncatingRemainder(dividingBy:rig.walk.duration)
            clipTime=gaitTime
        } else {
            clipTime=idleClock.truncatingRemainder(dividingBy:max(0.01,duration))
        }
        poses=rig.sample(walk:moving,time:clipTime)
        blendElapsed=min(Self.blendSeconds,blendElapsed+dt)
        if blendElapsed < Self.blendSeconds {
            let fraction=blendElapsed/Self.blendSeconds
            let smooth=fraction*fraction*(3-2*fraction)
            for i in poses.indices {poses[i]=Pose.interpolate(previousPoses[i],poses[i],smooth)}
        }
        // PC v541/v542: local X fore/aft, LOCAL Y is world side in this rig.
        let target:Float=moving ? 1 : 0
        lateralLock+=(target-lateralLock)*(1-exp(-dt*11))
        let neutral=rig.bones[pelvis].base.position
        let source=poses[pelvis].position
        poses[pelvis].position.x=neutral.x+(source.x-neutral.x)*(1-lateralLock)
        poses[pelvis].position.y=neutral.y+(source.y-neutral.y)*(1-lateralLock)
        // Preserve source local Z=world vertical foot lift.

        let acceleration=dt>0.0001 ? (measuredSpeed-previousSpeed)/dt : 0
        previousSpeed=measuredSpeed
        let pitchTarget=clamp(-acceleration*0.023,-0.052,0.052)
        let sideTarget=clamp(-yawRate*measuredSpeed*0.010,-0.024,0.024)
        let alpha=1-exp(-dt*5.8)
        leanPitch+=(pitchTarget-leanPitch)*alpha
        leanSide+=(sideTarget-leanSide)*alpha
        poses[spineLow].rotation=tilted(poses[spineLow].rotation,leanPitch*0.58,leanSide*0.58)
        poses[spineHigh].rotation=tilted(poses[spineHigh].rotation,leanPitch*0.42,leanSide*0.42)
        if !linksInitialized {
            for i in links.indices {links[i].q=poses[links[i].bone].rotation}
            linksInitialized=true
            return poses
        }
        let micro=max(1,Int(ceil(dt/(1.0/120.0))))
        let h=dt/Float(micro)
        for i in links.indices {
            var link=links[i]
            let target=poses[link.bone].rotation
            let damping=2*sqrt(link.stiffness*link.mass)*1.04
            for _ in 0..<micro {
                var error=target*link.q.conjugate()
                if error.w<0 {error=Q(x:-error.x,y:-error.y,z:-error.z,w:-error.w)}
                let xyz=SIMD3(error.x,error.y,error.z)
                let len=length(xyz)
                let factor:Float=len>0.00001 ? 2*atan2(len,error.w)/len : 2
                let acceleration=(xyz*link.stiffness*factor-link.angularVelocity*damping)/link.mass
                link.angularVelocity += acceleration*h
                for k in 0..<3 {link.angularVelocity[k]=clamp(link.angularVelocity[k],-7,7)}
                let mag=length(link.angularVelocity)
                if mag>0.000001 {
                    let s=sin(mag*h*0.5)/mag
                    let dq=Q(x:link.angularVelocity.x*s,y:link.angularVelocity.y*s,
                             z:link.angularVelocity.z*s,w:cos(mag*h*0.5))
                    link.q=(dq*link.q).normalized()
                }
            }
            let dot=abs((link.q.x*target.x + link.q.y*target.y) +
                        (link.q.z*target.z + link.q.w*target.w))
            let error=2*acos(clamp(dot,0,1))
            if error>link.cap {
                link.q=turn(link.q,target,(error-link.cap)/error)
                link.angularVelocity *= 0.55
            }
            poses[link.bone].rotation=link.q
            links[i]=link
        }
        return poses
    }
    private var linksInitialized=false
    // PC v525 snapshots the FINAL rig pose after foot IK for the next
    // 0.25s transition. Source animation track data remain immutable.
    func recordSolvedPose(_ resolved:[Pose]) {
        guard resolved.count==poses.count else{return}
        poses=resolved
    }

    /// Source v538 110 kg damped landing, 120Hz microsteps, 17 mm reach cap.
    func land(dt raw:Float,newContacts:Int,speed:Float)->Float {
        let dt=clamp(raw,0,0.07)
        if newContacts>0 {
            let impulse=min(0.155,max(0,speed)*0.155)
            landingVelocity=min(0.24,landingVelocity+impulse*Float(newContacts))
        }
        let micro=max(1,Int(ceil(dt/(1.0/120.0))))
        let h=dt/Float(micro)
        for _ in 0..<micro {
            let force = -Self.landingSpring*landingDrop-Self.landingDamping*landingVelocity
            landingVelocity+=force/Self.bodyMass*h
            landingDrop+=landingVelocity*h
            if landingDrop<0 {landingDrop=0;landingVelocity=max(0,landingVelocity)}
            if landingDrop>0.017 {landingDrop=0.017;landingVelocity=min(0,landingVelocity)}
        }
        return landingDrop
    }
}
