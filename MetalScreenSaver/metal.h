//
//  metal.h
//  MetalScreenSaver
//
//  Created by Felix Naredi on 2019-05-17.
//

#ifndef metal_h
#define metal_h

@import Metal;

_Nullable id<MTLLibrary> mss_bundle_default_metallib(const id<MTLDevice> device,
                                                     char * _Nonnull bundleIdentifier);

_Nullable id<MTLRenderPipelineState>
mss_make_render_pipeline_state(_Nonnull id<MTLDevice> device,
                               MTLRenderPipelineDescriptor * _Nonnull descriptor);

id<MTLTexture> mss_make_msaa_texture(_Nonnull id<MTLDevice> device,
                                     uint width,
                                     uint height,
                                     uint sampleCount);

void mss_clear_texture(id<MTLDevice> device,
                       id<MTLCommandBuffer> commandBuffer,
                       id<MTLTexture> texture);

#endif /* metal_h */
