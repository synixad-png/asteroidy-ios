import Foundation

/// PC v600 RendererHudEnergy.cs: deterministic screen-space energy field.
/// Geometry is produced at draw time; never allocates GPU textures or affects damage.
enum HudEnergy600 {
    struct Point {
        var x:Double
        var y:Double
    }
    static func clamp(_ v:Double)->Double {max(0,min(1,v.isFinite ? v:0))}
    static func fraction(_ value:Int?,maximum:Int)->Double {
        clamp(Double(max(0,value ?? 0))/Double(max(1,maximum)))
    }
    static func wave(_ x:Double,time:Double,seed:Double)->Double {
        0.53*sin(x*17.3-time*2.9+seed)
        + 0.30*sin(x*41.7+time*4.3+seed*1.73)
        + 0.17*sin(x*82.9-time*5.8+seed*0.57)
    }
    static func radius(layer:Int)->Double {
        [9.1,6.9,4.1,2.35,0.78][max(0,min(4,layer))]
    }
    static func ribbon(x:Double,y:Double,width:Double,length:Double,
                       time:Double,style:Int,layer:Int)->[Point] {
        let width=max(1,width),length=max(0,min(width,length))
        guard length>0.05 else {return []}
        let steps=max(4,min(34,Int(ceil(length/5))))
        let jitter=[2.6,2.35,1.65,0.88,0.36][max(0,min(4,layer))]
        let r=radius(layer:layer)
        var top=[Point](),bottom=[Point]()
        top.reserveCapacity(steps+1);bottom.reserveCapacity(steps+1)
        for i in 0...steps {
            let local=length*Double(i)/Double(steps)
            let coordinate=local/width
            let flow=0.42*sin(coordinate*8.1-time*2.1+Double(style)*0.73)
            let a=wave(coordinate,time:time,seed:Double(style)*0.91+1.2)
            let b=wave(coordinate,time:time,seed:Double(style)*0.67+3.8)
            let cap=min(1,max(0.16,min((local+3)/6,(length-local+2)/7)))
            let half=r*cap
            top.append(Point(x:x+local,y:y+4.5+flow-half+a*jitter*cap))
            bottom.append(Point(x:x+local,y:y+4.5+flow+half+b*jitter*cap))
        }
        return top+Array(bottom.reversed())
    }
}