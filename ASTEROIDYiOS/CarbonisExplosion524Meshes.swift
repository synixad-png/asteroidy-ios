import Foundation

/// Tessellation of exact Game.Particles/Lights + CombatPieces125 and
/// Explosion524.DrawExplosionShards524 for the CARBONIS C279 sphere.
/// Matches source event lifetimes, colors, dimensions and triangle facets.
/// OpenGL SphereLine67 was 6-segment line rasterization; Metal expands each
/// segment into a thin depth-tested quad (not a 2D HUD overlay).
/// Same six great-circle steps as Windows SphereLine67, evaluated as
/// a recurrence on unit vectors. This avoids repeated longitude/latitude
/// inverse conversions, trigonometry and Sphere67.offset on EACH
/// sub-segment of every 32-edge explosion light ring.
/// It does NOT change subdivision count, line width or the game state.
struct SourceGeodesicStep568 {
    let origin:SphereVector3
    let destination:SphereVector3
    let tangent:SphereVector3
    let cosIncrement:Float
    let sinIncrement:Float
    let steps:Int
    private(set) var index=0
    private var c:Float=1
    private var s:Float=0

    init(from:Vec2,to:Vec2,steps:Int=6) {
        precondition(steps>0)
        let a=Sphere67.normal(from)
        let b=Sphere67.normal(to)
        let dot=max(-1,min(1,SphereVector3.dot(a,b)))
        let residual=b-a*dot
        let length=residual.length
        let angle:Float
        let direction:SphereVector3
        let end:SphereVector3
        if length<0.000001 {
            if dot<0 {
                // Same original antipodal fallback as Sphere67.delta:
                // travel pi*Sphere67.radius in local east direction.
                angle=Float.pi
                direction=Sphere67.basis(from).east
                end=b
            } else {
                angle=0
                direction=SphereVector3(x:0,y:0,z:0)
                end=a
            }
        } else {
            angle=atan2(length,dot)
            direction=residual/length
            end=b
        }
        origin=a
        destination=end
        tangent=direction
        cosIncrement=cos(angle/Float(steps))
        sinIncrement=sin(angle/Float(steps))
        self.steps=steps
    }
    mutating func nextUnit() -> SphereVector3 {
        precondition(index<steps)
        index+=1
        if index==steps {return destination}
        let nextC=c*cosIncrement-s*sinIncrement
        let nextS=s*cosIncrement+c*sinIncrement
        c=nextC
        s=nextS
        return origin*c+tangent*s
    }
}

enum CarbonisExplosion524Meshes {
    private static let outer:Float=SphereCameraView556.originalPlanetOuterRadius
    private static let shell:Float=(outer+15)/outer
    private static let lineLift:Float=0.4/outer
    private static let scale67:Float=(outer+15)/Sphere67.radius/outer

