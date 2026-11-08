import Foundation

/// Literal port of Windows/src/HangarCollision441.cs (PC v580).
/// H02 only constructs authentic, static collision geometry. H03/H04 will
/// consume it; the existing SceneKit camera and walking are NOT replaced here.
/// All positions are world-space metres in the *original* active GLB scene.
enum H55CollisionGeometry580 {
    struct Box {
        var x0:Float=0, y0:Float=0, z0:Float=0
        var x1:Float=0, y1:Float=0, z1:Float=0
        var name=""
        var valid=false
        mutating func expand(_ x:Float,_ y:Float,_ z:Float) {
            guard x.isFinite && y.isFinite && z.isFinite else{return}
            if !valid {x0=x;x1=x;y0=y;y1=y;z0=z;z1=z;valid=true}
            else {
                x0=min(x0,x);x1=max(x1,x)
                y0=min(y0,y);y1=max(y1,y)
                z0=min(z0,z);z1=max(z1,z)
            }
        }
    }
    struct Geometry {
        var triangles:[Float]
        var objects:[Box]
        var sourceTriangles:Int
        var proxyTriangles:Int
        var sceneNodes:Int
        var minX:Float
        var maxX:Float
        var minZ:Float
        var maxZ:Float
    }
    enum Invalid:Error,LocalizedError {
        case glb,tree,accessor,geometry,scene
        var errorDescription:String? {
            switch self {
            case .glb:return "Nieprawidłowy format GLB w oryginalnej geometrii kolizji."
            case .tree:return "Nieprawidłowe drzewo węzłów GLB."
            case .accessor:return "Niepoprawne dane POSITION/indices w GLB."
            case .geometry:return "Oryginalna geometria H55 jest niepełna."
            case .scene:return "Niepoprawna aktywna scena H55."
            }
        }
    }
    private typealias D=[String:Any]
    private static func dict(_ a:Any?)->D {a as? D ?? [:]}
    private static func arr(_ a:Any?)->[Any] {a as? [Any] ?? []}
    private static func text(_ a:Any?)->String {a as? String ?? ""}
    private static func integer(_ a:Any?,_ fallback:Int=0)->Int {
        (a as? NSNumber)?.intValue ?? fallback
    }
    private static func number(_ a:Any?,_ fallback:Float=0)->Float {
        (a as? NSNumber)?.floatValue ?? fallback
    }
    private static func vector(_ a:Any?,_ length:Int,_ defaults:[Float])->[Float] {
        let v=arr(a);var out=defaults
        for j in 0..<min(length,v.count) {out[j]=number(v[j])}
        return out
    }
    private static func word(_ data:Data,_ index:Int)->UInt32 {
        UInt32(data[index]) | UInt32(data[index+1])<<8 |
        UInt32(data[index+2])<<16 | UInt32(data[index+3])<<24
    }
    private static func identity()->[Float] {
        [1,0,0,0, 0,1,0,0, 0,0,1,0, 0,0,0,1]
    }
    private static func local(_ node:D)throws->[Float] {
        let matrix=arr(node["matrix"])
        if !matrix.isEmpty {
            guard matrix.count==16 else{throw Invalid.tree}
            return matrix.map{number($0)}
        }
        let t=vector(node["translation"],3,[0,0,0])
        let s=vector(node["scale"],3,[1,1,1])
        let q=vector(node["rotation"],4,[0,0,0,1])
        let x=q[0],y=q[1],z=q[2],w=q[3]
        let xx=x*x,yy=y*y,zz=z*z,xy=x*y,xz=x*z,yz=y*z
        let wx=w*x,wy=w*y,wz=w*z
        // Exact original column-major glTF TRS, including nonuniform scale.
        return [
            (1-2*(yy+zz))*s[0],2*(xy+wz)*s[0],2*(xz-wy)*s[0],0,
            2*(xy-wz)*s[1],(1-2*(xx+zz))*s[1],2*(yz+wx)*s[1],0,
            2*(xz+wy)*s[2],2*(yz-wx)*s[2],(1-2*(xx+yy))*s[2],0,
            t[0],t[1],t[2],1
        ]
    }
    private static func product(_ a:[Float],_ b:[Float])->[Float] {
        var c=[Float](repeating:0,count:16)
        for j in 0..<4 {for i in 0..<4 {
            var sum:Float=0
            for k in 0..<4 {sum+=a[k*4+i]*b[j*4+k]}
            c[j*4+i]=sum
        }}
        return c
    }
    private static func transformed(_ p:[Float],_ m:[Float])->[Float] {
        var out=[Float](repeating:0,count:p.count)
        for i in stride(from:0,to:p.count,by:3) {
            let x=p[i],y=p[i+1],z=p[i+2]
            out[i]=m[0]*x+m[4]*y+m[8]*z+m[12]
            out[i+1]=m[1]*x+m[5]*y+m[9]*z+m[13]
            out[i+2]=m[2]*x+m[6]*y+m[10]*z+m[14]
        }
        return out
    }
    private static func group(_ name:String)->String? {
        let lower=name.lowercased()
        for prefix in ["hangarlab_prefab_","hl_import_"] {
            guard let r=lower.range(of:prefix) else {continue}
            let from=r.upperBound
            let digits=lower[from...].prefix(while:{$0.isASCII && $0.isNumber})
            if !digits.isEmpty {
                return String(name[r.lowerBound...].prefix(prefix.count+digits.count))
            }
        }
        return nil
    }
    private static func looksLikePortal(_ name:String)->Bool {
        let n=name.lowercased()
        return n.contains("portal") &&
               (n.contains("frame") || n.contains("rama") || n.contains("ramka"))
    }
    private static func splitPortal(_ b:Box,_ points:[Float])->[Box]? {
        guard b.valid && points.count>=9 else {return nil}
        let dx=b.x1-b.x0,dz=b.z1-b.z0,dy=b.y1-b.y0
        guard dy>=2.3 && max(dx,dz)>=2.2 &&
              min(dx,dz)<=0.36*max(dx,dz) else{return nil}
        let alongX=dx>=dz
        let low=b.y0+dy*0.38,high=b.y0+dy*0.62
        var widths:[Float]=[]
        widths.reserveCapacity(points.count/3)
        for i in stride(from:0,to:points.count,by:3) {
            if points[i+1]>=low && points[i+1]<=high {
                widths.append(points[i+(alongX ? 0 : 2)])
            }
        }
        guard widths.count>=16 else{return nil}
        widths.sort()
        var gap:Float=0,left:Float=0,right:Float=0
        for i in 1..<widths.count {
            let delta=widths[i]-widths[i-1]
            if delta>gap {gap=delta;left=widths[i-1];right=widths[i]}
        }
        let extent=alongX ? dx : dz
        let edgeLow=alongX ? b.x0 : b.z0
        let edgeHigh=alongX ? b.x1 : b.z1
        guard gap>=max(1.1,extent*0.36),
              left>=edgeLow+0.15,right<=edgeHigh-0.15 else{return nil}
        var jambA=b,jambB=b,header=b
        jambA.name=b.name+"/jamb_A"
        jambB.name=b.name+"/jamb_B"
        header.name=b.name+"/header"
        if alongX {
            jambA.x1=min(b.x1,left);jambB.x0=max(b.x0,right)
        } else {
            jambA.z1=min(b.z1,left);jambB.z0=max(b.z0,right)
        }
        header.y0=b.y0+dy*0.72
        guard (alongX ? jambA.x1>jambA.x0 : jambA.z1>jambA.z0) &&
              (alongX ? jambB.x1>jambB.x0 : jambB.z1>jambB.z0)
        else{return nil}
        return [jambA,jambB,header]
    }
    private struct Reader {
        let bytes:Data
        let accessors:[D],views:[D]
        let start:Int,length:Int
        var positions:[Int:[Float]]=[:]
        var indices:[Int:[Int]]=[:]
        func u16(_ p:Int)->UInt16 {
            UInt16(bytes[p]) | UInt16(bytes[p+1])<<8
        }
        func u32(_ p:Int)->UInt32 {H55CollisionGeometry580.word(bytes,p)}
        func accessor(_ id:Int)->(base:Int,count:Int,type:Int,stride:Int,def:D)? {
            guard id>=0 && id<accessors.count else{return nil}
            let a=accessors[id]
            let count=integer(a["count"]),type=integer(a["componentType"])
            let viewIndex=integer(a["bufferView"],-1)
            guard viewIndex>=0 && viewIndex<views.count else{return nil}
            let v=views[viewIndex]
            let size=(type==5125 || type==5126) ? 4 :
                     ((type==5123 || type==5122) ? 2 : 1)
            let dims=text(a["type"])=="VEC3" ? 3 : 1
            let stride=integer(v["byteStride"],size*dims)
            let offset=integer(v["byteOffset"])+integer(a["byteOffset"])
            guard count>=0 && offset>=0 && stride>=size*dims &&
                  Int64(offset)+Int64(max(0,count-1))*Int64(stride)+Int64(size*dims)<=Int64(length)
            else{return nil}
            return (start+offset,count,type,stride,a)
        }
        mutating func pos(_ id:Int)throws->[Float] {
            if let v=positions[id] {return v}
            guard let a=accessor(id),text(a.def["type"])=="VEC3",
                  [5126,5123,5122,5121,5120].contains(a.type),
                  a.def["sparse"] == nil else{throw Invalid.accessor}
            let normalized=(a.def["normalized"] as? Bool) ?? false
            let size=a.type==5126 ? 4 :
                ((a.type==5123 || a.type==5122) ? 2 : 1)
            var out=[Float](repeating:0,count:a.count*3)
            for i in 0..<a.count {for j in 0..<3 {
                let p=a.base+i*a.stride+j*size
                let v:Float
                switch a.type {
                case 5126:v=Float(bitPattern:u32(p))
                case 5123:
                    let q=Float(u16(p))
                    v=normalized ? q/65535 : q
                case 5122:
                    let q=Float(Int16(bitPattern:u16(p)))
                    v=normalized ? max(-1,q/32767) : q
                case 5121:
                    let q=Float(bytes[p])
                    v=normalized ? q/255 : q
                default:
                    let q=Float(Int8(bitPattern:bytes[p]))
                    v=normalized ? max(-1,q/127) : q
                }
                guard v.isFinite else{throw Invalid.accessor}
                out[i*3+j]=v
            }}
            positions[id]=out
            return out
        }
        mutating func inds(_ id:Int,_ fallback:Int)throws->[Int] {
            if id<0 {return Array(0..<fallback)}
            if let v=indices[id] {return v}
            guard let a=accessor(id),text(a.def["type"])=="SCALAR"
            else{throw Invalid.accessor}
            var out=[Int](repeating:0,count:a.count)
            for i in 0..<a.count {
                let p=a.base+i*a.stride
                switch a.type {
                case 5125:out[i]=Int(u32(p))
                case 5123:out[i]=Int(u16(p))
                case 5121:out[i]=Int(bytes[p])
                default:throw Invalid.accessor
                }
            }
            indices[id]=out
            return out
        }
    }
    private static func selectedDrones(_ nodes:[D])->Set<String> {
        var mx:Float=10.194016,mz:Float=12.696275
        for n in nodes {
            let name=text(n["name"])
            if name.range(of:"Mechanik_",options:.caseInsensitive)==nil ||
               n["mesh"] != nil {continue}
            let m=arr(n["matrix"])
            if m.count==16 {mx=number(m[12]);mz=number(m[14]);break}
        }
        var candidates:[(name:String,x:Float,z:Float,dist:Float)]=[]
        for n in nodes {
            let extra=dict(n["extras"])
            guard (extra["hangarLabImported"] as? Bool)==true else{continue}
            let src=text(extra["hangarLabImportName"]).lowercased()
            guard src.contains("dron") || src.contains("drone") else{continue}
            let m=arr(n["matrix"])
            guard m.count==16, !arr(n["children"]).isEmpty else{continue}
            let x=number(m[12]),z=number(m[14])
            let d=(x-mx)*(x-mx)+(z-mz)*(z-mz)
            guard d<=36 else{continue}
            candidates.append((text(extra["hangarLabPrefabId"]),x,z,d))
        }
        candidates.sort{$0.dist<$1.dist}
        guard candidates.count>=2 else{return []}
        return Set(candidates.prefix(2).map{$0.name})
    }
    static func fromGLB(_ url:URL)throws->Geometry {
        let bytes=try Data(contentsOf:url,options:.mappedIfSafe)
        guard bytes.count>=28,word(bytes,0)==0x46546c67,
              word(bytes,4)==2,word(bytes,8)==UInt32(bytes.count),
              word(bytes,16)==0x4e4f534a else{throw Invalid.glb}
        let len=Int(word(bytes,12)),binStart=20+len
        guard len>=2,binStart+8<=bytes.count,
              word(bytes,binStart+4)==0x004e4942 else{throw Invalid.glb}
        let binLen=Int(word(bytes,binStart))
        guard binStart+8+binLen<=bytes.count else{throw Invalid.glb}
        guard let json=try JSONSerialization.jsonObject(
             with:bytes.subdata(in:20..<(20+len))) as? D else{throw Invalid.glb}
        let nodes=arr(json["nodes"]).map{dict($0)}
        let meshes=arr(json["meshes"]).map{dict($0)}
        let accessors=arr(json["accessors"]).map{dict($0)}
        let views=arr(json["bufferViews"]).map{dict($0)}
        guard !nodes.isEmpty,nodes.count<=100000,meshes.count<=100000
        else{throw Invalid.scene}
        var parent=[Int](repeating:-1,count:nodes.count)
        for i in nodes.indices {
            for c in arr(nodes[i]["children"]) {
                let id=integer(c,-1)
                guard id>=0,id<nodes.count,parent[id] == -1
                else{throw Invalid.tree}
                parent[id]=i
            }
        }
        var worlds=[[Float]?](repeating:nil,count:nodes.count)
        var visit=[UInt8](repeating:0,count:nodes.count)
        func world(_ id:Int)throws->[Float] {
            if visit[id]==1 {throw Invalid.tree}
            if let m=worlds[id] {return m}
            visit[id]=1
            let p=try parent[id]>=0 ? world(parent[id]) : identity()
            let m=product(p,try local(nodes[id]))
            worlds[id]=m;visit[id]=2
            return m
        }
        let scenes=arr(json["scenes"]).map{dict($0)}
        let selected=integer(json["scene"])
        guard selected>=0 && selected<scenes.count else{throw Invalid.scene}
        var active=[Bool](repeating:false,count:nodes.count)
        var queue=arr(scenes[selected]["nodes"]).map{integer($0,-1)}
        while let i=queue.popLast() {
            guard i>=0 && i<nodes.count else{throw Invalid.tree}
            if active[i] {continue}
            active[i]=true
            queue.append(contentsOf:arr(nodes[i]["children"]).map{integer($0,-1)})
        }
        let movingDrones=selectedDrones(nodes)
        var group=[String?](repeating:nil,count:nodes.count)
        var portal=[Bool](repeating:false,count:nodes.count)
        for i in nodes.indices where active[i] {
            let n=nodes[i]
            var identifier=text(dict(n["extras"])["hangarLabPrefabId"])
            var isPortal=looksLikePortal(text(n["name"]))
            var ancestor=parent[i]
            while ancestor>=0 {
                let upper=nodes[ancestor]
                if identifier.isEmpty {
                    identifier=text(dict(upper["extras"])["hangarLabPrefabId"])
                }
                if looksLikePortal(text(upper["name"])) ||
                   looksLikePortal(text(dict(upper["extras"])["hangarLabImportName"])) {
                    isPortal=true
                }
                ancestor=parent[ancestor]
            }
            group[i]=identifier.isEmpty ? self.group(text(n["name"])) : identifier
            portal[i]=isPortal && group[i] != nil
        }
        var reader=Reader(bytes:bytes,accessors:accessors,views:views,
                          start:binStart+8,length:binLen)
        var boxes:[String:Box]=[:],portalPoints:[String:[Float]]=[:]
        var triangles:[Float]=[]
        triangles.reserveCapacity(7_000_000)
        var source=0,proxy=0,activeNodes=0,extents=Box()
        for i in nodes.indices where active[i] {
            activeNodes+=1
            let n=nodes[i],mesh=integer(n["mesh"],-1)
            if mesh<0 {continue}
            guard mesh<meshes.count else{throw Invalid.tree}
            let name=text(n["name"])
            if let g=group[i],movingDrones.contains(g) {continue}
            if integer(n["skin"],-1)>=0 &&
               name.hasPrefix("HL_Import_2023_space_suit_3d_model_ca_o_c_animacji_-_najleps_") {
                continue
            }
            let door=name.hasPrefix("H70_HANGAR_AIRLOCK_") ||
                     name.hasPrefix("H70_WORKSHOP_AIRLOCK_")
            let transform=try world(i)
            for op in arr(meshes[mesh]["primitives"]) {
                let prim=dict(op)
                if integer(prim["mode"],4) != 4 {continue}
                let posId=integer(dict(prim["attributes"])["POSITION"],-1)
                if posId<0 {continue}
                let local=try reader.pos(posId)
                let positions=transformed(local,transform)
                for p in stride(from:0,to:positions.count,by:3) {
                    extents.expand(positions[p],positions[p+1],positions[p+2])
                }
                let inds=try reader.inds(integer(prim["indices"],-1),
                                         positions.count/3)
                guard inds.count%3==0 else{throw Invalid.accessor}
                source+=inds.count/3
                if let g=group[i] {
                    var box=boxes[g] ?? Box(name:g)
                    for p in stride(from:0,to:positions.count,by:3) {
                        box.expand(positions[p],positions[p+1],positions[p+2])
                    }
                    boxes[g]=box
                    if portal[i] {portalPoints[g,default:[]].append(contentsOf:positions)}
                    proxy+=inds.count/3
                    continue
                }
                if door {continue}
                for k in stride(from:0,to:inds.count,by:3) {
                    let ia=inds[k]*3,ib=inds[k+1]*3,ic=inds[k+2]*3
                    guard ia>=0,ib>=0,ic>=0,ia+2<positions.count,
                          ib+2<positions.count,ic+2<positions.count
                    else{throw Invalid.accessor}
                    let ax=positions[ia],ay=positions[ia+1],az=positions[ia+2]
                    let bx=positions[ib],by=positions[ib+1],bz=positions[ib+2]
                    let cx=positions[ic],cy=positions[ic+1],cz=positions[ic+2]
                    let ux=bx-ax,uy=by-ay,uz=bz-az
                    let vx=cx-ax,vy=cy-ay,vz=cz-az
                    let px=uy*vz-uz*vy,py=uz*vx-ux*vz,pz=ux*vy-uy*vx
                    if px*px+py*py+pz*pz<=1e-11 || !px.isFinite ||
                       !py.isFinite || !pz.isFinite {continue}
                    let minX=min(ax,min(bx,cx)),maxX=max(ax,max(bx,cx))
                    let minY=min(ay,min(by,cy)),maxY=max(ay,max(by,cy))
                    let minZ=min(az,min(bz,cz)),maxZ=max(az,max(bz,cz))
                    if maxX>25.5 && minX<30.65 && maxZ>6.25 &&
                       minZ<8.05 && minY >= -0.02 && maxY<2.22 {
                        continue
                    }
                    triangles.append(contentsOf:[ax,ay,az,bx,by,bz,cx,cy,cz])
                }
            }
        }
        // Exact world-space corridor bridge from HangarCollision441.cs:188.
        triangles.append(contentsOf:[
            23.9,0,6,27.7,0,6,27.7,0,8.5,
            23.9,0,6,27.7,0,8.5,23.9,0,8.5,
            27.7,0,6,31.4,0,6,31.4,0,8.5,
            27.7,0,6,31.4,0,8.5,27.7,0,8.5,
            31.4,0,6,34,0,6,34,0,8.5,
            31.4,0,6,34,0,8.5,31.4,0,8.5
        ])
        var resolved:[Box]=[]
        resolved.reserveCapacity(boxes.count+portalPoints.count*2)
        for (key,b) in boxes {
            if let points=portalPoints[key],
               let pieces=splitPortal(b,points) {
                resolved.append(contentsOf:pieces)
            } else {
                resolved.append(b)
            }
        }
        guard triangles.count>=90000,!resolved.isEmpty,extents.valid
        else{throw Invalid.geometry}
        return Geometry(triangles:triangles,objects:resolved,
            sourceTriangles:source,proxyTriangles:proxy,
            sceneNodes:activeNodes,minX:extents.x0,maxX:extents.x1,
            minZ:extents.z0,maxZ:extents.z1)
    }
}
