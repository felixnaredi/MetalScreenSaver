//
//  MetalScreenSaver.h
//  MetalScreenSaver
//
//  Created by Felix Naredi on 2019-05-05.
//

@import Foundation;
@import Metal;

_Nullable id<MTLLibrary> MSSNewDefaultBundleLibrary(const id<MTLDevice> device,
                                                    char * _Nonnull bundleIdentifier);

_Nullable id<MTLRenderPipelineState>
MSSMakeRenderPipelineState(_Nonnull id<MTLDevice> device,
                           MTLRenderPipelineDescriptor * _Nonnull descriptor);

id<MTLTexture> MSSNewMSAATexture(_Nonnull id<MTLDevice> device,
                                 uint width,
                                 uint height,
                                 uint sampleCount);
