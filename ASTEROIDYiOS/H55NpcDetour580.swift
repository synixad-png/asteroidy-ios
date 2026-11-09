import Foundation

/// Exact local-grid A* shape and safety gates from PC v580
/// Windows/src/H55Renderer.cs NpcMakeDetour532 / NpcSegmentClear532.
/// The caller supplies the REAL active H55 floor/capsule collision query.
/// Never straight-line bypass a wall, player or closed hangar door.
enum H55NpcDetour580 {
    struct Point: Equatable { var x:Float; var z:Float }
    static let grid:Float=0.24
    static let margin:Float=1.9
    static let playerBuffer:Float=0.97

    static func segmentClear(from a:Point,to b:Point,player:Point,
                             walkable:(Float,Float)->Bool)->Bool {
        let dx=b.x-a.x,dz=b.z-a.z
        let len=hypot(dx,dz)
        let n=max(1,Int(ceil(len/0.08)))
        let originDistance=hypot(a.x-player.x,a.z-player.z)
        for k in 1...n {
            let t=Float(k)/Float(n)
            let x=a.x+dx*t,z=a.z+dz*t
            guard walkable(x,z) else{return false}
            let distance=hypot(x-player.x,z-player.z)
            if distance<playerBuffer &&
               distance+0.005<min(playerBuffer,originDistance) {return false}
        }
        return true
    }

    /// Returns only validated waypoints; nil means remain stopped.
    static func plan(start:Point,join:Point,player:Point,
                     walkable:(Float,Float)->Bool)->[Point]? {
        let originX=min(start.x,join.x)-margin
        let originZ=min(start.z,join.z)-margin
        let width=Int(ceil((max(start.x,join.x)-originX+margin)/grid))+1
        let height=Int(ceil((max(start.z,join.z)-originZ+margin)/grid))+1
        guard width>=2,height>=2,width*height<=3000 else{return nil}
        let n=width*height
        func index(_ x:Int,_ z:Int)->Int {z*width+x}
        let sx=Int(round((start.x-originX)/grid))
        let sz=Int(round((start.z-originZ)/grid))
        let gx=Int(round((join.x-originX)/grid))
        let gz=Int(round((join.z-originZ)/grid))
        guard sx>=0,sx<width,sz>=0,sz<height,
              gx>=0,gx<width,gz>=0,gz<height else{return nil}
        let source=index(sx,sz),target=index(gx,gz)
        var allowed=[Bool](repeating:false,count:n)
        for z in 0..<height {
            for x in 0..<width {
                let wx=originX+Float(x)*grid
                let wz=originZ+Float(z)*grid
                let pdx=wx-player.x,pdz=wz-player.z
                allowed[index(x,z)]=pdx*pdx+pdz*pdz>=playerBuffer*playerBuffer &&
                                   walkable(wx,wz)
            }
        }
        allowed[source]=true // Original permits NPC already within player buffer.
        guard allowed[target] else{return nil}
        var score=[Float](repeating:Float.greatestFiniteMagnitude,count:n)
        var previous=[Int](repeating:-1,count:n)
        var known=[Bool](repeating:false,count:n)
        var closed=[Bool](repeating:false,count:n)
        var open=[source]
        known[source]=true
        score[source]=0
        var explored=0
        while !open.isEmpty && explored<n {
            explored+=1
            var best=0,bestScore=Float.greatestFiniteMagnitude
            for i in open.indices {
                let id=open[i],x=id%width,z=id/width
                let dx=Float(gx-x)*grid,dz=Float(gz-z)*grid
                let rank=score[id]+hypot(dx,dz)
                if rank<bestScore {best=i;bestScore=rank}
            }
            let current=open.remove(at:best)
            known[current]=false
            if current==target {break}
            if closed[current] {continue}
            closed[current]=true
            let x=current%width,z=current/width
            for dz in -1...1 {
                for dx in -1...1 {
                    if dx==0 && dz==0 {continue}
                    let nx=x+dx,nz=z+dz
                    if nx<0 || nx>=width || nz<0 || nz>=height {continue}
                    let next=index(nx,nz)
                    if !allowed[next] || closed[next] {continue}
                    if dx != 0 && dz != 0 &&
                       (!allowed[index(nx,z)] || !allowed[index(x,nz)]) {
                        continue // Never cut diagonally between two solids.
                    }
                    let candidate=score[current] +
                           ((dx==0 || dz==0) ? grid : grid*1.41421356)
                    if candidate+0.00001>=score[next] {continue}
                    score[next]=candidate
                    previous[next]=current
                    if !known[next] {open.append(next);known[next]=true}
                }
            }
        }
        if source != target && previous[target]<0 {return nil}
        var backward:[Point]=[]
        var cursor=target
        while cursor != source && cursor>=0 && backward.count<=n {
            backward.append(Point(x:originX+Float(cursor%width)*grid,
                                  z:originZ+Float(cursor/width)*grid))
            cursor=previous[cursor]
        }
        guard cursor==source else{return nil}
        backward.reverse()
        // PC v532 string-pulls only across verified geometry segments.
        var targets:[Point]=[]
        var origin=start
        var at=0
        while at<backward.count {
            var furthest=at
            if backward.count-at>1 {
                for j in stride(from:backward.count-1,through:at+1,by:-1) {
                    if segmentClear(from:origin,to:backward[j],
                                    player:player,walkable:walkable) {
                        furthest=j
                        break
                    }
                }
            }
            let next=backward[furthest]
            guard segmentClear(from:origin,to:next,
                               player:player,walkable:walkable) else{return nil}
            targets.append(next)
            origin=next
            at=furthest+1
        }
        guard segmentClear(from:origin,to:join,
                           player:player,walkable:walkable) else{return nil}
        targets.append(join)
        guard !targets.isEmpty,targets.count<=32 else{return nil}
        return targets
    }

