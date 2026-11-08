import Metal

/// GpuIntro41/IntroSky: source PArgb blending (ONE, ONE_MINUS_SRC_ALPHA).
/// Shared by the original solar, nebula and black-hole shader pipelines.
/// Called only when initializing Metal render pipelines, never per frame.
enum MetalBlendAttachmentError: Error {
    case missingColorAttachment
}

enum SourceSkyPremultipliedBlend {

    static func configure(_ descriptor: MTLRenderPipelineDescriptor) throws {
        guard let attachment=descriptor.colorAttachments[0] else {
            throw MetalBlendAttachmentError.missingColorAttachment
        }
        // All four source sky pipeline passes use the same BGRA8 target.
        // Set it only AFTER verifying the attachment exists.
        attachment.pixelFormat = .bgra8Unorm
        attachment.isBlendingEnabled=true
        attachment.sourceRGBBlendFactor = .one
        attachment.destinationRGBBlendFactor = .oneMinusSourceAlpha
        attachment.sourceAlphaBlendFactor = .one
        attachment.destinationAlphaBlendFactor = .oneMinusSourceAlpha
    }
}
