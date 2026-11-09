import Foundation
import SceneKit
import simd

/// H09: bind the 80 genuine NPC525 GLB nodes to PC v580's manually sampled
/// mocap, 15-joint 110kg secondary dynamics and grounded two-bone Foot IK.
/// The outer H08 root is NEVER moved by this animator; doors and input untouched.
/// Must run only on H55SceneModel580's main display-link before SceneKit draws.
final class H55NpcSceneAnimator580 {
    typealias Q=H55NpcTracks580.Quaternion
    let motion:H55NpcMotion580
    let bones:[SCNNode]
    let floor:H55SpatialSupport580
    let originalFoot:Float
    let heading:Float
    private let pelvis:SCNNode
    private var feet:[Contact]
    private var supportX:Float=0,supportZ:Float=0
    private var previousYaw:Float=0
    private(set) var solvedCount=0
    private(set) var lockCount=0
    private(set) var maxError:Float=0
    private(set) var maxCorrection:Float=0

    private struct Contact {
        let thigh:SCNNode,calf:SCNNode,ankle:SCNNode,ball:SCNNode
        var planted=false,waitForLift=false
        var weight:Float=0
        var anchor=SIMD3<Float>.zero
        var lockCount=0,releaseCount=0
    }
    enum Invalid:Error {case skeleton,duplicate,footChain}

    init(rig:H55NpcTracks580.Rig,allNodes:[SCNNode],
         collision:H55SpatialSupport580,foot:Float,anatomicalHeading:Float)throws {
        motion=try H55NpcMotion580(rig:rig)
        floor=collision;originalFoot=foot;heading=anatomicalHeading
        let byName=Dictionary(grouping:allNodes.compactMap {n in
            n.name.map {($0,n)}
        },by:{$0.0})
        var found=[SCNNode]()
        for bone in rig.bones {
            guard let matches=byName[bone.name],matches.count==1 else {throw Invalid.duplicate}
            found.append(matches[0].1)
        }
        bones=found
        guard let pelvisIndex=rig.named("_pelvis") else{throw Invalid.skeleton}
        pelvis=found[pelvisIndex]
        var contacts=[Contact]()
        for side in ["_l","_r"] {
            guard let a=rig.named("_thigh"+side),let b=rig.named("_calf"+side),
                  let c=rig.named("_foot"+side),let d=rig.named("_ball"+side) else{
                throw Invalid.footChain
            }
            let thigh=found[a],calf=found[b],ankle=found[c],ball=found[d]
            guard calf.parent === thigh,ankle.parent === calf,
                  ball.parent === ankle else{throw Invalid.footChain}
            contacts.append(Contact(thigh:thigh,calf:calf,ankle:ankle,ball:ball))
        }
        feet=contacts
    }
    private func length(_ v:SIMD3<Float>)->Float {sqrt(v.x*v.x+v.y*v.y+v.z*v.z)}
    private func dot(_ a:SIMD3<Float>,_ b:SIMD3<Float>)->Float {
        a.x*b.x+a.y*b.y+a.z*b.z
    }
    private func cross(_ a:SIMD3<Float>,_ b:SIMD3<Float>)->SIMD3<Float> {
        SIMD3(a.y*b.z-a.z*b.y,a.z*b.x-a.x*b.z,a.x*b.y-a.y*b.x)
    }
    private func clamp(_ x:Float,_ a:Float,_ b:Float)->Float {max(a,min(b,x))}
    private func smooth(_ x:Float)->Float {let y=clamp(x,0,1);return y*y*(3-2*y)}
    private func basis(_ world:simd_float4x4,_ i:Int)->SIMD3<Float> {
        let c=world[i];return SIMD3(c.x,c.y,c.z)
    }
    private func parentLocal(_ world:SIMD3<Float>,_ parent:SCNNode)->SIMD3<Float> {
        // PC v529: world-axis correction projected into PARENT local basis,
        // normalizing separately by each actual imported scale (~2.84).
        let m=parent.simdWorldTransform
        let x=basis(m,0),y=basis(m,1),z=basis(m,2)
        let sx=max(0.0001,dot(x,x)),sy=max(0.0001,dot(y,y)),sz=max(0.0001,dot(z,z))
        return SIMD3(dot(world,x)/sx,dot(world,y)/sy,dot(world,z)/sz)
    }
    private func groundAt(_ x:Float,_ z:Float)->Float? {
        guard let h=floor.support(x,z,low:originalFoot-0.14,high:originalFoot+0.16),
              abs(h-originalFoot)<0.14 else{return nil}
        return h
    }
    /// PC NpcRotateBoneToPoint529, hip/knee and ball in real skinned world space.
    private func point(_ joint:SCNNode,_ marker:SCNNode,
                       _ target:SIMD3<Float>,_ fraction:Float,_ cap:Float) {
        guard let parent=joint.parent else{return}
        let pos=joint.simdWorldPosition,toe=marker.simdWorldPosition
        var v=toe-pos,w=target-pos
        let n=length(v),m=length(w)
        if n<0.01 || m<0.01{return}
        v /= n;w /= m
        var axis=cross(v,w)
        let axisLength=length(axis)
        if axisLength<0.00001{return}
        let angle=min(cap,atan2(axisLength,clamp(dot(v,w),-1,1))*fraction)
        axis /= axisLength
        let local=parentLocal(axis,parent)
        let ml=length(local)
        if ml<0.0001{return}
        let q=simd_quatf(angle:angle,axis:local/ml)
        joint.simdOrientation=simd_normalize(q*joint.simdOrientation)
    }