    /// PC v580 NpcPlanPlayerBypass532: only join an approved nearby
    /// source route segment/waypoint; never invent a new final goal.
    static func bypass(start:Point,player:Point,goal:Point,
                       goalIndex:Int,workshopIndex:Int,
                       routeX:[Float],routeZ:[Float],
                       walkable:(Float,Float)->Bool)->(points:[Point],skipTo:Int)? {
        let dx=goal.x-start.x,dz=goal.z-start.z
        let length=hypot(dx,dz)
        let pDist=hypot(goal.x-player.x,goal.z-player.z)
        if length<1.8 || pDist<1.5 {
            // H08 real-GLB regression exposed an original PC v580 bug:
            // NpcPlanPlayerBypass532 always clamps lookahead to
            // NpcWorkshopIndex530-1 even when already on RETURN leg.
            // On return (indices 12...27), that prevents every bypass.
            // Keep the original 28 user-approved points, 3-point
            // lookahead, 6m safety and A*; only select the proper leg end.
            let legEnd=goalIndex<workshopIndex ? workshopIndex-1 : routeX.count-1
            let limit=min(legEnd,goalIndex+3)
            if limit<goalIndex+1 {return nil}
            for i in (goalIndex+1)...limit {
                let join=Point(x:routeX[i],z:routeZ[i])
                let pdx=join.x-player.x,pdz=join.z-player.z
                if pdx*pdx+pdz*pdz<1.6*1.6 {continue}
                let sx=join.x-start.x,sz=join.z-start.z
                if sx*sx+sz*sz>36 {continue}
                if let points=plan(start:start,join:join,player:player,
                                   walkable:walkable) {
                    return (points,i)
                }
            }
            return nil
        }
        let projected=((player.x-start.x)*dx+(player.z-start.z)*dz)/length
        for i in 0..<4 {
            let ahead=min(length-0.3,max(1.6,projected+1.65+Float(i)*0.40))
            if ahead<=0 || ahead>=length {continue}
            let join=Point(x:start.x+dx/length*ahead,
                           z:start.z+dz/length*ahead)
            let pdx=join.x-player.x,pdz=join.z-player.z
            if pdx*pdx+pdz*pdz<1.3*1.3 {continue}
            if let points=plan(start:start,join:join,player:player,
                               walkable:walkable) {
                return (points,-1)
            }
        }
        return nil
    }
}
