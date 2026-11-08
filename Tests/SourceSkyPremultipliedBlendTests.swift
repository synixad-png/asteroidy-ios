import Metal

/// Real Apple Metal descriptor test. No GPU, drawable or source textures needed:
/// confirms exact blending fields before the renderer builds any pipeline.
@main struct SourceSkyPremultipliedBlendTests {
    static func main() throws {
        let descriptor=MTLRenderPipelineDescriptor()
        // The helper itself must set the source BGRA8 target after validation.
        descriptor.depthAttachmentPixelFormat = .depth32Float
        try SourceSkyPremultipliedBlend.configure(descriptor)

        guard let blend=descriptor.colorAttachments[0] else {
            preconditionFailure("Metal color attachment 0 unexpectedly absent")
        }
        precondition(blend.isBlendingEnabled)
        precondition(blend.sourceRGBBlendFactor == .one)
        precondition(blend.destinationRGBBlendFactor == .oneMinusSourceAlpha)
        precondition(blend.sourceAlphaBlendFactor == .one)
        precondition(blend.destinationAlphaBlendFactor == .oneMinusSourceAlpha)
        precondition(blend.rgbBlendOperation == .add)
        precondition(blend.alphaBlendOperation == .add)
        precondition(blend.pixelFormat == .bgra8Unorm)
        precondition(descriptor.depthAttachmentPixelFormat == .depth32Float)

        // Original descriptor remains mutable and reusable; the helper
        // configures rather than replacing it or allocating GPU resources.
        try SourceSkyPremultipliedBlend.configure(descriptor)
        precondition(blend.isBlendingEnabled)
        precondition(blend.destinationRGBBlendFactor == .oneMinusSourceAlpha)
        print("PASS: source PArgb blending from actual Metal descriptors; pixel format, depth and additive operations unchanged")
    }
}
