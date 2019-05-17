//
//  KeplerRenderer.m
//  KeplerPreview
//
//  Created by Felix Naredi on 2019-05-16.
//

@import Metal;
@import simd;

#import "KeplerRenderer.h"
#import "Metal-Bridging-Header.h"
#import "../MetalScreenSaver/metal.h"
#import <os/log.h>


/// Renders a circle (n-sided polygon) into a texture and returns it.
static _Nullable id<MTLTexture> __circle_texture(_Nonnull id<MTLDevice> device,
                                                 _Nonnull id<MTLLibrary> library,
                                                 _Nonnull id<MTLCommandBuffer> commandBuffer,
                                                 uint width,
                                                 uint height,
                                                 uint sides)
{
    MTLTextureDescriptor *textureDescriptor =
        [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatBGRA8Unorm
                                                           width:width
                                                          height:height
                                                       mipmapped:false];
    textureDescriptor.usage |= MTLTextureUsageRenderTarget | MTLTextureUsageShaderRead;
    id<MTLTexture> texture = [device newTextureWithDescriptor:textureDescriptor];
    
    MTLRenderPipelineDescriptor *pipelineDescriptor = [MTLRenderPipelineDescriptor new];
    pipelineDescriptor.label = @"MSSCircleTextureRenderPipeline";
    pipelineDescriptor.vertexFunction = [library newFunctionWithName:@"vertex_circle_texture"];
    pipelineDescriptor.fragmentFunction = [library newFunctionWithName:@"fragment_circle_texture"];
    pipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
    id<MTLRenderPipelineState> pipelineState;
    if (!(pipelineState = mss_make_render_pipeline_state(device, pipelineDescriptor)))
        return NULL;
    
    MTLRenderPassDescriptor *renderPassDescriptor = [MTLRenderPassDescriptor new];
    renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 0);
    renderPassDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;
    renderPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
    renderPassDescriptor.colorAttachments[0].texture = texture;
    
    id<MTLRenderCommandEncoder> commandEncoder =
        [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
    [commandEncoder setRenderPipelineState:pipelineState];
    [commandEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:sides * 3];
    [commandEncoder endEncoding];
    [commandBuffer commit];
    
    return texture;
}

@implementation KeplerRenderer
{
    id<MTLDevice> _device;
    id<MTLCommandQueue> _commandQueue;
    id<MTLTexture> _circleTexture;
    id<MTLRenderPipelineState> _quadTextureRenderPipeline;
    MTLRenderPassDescriptor *_renderPassDescriptor;
}

- (nullable id)init
{
    if (!(_device = MTLCreateSystemDefaultDevice())) {
        os_log_error(OS_LOG_DEFAULT, "Metal is not supported.");
        return NULL;
    }
    _commandQueue = [_device newCommandQueue];
    
    id<MTLLibrary> library = mss_bundle_default_metallib(_device, MSS_BUNDLE_IDENTIFIER);
    
    // Make a texture of a circle that will be used for rendering later.
    if (!(_circleTexture = __circle_texture(_device,
                                            library,
                                            [_commandQueue commandBuffer],
                                            512,
                                            512,
                                            kMSSCircleTextureSideCount))) {
        return NULL;
    }
    
    // Render pipeline state for rendering quads covered by a texture. In this case they will be
    // covered by the circle texture that was created above.
    MTLRenderPipelineDescriptor *pipelineDescriptor = [MTLRenderPipelineDescriptor new];
    pipelineDescriptor.label = @"MSSQuadTexturePipelineDescriptor";
    pipelineDescriptor.vertexFunction = [library newFunctionWithName:@"vertex_render_texture_quad"];
    pipelineDescriptor.fragmentFunction =
        [library newFunctionWithName:@"fragment_render_texture_quad"];
    pipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
    pipelineDescriptor.colorAttachments[0].blendingEnabled = true;
    pipelineDescriptor.colorAttachments[0].rgbBlendOperation = MTLBlendOperationAdd;
    pipelineDescriptor.colorAttachments[0].alphaBlendOperation = MTLBlendOperationAdd;
    pipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = MTLBlendFactorSourceAlpha;
    pipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = MTLBlendFactorSourceAlpha;
    pipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor =
        MTLBlendFactorOneMinusSourceAlpha;
    pipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor =
        MTLBlendFactorOneMinusSourceAlpha;
    if (!(_quadTextureRenderPipeline = mss_make_render_pipeline_state(_device, pipelineDescriptor)))
        return NULL;
    
    _renderPassDescriptor = [MTLRenderPassDescriptor new];
    MTLRenderPassColorAttachmentDescriptor *renderPassColorAttatchment =
        _renderPassDescriptor.colorAttachments[0];
    renderPassColorAttatchment.clearColor = MTLClearColorMake(0.1, 0.2, 0.3, 1.0);
    renderPassColorAttatchment.loadAction = MTLLoadActionClear;
    renderPassColorAttatchment.storeAction = MTLStoreActionStore;
    
    return self;
}

- (nonnull id<MTLDevice>)getDevice
{ return _device; }

- (void)displayMetalLayer:(CAMetalLayer *)layer
{
    static float r = 0;
    
    id<CAMetalDrawable> drawable = [layer nextDrawable];
    id<MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
    _renderPassDescriptor.colorAttachments[0].texture = drawable.texture;
    id<MTLRenderCommandEncoder> commandEncoder =
        [commandBuffer renderCommandEncoderWithDescriptor:_renderPassDescriptor];
    [commandEncoder setRenderPipelineState:_quadTextureRenderPipeline];
    
    float ar = layer.frame.size.height / layer.frame.size.width;
    simd_float4x4 modelMatrix = simd_matrix(
        simd_make_float4((1.0/5.0) * ar, 0,         0, cos(r) * (4.0/5.0) * ar),
        simd_make_float4(0,              (1.0/5.0), 0, sin(r) * (4.0/5.0)),
        simd_make_float4(0,              0,         1, 0),
        simd_make_float4(0,              0,         0, 1));
    [commandEncoder setVertexBytes:&modelMatrix
                            length:sizeof(modelMatrix)
                           atIndex:MSSBufferIndexModelMatrix];
    [commandEncoder setFragmentTexture:_circleTexture atIndex:0];
    [commandEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:6];
    
    [commandEncoder endEncoding];
    [commandBuffer presentDrawable:drawable];
    [commandBuffer commit];
    
    r += M_PI / 270;
}

@end
