import Metal

/// GpuIntro41/IntroSky: source PArgb blending (ONE, ONE_MINUS_SRC_ALPHA).
/// Shared by the original solar, nebula and black-hole shader pipelines.
/// Called only when initializing Metal render pipelines, never per frame.
enum SourceSkyPremultipliedBlend {
    enum ConfigurationError: Error {
        case missingColorAttachment
    }

    static func configure(_ descriptor: MTLRenderPipelineDescriptor) throws {
        guard let attachment=descriptor.colorAttachments[0] else {
            throw ConfigurationError.missingColorAttachment
        }
        attachment.isBlendingEnabled=true
        attachment.sourceRGBBlendFactor = .one
        attachment.destinationRGBBlendFactor = .oneMinusSourceAlpha
        attachment.sourceAlphaBlendFactor = .one
        attachment.destinationAlphaBlendFactor = .oneMinusSourceAlpha
    }
}