    static func hash524(_ n:Float)->Float {
        0.5+0.5*sin(n*53.71+n*n*0.037)
    }
    private static func rgba(_ r:Float,_ g:Float,_ b:Float,_ a:Float)->[Float] {
        [r,g,b,a]
    }
    private static func append(_ p:SphereVector3,
                               color:[Float],into out:inout [Float]) {
        let n=p.normalized
        out.append(contentsOf:[
            p.x,p.y,p.z,n.x,n.y,n.z,
            color[0],color[1],color[2],color[3],0,0])
    }
    private static func triangle(_ a:SphereVector3,
        _ b:SphereVector3,_ c:SphereVector3,
        color:[Float],into out:inout [Float]) {
        append(a,color:color,into:&out)
        append(b,color:color,into:&out)
        append(c,color:color,into:&out)
    }
    private static func stripe(_ from:SphereVector3,
        _ to:SphereVector3,color:[Float],
        width:Float,into out:inout [Float]) {
        let length=(to-from).length
        if length<0.000001 {return}
        let tangent=(to-from)/length
        let normal=(from+to).normalized
        let side=SphereVector3.cross(tangent,normal).normalized*(width*0.5)
        if side.length<0.000001 {return}
        triangle(from-side,to-side,to+side,color:color,into:&out)
        triangle(from-side,to+side,from+side,color:color,into:&out)
    }
    /// SphereLine67: seven points -> exactly six geodesic subdivisions.
    private static func sphereLine(from:Vec2,to:Vec2,color:[Float],
                                   into out:inout [Float]) {
        // Source SphereLine67 always draws exactly six geodesic pieces.
        // The old path reprojected six geographic coordinates per line.
        // A unit-vector great-circle recurrence is mathematically the
        // same original arc and needs only one angular sin/cos pair.
        var arc=SourceGeodesicStep568(from:from,to:to,steps:6)
        var last=arc.origin*(shell+lineLift)
        for _ in 0..<6 {
            let current=arc.nextUnit()*(shell+lineLift)
            stripe(last,current,color:color,width:0.006,
                   into:&out)
            last=current
        }
    }
    /// RingSphere67: 32 source edges, six geodesic subdivisions each.
    private static func ring(at center:Vec2,radius:Float,
        color:[Float],into out:inout [Float]) {
        let first=Sphere67.offset(center,by:Vec2(x:radius,y:0))
        var previous=first
        for i in 1...32 {
            let angle=Float(i)*Float.pi/16
            let end=i==32 ? first :
                Sphere67.offset(center,by:Vec2(
                    x:cos(angle)*radius,y:sin(angle)*radius))
            sphereLine(from:previous,to:end,color:color,into:&out)
            previous=end
        }
    }
    private static func localToWorld(
        _ local:SphereVector3,at point:Vec2,
        angle:Float,size:Float)->SphereVector3 {
        let basis=Sphere67.basis(point)
        let n=Sphere67.normal(point)
        let forward=basis.east*cos(angle)+basis.south*sin(angle)
        let right=SphereVector3.cross(forward,n).normalized
        // GpuCombatPieces125: shipRotate(angle*57,Y);
        // shipRotate(angle*36,X), source GL degrees.
        let y=angle*57*Float.pi/180
        let x=angle*36*Float.pi/180
        let rotX=SphereVector3(
            x:local.x,
            y:local.y*cos(x)-local.z*sin(x),
            z:local.y*sin(x)+local.z*cos(x))
        let rotated=SphereVector3(
            x:rotX.x*cos(y)+rotX.z*sin(y),
            y:rotX.y,
            z:-rotX.x*sin(y)+rotX.z*cos(y))
        let displacement=right*rotated.x+forward*rotated.y+n*rotated.z
        return n*shell+displacement*(size*scale67)
    }
    private static func tetra(_ piece:CarbonisDestruction524.CombatPiece,
        into out:inout [Float]) {
        let fraction=min(1,piece.life/0.3)
        let size=max(0.13,piece.size*fraction)
        let a=SphereVector3(x:-0.75,y:-0.50,z:0)
        let b=SphereVector3(x:0.85,y:-0.23,z:-0.08)
        let c=SphereVector3(x:0.04,y:0.65,z:0.34)
        let d=SphereVector3(x:0.18,y:-0.08,z:-0.70)
        let r:Float=piece.kind==3 ? 0.48 : 0.35
        let g:Float=piece.kind==3 ? 0.55 : 0.41
        let blue:Float=piece.kind==3 ? 0.65 : 0.52
        func v(_ source:SphereVector3)->SphereVector3 {
            localToWorld(source,at:piece.point,
                         angle:piece.angle,size:size)
        }
        triangle(v(a),v(b),v(c),
                 color:rgba(r,g,blue,1),into:&out)
        triangle(v(a),v(c),v(d),
                 color:rgba(r*0.58,g*0.62,blue*0.68,1),into:&out)
        triangle(v(b),v(d),v(c),
                 color:rgba(r*0.80,g*0.82,blue*0.86,1),into:&out)
        triangle(v(a),v(d),v(b),
                 color:rgba(r*0.44,g*0.49,blue*0.56,1),into:&out)
    }

    /// Explosion524.cs:165-183: deterministic 35 flying 3D shards under
    /// default explosion preset (50% shards); no rendered texture stand-in.
    private static func volumetricShards(
        _ event:CarbonisDestruction524.Explosion,time:Float,
        camera:SphereCamera67,settings:CarbonisVisualSettings568,
        budget:CarbonisIOSFXBudget568,
        into out:inout [Float]) {
        let age=time-event.spawned
        if age<0.1 || age>3.8 {return}
        let center=Sphere67.normal(event.point)*(shell+1.1/outer)
        let eye=SphereCameraView556(camera:camera).eye
        let front=(eye-center).normalized
        var right=SphereVector3.cross(
            SphereVector3(x:0,y:1,z:0),front).normalized
        if right.length<0.01 {right=SphereVector3(x:1,y:0,z:0)}
        let up=SphereVector3.cross(front,right).normalized
        let life=max(0,1-age/3.8)
        let spread=settings.factor(5)
        for i in 0..<budget.shardLimit(settings.shardCount) {
            let seed=Float(i+1)
            let dx=hash524(seed*3+2)*2-1
            let dy=hash524(seed*5+4)*2-1
            let dz=hash524(seed*7+6)*2-1
            let raw=right*dx+up*dy+front*dz
            let length=raw.length
            if length<0.01 {continue}
            let direction=raw/length
            let distance=age*(0.48+hash524(seed*9)*0.85) *
                spread*event.scale*0.47/outer
            let point=center+direction*distance
            let size=(0.025+0.055*hash524(seed+9)) *
                event.scale*0.52*life/outer
            let edge=SphereVector3.cross(direction,up).normalized
            let tilt=SphereVector3.cross(direction,edge).normalized
            let h=hash524(seed+2)
            let red=event.kind==1 ? 0.38+0.4*h : 0.76+0.2*h
            let color=rgba(red,0.18+0.23*h,0.05+0.07*h,0.7*life)
            let a=point+direction*size*1.4
            let b=point-edge*size+tilt*size*0.4-direction*size
            let c=point+edge*size+tilt*size*0.4-direction*size
            triangle(a,b,c,color:color,into:&out)
        }
    }

