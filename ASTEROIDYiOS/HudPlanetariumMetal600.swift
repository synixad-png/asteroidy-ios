import Foundation
import MetalKit
import simd
import QuartzCore

/// PC v602 planetarium, native Metal screen-space pass.
/// Uses the same already-presented CAMetalDrawable and command buffer as
/// the four working pickup HUD models; never a SceneKit view or world actor.
/// Only the 159 authored glTF node tracks animate — F6 position stays fixed.
final class HudPlanetariumMetal600 {
    // The three plasma bars already use the same 0.78 HUD motion weight.
    // Match that *visual transform only*: all four widgets keep their
    // original, independently editable F6 x/y/scale. No endpoint tether.
    private static let plasmaGroupMotionID="armor.bar"
    enum Failure:Error {case missingOriginal, missingShader, invalidPipeline}
    private struct Uniforms {
        var mvp:simd_float4x4
        var baseColor:SIMD4<Float>
    }
    private let original:HudPlanetariumOriginal600
    private let opaque:MTLRenderPipelineState
    private let translucent:MTLRenderPipelineState
    private let solidDepth:MTLDepthStencilState
    private let transparentDepth:MTLDepthStencilState

    init(device:MTLDevice,originalURL:URL?) throws {
        guard let originalURL else{throw Failure.missingOriginal}
        original=try HudPlanetariumOriginal600(originalURL:originalURL,device:device)
        guard let lib=device.makeDefaultLibrary(),
              let vertex=lib.makeFunction(name:"hudPlanetariumVertex600"),
              let fragment=lib.makeFunction(name:"hudPlanetariumFragment600")
        else{throw Failure.missingShader}
        let spec=MTLRenderPipelineDescriptor()
        spec.label="PC602_Original_HUD_Planetarium"
        spec.vertexFunction=vertex
        spec.fragmentFunction=fragment
        spec.colorAttachments[0].pixelFormat = .bgra8Unorm
        spec.depthAttachmentPixelFormat = .depth32Float
        opaque=try device.makeRenderPipelineState(descriptor:spec)
        spec.colorAttachments[0].isBlendingEnabled=true
        spec.colorAttachments[0].rgbBlendOperation = .add
        spec.colorAttachments[0].alphaBlendOperation = .add
        spec.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        spec.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        spec.colorAttachments[0].sourceAlphaBlendFactor = .one
        spec.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
        translucent=try device.makeRenderPipelineState(descriptor:spec)
        let d=MTLDepthStencilDescriptor()
        d.depthCompareFunction = .lessEqual
        d.isDepthWriteEnabled=true
        guard let opaqueState=device.makeDepthStencilState(descriptor:d)
        else{throw Failure.invalidPipeline}
        solidDepth=opaqueState
        d.isDepthWriteEnabled=false
        guard let transState=device.makeDepthStencilState(descriptor:d)
        else{throw Failure.invalidPipeline}
        transparentDepth=transState
    }

    private static func translate(_ x:Float,_ y:Float,_ z:Float)->simd_float4x4 {
        var m=matrix_identity_float4x4
        m.columns.3=SIMD4<Float>(x,y,z,1)
        return m
    }
    private static func scale(_ x:Float,_ y:Float,_ z:Float)->simd_float4x4 {
        var m=matrix_identity_float4x4
        m.columns.0.x=x;m.columns.1.y=y;m.columns.2.z=z
        return m
    }

    /// This is the original PC HudGlbAssets.DrawHudGlb F6 transform:
    /// ortho on complete screen, translate centre, yaw/pitch/roll,
    /// scale 0.44*widgetWidth*F6 scale/modelRadius,
    /// translate(-PlanetModelCenter463).
    private static func hudMatrix(
            _ projection:HudPlanetariumProjection.Transform,
            width:Double,height:Double,
            widget:HudLayout600.Widget,
            pose:HudMotion600.Pose)->simd_float4x4 {
        let w=Float(width),h=Float(height)
        var ortho=matrix_identity_float4x4
        ortho.columns.0.x=2/w
        ortho.columns.1.y=2/h
        // World Z is isolated from the original planet's depth attachment.
        // Clip-space Z is Metal's [0,1], with positive model Z closer.
        ortho.columns.2.z = -0.0005
        ortho.columns.3.z = 0.5
        let yaw=simd_float4x4(simd_quatf(
            angle:Float(widget.yaw ?? 0)*Float.pi/180,
            axis:SIMD3<Float>(0,1,0)))
        let pitch=simd_float4x4(simd_quatf(
            angle:Float(widget.pitch ?? -20)*Float.pi/180,
            axis:SIMD3<Float>(1,0,0)))
        // Keep the approved F6 model orientation but inherit the same
        // 0.78 live HUD bank as all three freely editable plasma bars.
        let rollDegrees=Float(widget.roll ?? 0) +
            pose.roll*pose.weight(Self.plasmaGroupMotionID)
        let roll=simd_float4x4(simd_quatf(
            angle:rollDegrees*Float.pi/180,
            axis:SIMD3<Float>(0,0,1)))
        let pixels=Float(projection.pixelsPerModelUnit)
        return ortho *
            translate(Float(projection.x),Float(projection.y),0) *
            yaw*pitch*roll *
            scale(pixels,pixels,pixels) *
            translate(-HudPlanetariumAsset600.pc602ModelCenterX,
                      -HudPlanetariumAsset600.pc602ModelCenterY,
                      -HudPlanetariumAsset600.pc602ModelCenterZ)
    }

