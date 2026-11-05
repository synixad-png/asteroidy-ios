import Foundation
@main struct TestTelemetry {
    static func main() {
        let t = RenderTelemetry(capacity: 4)
        for ms in [1.0,2.0,3.0,4.0,5.0] { t.record(.morphCPU,seconds:ms/1000) }
        t.record(.uploadCPU,seconds:Double.nan)
        t.record(.uploadCPU,seconds:-1)
        t.noteUpload(success:true)
        t.noteUpload(success:false)
        let s = t.snapshot()
        precondition(s.uploads == 1 && s.skipped == 1)
        precondition(s.stages[.morphCPU]!.samples == 4)
        precondition(abs(s.stages[.morphCPU]!.meanMS - 3.5) < 0.00001)
        precondition(abs(s.stages[.morphCPU]!.p95MS - 5) < 0.00001)
        precondition(s.stages[.uploadCPU] == nil)
        let g = DispatchGroup()
        for _ in 0..<8 { g.enter(); DispatchQueue.global().async {
            for _ in 0..<1000 { t.record(.gpuExecution,seconds:0.0005);t.noteUpload(success:true) }
            g.leave()
        } }
        g.wait()
        precondition(t.snapshot().uploads == 8001)
        precondition(t.snapshot().stages[.gpuExecution]?.samples == 4)
        print("RenderTelemetry: PASS")
    }
}