    static func vertices(_ state:CarbonisDestruction524,
                         time:Float,camera:SphereCamera67,
                         settings:CarbonisVisualSettings568 = .init(),
                         budget:CarbonisIOSFXBudget568 = .original,
                         aspect:Float?=nil)->[Float] {
        var out:[Float]=[]
        out.reserveCapacity(budget.reduced ? 18000 : 60000)
        // Original GpuSphere67.VisibleSurface73: invisible cosmetic
        // sprites must never incur 32x6 source geodesic ring tessellation.
        // The optional aspect is supplied ONLY by live gameplay: source
        // unit tests and preview calls with nil still render EVERYTHING.
        // Bounds are deliberately larger than the source surface
        // footprint, including edge-of-screen and horizon glow.
        let visibility=aspect.map { _ in SphereCameraView556(camera:camera) }
        func visible(_ point:Vec2,_ worldRadius:Float)->Bool {
            guard let aspect,let visibility else {return true}
            return SourceVisibleSurface73.possiblyVisible(
                point,worldRadius:worldRadius,
                camera:visibility,aspect:aspect)
        }
        for p in state.particles.suffix(
                budget.particleLimit(state.particles.count)) {
            // Max source trail 200*0.024 screen units, plus line width.
            if !visible(p.point,0.06) {continue}
            let alpha=max(0,min(1,p.life/max(p.maxLife,0.00001)))
            let color=p.kind==1 ?
                rgba(1,0.647,0,alpha) : rgba(0,1,1,alpha)
            // GpuSphere67.cs:442 length corresponds to velocity*-.024.
            let back=Sphere67.offset(p.point,by:p.velocity*(-0.024))
            sphereLine(from:back,to:p.point,color:color,into:&out)
        }
        for light in state.lights where light.life>0 {
            // Source radius expands from 10 to 75 sphere arc units:
            // 75/(720/pi)*(shell+lift)=0.363 in normalized 3D.
            // Conservative 0.45 margin also covers stripe width.
            if !visible(light.point,0.45) {continue}
            if state.nearDestruction(light.point,time:time) {continue}
            let fraction=max(0,min(1,
                light.life/max(light.maxLife,0.00001)))
            let color=light.kind==1 ?
                rgba(1,0.647,0,180/255*fraction)
                : rgba(0,1,1,180/255*fraction)
            ring(at:light.point,radius:10+(1-fraction)*65,
                 color:color,into:&out)
        }
        for piece in state.pieces.suffix(
                budget.pieceLimit(state.pieces.count)) {
            // Original small spark/shard geometry, generously bounded:
            // clip only if the *entire* cosmetic element is invisible.
            if !visible(piece.point,max(0.30,piece.size*0.04)) {continue}
            if piece.kind==0 {
                let along=Vec2(x:cos(piece.angle)*piece.size,
                               y:sin(piece.angle)*piece.size)
                sphereLine(from:Sphere67.offset(piece.point,by:along*(-1)),
                           to:Sphere67.offset(piece.point,by:along),
                           color:rgba(1,192/255,92/255,244/255),
                           into:&out)
                let side=Vec2(x:-along.y,y:along.x)
                sphereLine(from:Sphere67.offset(piece.point,by:side*(-0.65)),
                           to:Sphere67.offset(piece.point,by:side*0.65),
                           color:rgba(1,111/255,53/255,225/255),
                           into:&out)
            } else {
                tetra(piece,into:&out)
            }
        }
        for event in state.visibleExplosions(
            at:time,maxCount:budget.volumeCount(settings.simultaneousVolumes),
            duration:budget.explosionDuration(settings.explosionDuration)) {
            volumetricShards(event,time:time,camera:camera,
                             settings:settings,budget:budget,into:&out)
        }
        return out
    }
}