    func render(command:MTLCommandBuffer,
                drawable:CAMetalDrawable,
                depthTexture:MTLTexture?,
                layout:HudLayout600,
                viewport:CombatHUDViewport568,
                pose:HudMotion600.Pose,
                seconds:Double,
                capsules:HudCapsuleController600.Snapshot) {
        guard let widget=layout.widget("hud.planetarium"),
              widget.visible,
              let placement=HudWidgetPlacement600.frame(widget,
                  sourceWidth:250,sourceHeight:135,
                  anchor:.bottomLeft,viewport:viewport),
              let projection=HudPlanetariumProjection.make(
                  placement:placement,viewport:viewport,
                  widget:widget,
                  modelRadius:HudPlanetariumAsset600.pc602ModelRadius),
              let depthTexture,
              drawable.texture.width>1,drawable.texture.height>1
        else{return}

        // The previous (world + four pickups) encoder has ended. Clear only
        // depth, never the finished game color. This is the PC's isolated
        // HUD depth pass in the SAME native Metal command buffer.
        let pass=MTLRenderPassDescriptor()
        pass.colorAttachments[0].texture=drawable.texture
        pass.colorAttachments[0].loadAction = .load
        pass.colorAttachments[0].storeAction = .store
        pass.depthAttachment.texture=depthTexture
        pass.depthAttachment.loadAction = .clear
        pass.depthAttachment.storeAction = .dontCare
        pass.depthAttachment.clearDepth=1
        guard let encoder=command.makeRenderCommandEncoder(descriptor:pass)
        else{return}
        encoder.label="PC602_Original_Animated_HUD_Planetarium"
        encoder.setCullMode(.none)
        let frame=original.sample(at:seconds,capsules:capsules)
        // A single visual HUD transform (same as plasma bars) stops
        // differential rotation/sway. Each child still has its OWN
        // F6 coordinates: moving the planetarium or any gauge never
        // changes the other widgets or requires a fixed plasma endpoint.
        let screenPose=HudMotionProject600.project(
            x:widget.x+125,y:widget.y+67.5,pose:pose,
            widget:Self.plasmaGroupMotionID)
        let centerX=viewport.x(screenPose.x,at:.bottomLeft)
        let centerY=viewport.y(screenPose.y,at:.bottomLeft)
        let attached=HudPlanetariumProjection.Transform(
            x:centerX-viewport.width*0.5,
            y:viewport.height*0.5-centerY,
            pixelsPerModelUnit:projection.pixelsPerModelUnit,
            cameraHalfHeight:projection.cameraHalfHeight)
        let hud=Self.hudMatrix(attached,
                width:viewport.width,height:viewport.height,
                widget:widget,pose:pose)

        for mode in 0...1 {
            encoder.setRenderPipelineState(mode==0 ? opaque:translucent)
            encoder.setDepthStencilState(mode==0 ? solidDepth:transparentDepth)
            for idx in original.drawOrder {
                let node=original.nodes[idx]
                guard !frame.hidden[idx],let mesh=node.mesh else{continue}
                let mvp=hud*frame.world[idx]
                for part in original.parts[mesh] where
                    (part.material == 0) == (mode == 0) {
                    var uniform=Uniforms(mvp:mvp,baseColor:part.tint)
                    encoder.setVertexBuffer(part.buffer,offset:0,index:0)
                    encoder.setVertexBytes(&uniform,
                       length:MemoryLayout<Uniforms>.stride,index:1)
                    encoder.drawPrimitives(type:.triangle,vertexStart:0,
                                           vertexCount:part.vertices)
                }
            }
        }
        encoder.endEncoding()
    }
}
