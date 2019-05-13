//
//  MetalScreenSaver.h
//  MetalScreenSaver
//
//  Created by Felix Naredi on 2019-05-05.
//

@import Foundation;
@import Metal;


FOUNDATION_EXPORT _Nullable id<MTLLibrary> MSSNewDefaultBundleLibrary(const id<MTLDevice> device,
                                                    char * _Nonnull bundleIdentifier);

FOUNDATION_EXPORT _Nullable id<MTLRenderPipelineState>
MSSMakeRenderPipelineState(_Nonnull id<MTLDevice> device,
                           MTLRenderPipelineDescriptor * _Nonnull descriptor);

