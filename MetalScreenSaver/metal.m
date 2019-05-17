//
//  metal.c
//  MetalScreenSaver
//
//  Created by Felix Naredi on 2019-05-17.
//

@import Metal;

#include "metal.h"
#include <os/log.h>

_Nullable id<MTLLibrary> mss_bundle_default_metallib(const id<MTLDevice> device,
                                                     char * _Nonnull bundleIdentifier)
{
    NSBundle *bundle =
    [NSBundle bundleWithIdentifier:[NSString stringWithCString:bundleIdentifier
                                                      encoding:NSUTF8StringEncoding]];
    NSError *error = NULL;
    id<MTLLibrary> library = [device newDefaultLibraryWithBundle:bundle error:&error];
    if (!library) {
        os_log_error(OS_LOG_DEFAULT, "Failed to create library %@", error);
        return NULL;
    }
    return library;
}

_Nullable id<MTLRenderPipelineState>
mss_make_render_pipeline_state(_Nonnull id<MTLDevice> device,
                               MTLRenderPipelineDescriptor * _Nonnull descriptor)
{
    NSError *error = NULL;
    id<MTLRenderPipelineState> renderState =
    [device newRenderPipelineStateWithDescriptor:descriptor error:&error];
    if (!renderState) {
        os_log_error(OS_LOG_DEFAULT, "Failed to create render pipeline state, %@", error);
        return NULL;
    }
    return renderState;
}

id<MTLTexture> mss_make_msaa_texture(_Nonnull id<MTLDevice> device,
                                     uint width,
                                     uint height,
                                     uint sampleCount)
{
    MTLTextureDescriptor *textureDescriptor =
    [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatBGRA8Unorm
                                                       width:width
                                                      height:height
                                                   mipmapped:false];
    textureDescriptor.storageMode = MTLStorageModePrivate;
    textureDescriptor.sampleCount = sampleCount;
    textureDescriptor.textureType = MTLTextureType2DMultisample;
    textureDescriptor.usage = MTLTextureUsageRenderTarget;
    return [device newTextureWithDescriptor:textureDescriptor];
}

void mss_clear_texture(id<MTLDevice> device,
                       id<MTLCommandBuffer> commandBuffer,
                       id<MTLTexture> texture)
{
    uint64 width = texture.width;
    uint64 height = texture.height;
    
    // Clear texture by copy from zero value buffer.
    uint64 bufferLength = width * height * sizeof(float) * 4;
    id<MTLBuffer> buffer = [device newBufferWithLength:bufferLength
                                               options:MTLResourceStorageModePrivate];
    
    id<MTLBlitCommandEncoder> commandEncoder = [commandBuffer blitCommandEncoder];
    [commandEncoder fillBuffer:buffer range:NSMakeRange(0, bufferLength) value:0];
    [commandEncoder copyFromBuffer:buffer
                      sourceOffset:0
                 sourceBytesPerRow:width * 4
               sourceBytesPerImage:bufferLength
                        sourceSize:MTLSizeMake(width, height, 1)
                         toTexture:texture
                  destinationSlice:0
                  destinationLevel:0
                 destinationOrigin:MTLOriginMake(0, 0, 0)];
    [commandEncoder endEncoding];
    [commandBuffer commit];
}
