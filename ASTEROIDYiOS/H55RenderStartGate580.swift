import Foundation

/// Presentation readiness is distinct from GLB parse completion.
/// The 3.25s PC580 approach must not tick while SceneKit prepares its
/// first texture uploads, shader pipelines or drawable. Exactly three
/// completed render callbacks are needed to unmask and START the clock.
/// This counter is independent of gameplay physics and H51/H70 timing.
struct H55RenderStartGate580 {
    private(set) var renderedFrames:Int=0
    private(set) var started:Bool=false

    mutating func didRenderFrame()->Bool {
        guard !started else{return false}
        renderedFrames += 1
        guard renderedFrames>=3 else{return false}
        started=true
        return true
    }
    mutating func reset() {
        renderedFrames=0
        started=false
    }
}
