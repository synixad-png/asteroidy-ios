import SwiftUI
import MetalKit
import simd

/// Real native original Explosion524 Metal preview — the same 3D
/// raymarch pipeline used during CARBONIS combat, not an illustration.
struct CarbonisExplosion524Preview568: UIViewRepresentable {
    let settings:CarbonisVisualSettings568
    let revision:Int
    let budget:CarbonisIOSFXBudget568

    func makeCoordinator()->Coordinator {Coordinator()}
    func makeUIView(context:Context)->MTKView {
        let view=MTKView(frame:.zero)
        view.device=MTLCreateSystemDefaultDevice()
        view.colorPixelFormat = .bgra8Unorm
        view.depthStencilPixelFormat = .depth32Float
        view.clearColor=MTLClearColor(red:0.004,green:0.016,
                                     blue:0.028,alpha:1)
        view.clearDepth=1
        view.preferredFramesPerSecond=30
        view.isPaused=false
        view.enableSetNeedsDisplay=false
        if let device=view.device {
            do {
                let renderer=try Renderer(device:device,settings:settings,
                                          revision:revision,budget:budget)
                context.coordinator.renderer=renderer
                view.delegate=renderer
            } catch {
                NSLog("Explosion524 native preview unavailable: %@",
                      String(describing:error))
            }
        }
        return view
    }
    func updateUIView(_ view:MTKView,context:Context) {
        guard let renderer=context.coordinator.renderer else {return}
        renderer.update(settings:settings,revision:revision,budget:budget)
    }

    final class Coordinator {
        var renderer:Renderer?
    }
    final class Renderer:NSObject,MTKViewDelegate {
        private let queue:MTLCommandQueue
        private let explosions:CarbonisExplosion524Renderer
        private var started=ProcessInfo.processInfo.systemUptime
        private var settings:CarbonisVisualSettings568
        private var revision:Int
        private var budget:CarbonisIOSFXBudget568
        private let center=Vec2(x:640,y:360)
        private var state=CarbonisDestruction524()

        init(device:MTLDevice,
             settings:CarbonisVisualSettings568,revision:Int,
             budget:CarbonisIOSFXBudget568) throws {
            enum Setup:Error {case missing}
            guard let command=device.makeCommandQueue(),
                  let library=try? device.makeDefaultLibrary(bundle:.main)
            else {throw Setup.missing}
            self.queue=command
            explosions=try CarbonisExplosion524Renderer(
                device:device,library:library)
            self.settings=settings
            self.revision=revision
            self.budget=budget
            super.init()
            reset()
        }
        private func reset() {
            started=ProcessInfo.processInfo.systemUptime
            state=CarbonisDestruction524()
            state.explosion(at:center,kind:settings.type,scale:14,time:0)
        }
        func update(settings:CarbonisVisualSettings568,
                    revision:Int,budget:CarbonisIOSFXBudget568) {
            let typeChanged=self.settings.type != settings.type
            let revisionChanged=self.revision != revision
            let budgetChanged=self.budget != budget
            self.settings=settings
            self.revision=revision
            self.budget=budget
            if typeChanged || revisionChanged || budgetChanged {reset()}
        }
        func mtkView(_ view:MTKView,
                     drawableSizeWillChange size:CGSize) {}
        private func projection(_ camera:SphereCamera67,
                                aspect:Float)->simd_float4x4 {
            let v=SphereCameraView556(camera:camera).viewColumnMajor
            let m=simd_float4x4(columns:(
                SIMD4<Float>(v[0],v[1],v[2],v[3]),
                SIMD4<Float>(v[4],v[5],v[6],v[7]),
                SIMD4<Float>(v[8],v[9],v[10],v[11]),
                SIMD4<Float>(v[12],v[13],v[14],v[15])))
            let near=SphereProjection556.normalizedNear
            let far=SphereProjection556.normalizedFar
            let f=SphereProjection556.sourceVerticalFocal
            let p=simd_float4x4(columns:(
                SIMD4<Float>(f/max(0.35,aspect),0,0,0),
                SIMD4<Float>(0,f,0,0),
                SIMD4<Float>(0,0,far/(near-far),-1),
                SIMD4<Float>(0,0,near*far/(near-far),0)))
            return p*m
        }
        func draw(in view:MTKView) {
            guard let drawable=view.currentDrawable,
                  let pass=view.currentRenderPassDescriptor,
                  let command=queue.makeCommandBuffer(),
                  let encoder=command.makeRenderCommandEncoder(
                    descriptor:pass)
            else {return}
            let now=ProcessInfo.processInfo.systemUptime
            // The quality option also controls the genuine Metal preview.
            // Short blasts replay instead of leaving an empty demo window.
            let duration=budget.explosionsReduced
                ? Double(budget.explosionDuration(
                    settings.explosionDuration)+0.3)
                : max(4.1,Double(settings.explosionDuration))
            let age=Float((now-started).truncatingRemainder(
                dividingBy:duration))
            var camera=SphereCamera67(at:center)
            if settings.autoRotate {
                let phase=Float(now-started)*0.26
                let right=camera.right*cos(phase)+camera.up*sin(phase)
                camera.right=right.normalized
                camera.up=SphereVector3.cross(
                    camera.focus,camera.right).normalized
            }
            let width=Float(max(1,view.drawableSize.width))
            let height=Float(max(1,view.drawableSize.height))
            explosions.render(state,time:age,camera:camera,
                vp:projection(camera,aspect:width/height),
                settings:settings,budget:budget,into:encoder)
            encoder.endEncoding()
            command.present(drawable)
            command.commit()
        }
    }
}
