import Foundation

@main enum H55RenderStartGate580Tests {
    static func main() {
        var gate=H55RenderStartGate580()
        precondition(!gate.started && gate.renderedFrames==0)
        precondition(!gate.didRenderFrame() && !gate.started)
        precondition(!gate.didRenderFrame() && gate.renderedFrames==2)
        precondition(gate.didRenderFrame() && gate.started,
                     "start immediately after third actual render callback")
        for _ in 0..<120 {
            precondition(!gate.didRenderFrame() && gate.renderedFrames==3,
                         "never restart a 3.25s arrival")
        }
        gate.reset()
        precondition(!gate.started && gate.renderedFrames==0)
        precondition(!gate.didRenderFrame() && !gate.didRenderFrame())
        precondition(gate.didRenderFrame(),
                     "new imported H55 scene must start its own 3.25s arrival")
        print("PASS: 3 completed SceneKit frames before PC580 H55 cinematic clock; restart/resume gates")
    }
}
