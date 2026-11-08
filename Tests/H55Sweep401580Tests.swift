import Foundation

@main struct H55Sweep401580Tests {
    private static func check(_ v:Bool,_ s:String){precondition(v,"H04 SWEEP: "+s)}
    static func main() {
        // The PC source only eliminates displacement INTO an outward wall.
        let into=H55Sweep401580.slide(dx:0.5,dz:0.2,nx:-1,nz:0)
        check(abs(into.x)<0.000001 && abs(into.z-0.2)<0.000001,
              "source inward wall projection preserves tangent")
        let away=H55Sweep401580.slide(dx:-0.5,dz:0.2,nx:-1,nz:0)
        check(abs(away.x+0.5)<0.000001 && abs(away.z-0.2)<0.000001,
              "outward movement remains unchanged")
        typealias G=H55CollisionGeometry580
        let wall:[Float]=[
            10,0.6,9, 10,1.8,9, 10,0.6,11,
            10,1.8,9, 10,1.8,11, 10,0.6,11
        ]
        let geometry=G.Geometry(triangles:wall,objects:[],
               sourceTriangles:2,proxyTriangles:0,sceneNodes:1,
               minX:-30,maxX:50,minZ:-20,maxZ:20)
        let col=H55SpatialSupport580(geometry:geometry)
        typealias P=H55Sweep401580.Position
        var calls=0
        let move:(P,Float,Float)->P={state,dx,dz in
            calls+=1
            let nx=state.x+dx,nz=state.z+dz
            if !col.bodyClear379(nx,feet:state.feet,nz) {return state}
            return P(x:nx,feet:state.feet,z:nz)
        }
        let start=P(x:9.2,feet:0,z:9.6)
        let stopped=H55Sweep401580.sweep(
            collision:col,from:start,vx:1.8,vz:0,moveHubAxis:move)
        // Original ContactNormal401 is derived from triangle overlap energy.
        // It can add a SMALL tangential Z motion even for X-only input;
        // that is the intended source v401 wall-slide, not axis drift.
        check(stopped.x>=start.x && stopped.x<9.8 &&
              col.bodyClear379(stopped.x,feet:stopped.feet,stopped.z) &&
              hypot(stopped.x-start.x,stopped.z-start.z)<=1.8001,
              "source swept motion must remain outside wall, without added energy")
        check(calls>=20 && calls<=60,"source bounded max 20 substeps")
        let before=calls
        let clear=H55Sweep401580.sweep(
            collision:col,from:P(x:11.1,feet:0,z:9.6),
            vx:0.11,vz:0,moveHubAxis:move)
        check(abs(clear.x-11.21)<0.00001 &&
              calls-before==3,"source 5cm steps in empty space")
        print("PASS H04 v401 original wall tangent projection, exact capsule swept collision, bounded 20 substeps and clear translation")
    }
}
