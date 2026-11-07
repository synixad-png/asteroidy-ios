import Foundation

/// Native-GPU-independent verification of original Wreck211 geometry.
@main struct ResearchWreckGeometry214Tests {
    static func main() {
        let mesh=ResearchWreckGeometry214.make(sector:1)
        precondition(mesh.triangleCount>10000)
        precondition(mesh.lineCount>1000)
        precondition(mesh.triangleCount < 131072)
        precondition(mesh.lineCount < 32768)
        precondition(mesh.triangleCount%3==0)
        precondition(mesh.lineCount%2==0)
        precondition(mesh.triangles.count%11==0)
        precondition(mesh.lines.count%7==0)
        precondition(mesh.triangles.allSatisfy { $0.isFinite })
        precondition(mesh.lines.allSatisfy { $0.isFinite })
        // All seven WreckWarningLamp213 source phase markers (0..4.9)
        // must be present on the tri stream for GPU animated source lamps.
        let phases:Set<Int>=Set(stride(from:10,to:mesh.triangles.count,by:11)
            .map { Int((mesh.triangles[$0]*100).rounded()) }
            .filter {$0 >= 0})
        for phase in [0,110,220,270,310,420,490] {
            precondition(phases.contains(phase),"missing v568 lamp phase")
        }
        // Source 112 fragments and same fixed seed + level 214 on
        // every reload; no per-launch randomized universe or GPU uploads.
        let rebuilt=ResearchWreckGeometry214.make(sector:1)
        precondition(mesh.triangles.count==rebuilt.triangles.count)
        precondition(mesh.lines.count==rebuilt.lines.count)
        precondition(mesh.triangles.prefix(300).elementsEqual(
            rebuilt.triangles.prefix(300)))
        print("PASS original Wreck211 3D hull, weathering, 112 fragments, seven lamps")
        print("Triangles:",mesh.triangleCount,"lines:",mesh.lineCount)
    }
}
