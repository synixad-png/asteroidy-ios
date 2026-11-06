import Foundation

@main struct CarbonisShooterMesh71Tests {
    static func main() {
        var count=0
        func check(_ pass:Bool,_ name:String) {
            precondition(pass,name)
            count+=1
        }
        let mesh=CarbonisShooterMesh71.typeZero()
        check(mesh.vertices.count>3600,"actual full procedural 3D model")
        check(mesh.vertices.count%36==0,"three 12-float GPU vertices/triangle")
        check(mesh.ranges.count==8,"source 8 BossMesh65 material parts")
        check(mesh.ranges.first!.lowerBound==0,"zero base offset")
        check(mesh.ranges.last!.upperBound==mesh.vertices.count/12,"complete parts")
        check(mesh.ranges.allSatisfy({$0.count%3==0}),"material triangle partition")
        check(mesh.ranges.allSatisfy({!$0.isEmpty}),"original detailed material layers")
        for i in 0..<(mesh.ranges.count-1) {
            check(mesh.ranges[i].upperBound==mesh.ranges[i+1].lowerBound,
                  "contiguous source part boundaries")
        }
        var minX:Float=Float.infinity,maxX:Float = -Float.infinity
        var minY:Float=Float.infinity,maxY:Float = -Float.infinity
        var minZ:Float=Float.infinity,maxZ:Float = -Float.infinity
        for i in stride(from:0,to:mesh.vertices.count,by:12) {
            let d=mesh.vertices
            check(d[i].isFinite && d[i+1].isFinite && d[i+2].isFinite,
                  "finite source position")
            check(d[i+3].isFinite && d[i+4].isFinite && d[i+5].isFinite,
                  "finite source normal")
            check((0...1).contains(d[i+6]) && (0...1).contains(d[i+7])
                  && (0...1).contains(d[i+8]) && d[i+9]==1,
                  "source per-material RGBA")
            check(d[i+10]==0 && d[i+11]==0,
                  "zero-only UV padding (original source has 10 floats)")
            minX=min(minX,d[i]);maxX=max(maxX,d[i])
            minY=min(minY,d[i+1]);maxY=max(maxY,d[i+1])
            minZ=min(minZ,d[i+2]);maxZ=max(maxZ,d[i+2])
        }
        check(minX < -0.7 && maxX > 0.7,"full left/right combat wings")
        check(minY < -1.1 && maxY > 2.1,"source kind0 hull nose and rear")
        check(minZ < -0.15 && maxZ > 0.5,"3D fins and engines, not billboard")
        let other=CarbonisShooterMesh71.typeZero()
        check(other.vertices==mesh.vertices && other.ranges==mesh.ranges,
              "deterministic source construction")
        check(mesh.triangleCount>800,"source full detailed mesh")
        print("PASS \(count) authentic first-wave fighter source mesh assertions, \(mesh.triangleCount) triangles")
    }
}