    /// Operates only on imported NPC bones on main thread. SCNTransaction
    /// disables implicit interpolation, since the PC blend is already sampled.
    func apply(dt raw:Float,mechanic:H55Mechanic580) {
        let dt=clamp(raw,0,0.07)
        let measured=dt>0.0001 ? mechanic.movedThisFrame/dt : 0
        let yawRate=dt>0.0001 ? H55Mechanic580.wrap(mechanic.yaw-previousYaw)/dt : 0
        previousYaw=mechanic.yaw
        let poses=motion.step(dt:dt,moving:mechanic.moving,
                              distance:mechanic.distance,speed:measured,yawRate:yawRate)
        SCNTransaction.begin()
        SCNTransaction.disableActions=true
        for i in poses.indices {
            let bone=bones[i],p=poses[i]
            bone.simdPosition=p.position
            bone.simdOrientation=simd_quatf(ix:p.rotation.x,iy:p.rotation.y,
                                            iz:p.rotation.z,r:p.rotation.w)
            bone.simdScale=p.scale
        }
        var landings=0
        for i in feet.indices {
            var foot=feet[i]
            let toe=foot.ball.simdWorldPosition
            guard let ground=groundAt(toe.x,toe.z) else {
                foot.planted=false
                foot.weight=max(0,foot.weight-dt*8)
                feet[i]=foot
                continue
            }
            let clearance=toe.y-(ground+0.08)
            let turningInPlace = !mechanic.moving && abs(yawRate)>0.24
            let threshold:Float=foot.planted ? 0.062 : (mechanic.moving ? 0.050 : 0.052)
            var candidate = !turningInPlace && (!mechanic.moving || measured>0.05) &&
                            clearance<threshold
            if clearance>0.078 {foot.waitForLift=false}
            let horizontal=SIMD3(toe.x-foot.anchor.x,0,toe.z-foot.anchor.z)
            if foot.planted && dot(horizontal,horizontal)>0.20*0.20 {
                foot.waitForLift=true;candidate=false
            }
            if foot.waitForLift {candidate=false}
            if foot.planted && clearance>0.078 {candidate=false}
            if candidate && !foot.planted {
                foot.planted=true
                foot.anchor=SIMD3(toe.x,ground+0.08,toe.z)
                foot.lockCount+=1;lockCount+=1
                if mechanic.moving && measured>0.12 {landings+=1}
            } else if !candidate && foot.planted {
                foot.planted=false;foot.releaseCount+=1
            }
            if turningInPlace {foot.planted=false}
            foot.weight=clamp(foot.weight+(foot.planted ? dt*24 : -dt*18),0,1)
            if !foot.planted && foot.weight<0.001 {
                foot.anchor=SIMD3(toe.x,ground+0.08,toe.z)
            }
            feet[i]=foot
        }
        let landing=motion.land(dt:dt,newContacts:landings,speed:measured)
        let sum=feet[0].weight+feet[1].weight
        var shift=SIMD3<Float>.zero
        if mechanic.moving && sum>0.25 {
            let cx=(feet[0].anchor.x*feet[0].weight+feet[1].anchor.x*feet[1].weight)/sum
            let cz=(feet[0].anchor.z*feet[0].weight+feet[1].anchor.z*feet[1].weight)/sum
            let hip=pelvis.simdWorldPosition
            let ex=cx-hip.x,ez=cz-hip.z
            if hypot(ex,ez)>0.001 {
                let face=H55Mechanic580.wrap(heading-mechanic.yaw)
                let forward=SIMD3<Float>(sin(face),0,-cos(face))
                let side=SIMD3<Float>(-forward.z,0,forward.x)
                var long=clamp((ex*forward.x+ez*forward.z)*0.14,-0.012,0.012)
                var lateral=clamp((ex*side.x+ez*side.z)*0.08,-0.006,0.006)
                if mechanic.avoidingPlayer {long *= 0.65;lateral *= 0.65}
                shift=forward*long+side*lateral
            }
        }
        let alpha:Float=1-exp(-dt*5)
        supportX+=(shift.x-supportX)*alpha
        supportZ+=(shift.z-supportZ)*alpha
        if let parent=pelvis.parent {
            let v=SIMD3<Float>(supportX,-landing,supportZ)
            pelvis.simdPosition+=parentLocal(v,parent)
        }
        // Original PC v529 two-bone IK: 10 iterations of calf then thigh,
        // max 20 cm correction, no authored ankle/ball rotations overwritten.
        for i in feet.indices {
            let foot=feet[i]
            if foot.weight<0.01 {continue}
            if !foot.planted && foot.weight<0.65 {continue}
            let toe=foot.ball.simdWorldPosition
            guard groundAt(toe.x,toe.z) != nil else{continue}
            var target=toe+(foot.anchor-toe)*smooth(foot.weight)
            let error=target-toe,amount=length(error)
            if amount>0.20 {target=toe+error*(0.20/amount)}
            let initial=length(target-toe)
            maxError=max(maxError,initial)
            for _ in 0..<10 {
                point(foot.calf,foot.ball,target,0.88,0.25)
                point(foot.thigh,foot.ball,target,0.86,0.23)
            }
            let remaining=length(foot.ball.simdWorldPosition-target)
            maxCorrection=max(maxCorrection,initial-remaining)
            solvedCount+=1
        }
        // Like PC v525 npcLast{T,R,S}, snapshot resolved IK as the
        // next blend's true starting pose, not the unclamped source pose.
        var solved=[H55NpcTracks580.Pose]()
        solved.reserveCapacity(bones.count)
        for bone in bones {
            let q=bone.simdOrientation
            solved.append(H55NpcTracks580.Pose(position:bone.simdPosition,
                rotation:Q(x:q.imag.x,y:q.imag.y,z:q.imag.z,w:q.real),
                scale:bone.simdScale))
        }
        motion.recordSolvedPose(solved)
        SCNTransaction.commit()
    }
}
