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
static _Nullable id<MTLTexture> __make_circle_texture(_Nonnull id<MTLDevice> device,
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
    id<MTLLibrary> _library;
    id<MTLCommandQueue> _commandQueue;
    id<MTLTexture> _circleTexture;
    id<MTLTexture> _renderDestinationTexture;
    id<MTLTexture> _displayTexture;
    id<MTLComputePipelineState> _fadeOutComputePipeline;
    id<MTLRenderPipelineState> _quadTextureRenderPipeline;
    id<MTLRenderPipelineState> _orbitRenderPipeline;
    MTLRenderPassDescriptor *_renderPassDescriptor;
    id<MTLBuffer> _orbitBuffer;
    uint _fadeTextureIndex;
    // uint _trackingOrbitIndex;
    mss_orbit_vertex _orbits[kMSSOrbitCount];
}

- (nonnull id<MTLDevice>)getDevice
{ return _device; }

- (nonnull mss_orbit_vertex*)getOrbitBufferContents
{ return [_orbitBuffer contents]; }

- (nullable id)init
{
    if (!(_device = MTLCreateSystemDefaultDevice())) {
        os_log_error(OS_LOG_DEFAULT, "Metal is not supported.");
        return NULL;
    }
    _commandQueue = [_device newCommandQueue];
    
    _library = mss_bundle_default_metallib(_device, MSS_BUNDLE_IDENTIFIER);
    id<MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
    
    // Create pipeline state that "fades a texture out".
    NSError *error;
    _fadeOutComputePipeline =
        [_device
         newComputePipelineStateWithFunction:[_library
                                              newFunctionWithName:@"kernel_fade_out_append_frame"]
                                       error:&error];
    if (!_fadeOutComputePipeline) {
        os_log_error(OS_LOG_DEFAULT, "Failed to create render pipeline state, %@", error);
        return NULL;
    }
    
    // Make a texture of a circle that will be used for rendering later.
    if (!(_circleTexture = __make_circle_texture(_device,
                                                 _library,
                                                 commandBuffer,
                                                 512,
                                                 512,
                                                 kMSSCircleTextureSideCount))) {
        return NULL;
    }
    
    // Render pipeline state for rendering quads covered by a texture. In this case they will be
    // covered by the circle texture that was created above.
    MTLRenderPipelineDescriptor *pipelineDescriptor = [MTLRenderPipelineDescriptor new];
    pipelineDescriptor.label = @"MSSQuadTexturePipelineDescriptor";
    pipelineDescriptor.vertexFunction =
        [_library newFunctionWithName:@"vertex_render_texture_quad"];
    pipelineDescriptor.fragmentFunction =
        [_library newFunctionWithName:@"fragment_render_texture_quad"];
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
    
    pipelineDescriptor.label = @"MSSVertexRenderOrbitPipelineDescriptor";
    pipelineDescriptor.vertexFunction =
        [_library newFunctionWithName:@"vertex_render_orbits"];
    pipelineDescriptor.fragmentFunction =
        [_library newFunctionWithName:@"fragment_render_orbits"];
    if (!(_orbitRenderPipeline = mss_make_render_pipeline_state(_device, pipelineDescriptor)))
        return NULL;
    
    _renderPassDescriptor = [MTLRenderPassDescriptor new];
    MTLRenderPassColorAttachmentDescriptor *renderPassColorAttatchment =
        _renderPassDescriptor.colorAttachments[0];
    renderPassColorAttatchment.clearColor = MTLClearColorMake(0.1, 0.2, 0.3, 1.0);
    renderPassColorAttatchment.loadAction = MTLLoadActionClear;
    renderPassColorAttatchment.storeAction = MTLStoreActionStore;
    
    _fadeTextureIndex = 0;
    
    _orbitBuffer = [_device newBufferWithLength:kMSSOrbitCount * sizeof(mss_orbit_vertex)
                                        options:MTLResourceStorageModeShared];
    mss_orbit_vertex *orbits = [self getOrbitBufferContents];
    for (int i = 0; i < kMSSOrbitCount; ++i) {
        orbits[i] = (mss_orbit_vertex) {
            .h     = 0.0625 * (float)(arc4random() % 15) + 0.5,
            .e     = 0.0625 * (float)(arc4random() % 8) + (7.0 / 16.0),
            .rad   = (2.0 * M_PI / 16.0) * (float)(arc4random() % 16),
            .t     = (2.0 * M_PI / 360.0) * ((float)(arc4random() % 60) + 60.0) * (1.0 / 512.0),
            .color = simd_make_float3((float)arc4random() / (float)UINT_MAX,
                                      (float)arc4random() / (float)UINT_MAX,
                                      (float)arc4random() / (float)UINT_MAX),
        };
    }
    
    return self;
}

- (void)metalLayerDidResize:(CAMetalLayer *)layer
{
    MTLTextureDescriptor *descriptor =
        [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatBGRA8Unorm
                                                           width:layer.frame.size.width
                                                          height:layer.frame.size.height
                                                       mipmapped:false];
    descriptor.usage |= MTLTextureUsageRenderTarget | MTLTextureUsageShaderRead;
    _renderDestinationTexture = [_device newTextureWithDescriptor:descriptor];
    
    descriptor.usage |= MTLTextureUsageShaderRead | MTLTextureUsageShaderWrite;
    _displayTexture = [_device newTextureWithDescriptor:descriptor];
    mss_clear_texture(_device, [_commandQueue commandBuffer], _displayTexture);
}

- (void)displayMetalLayer:(CAMetalLayer *)layer
{
    id<MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
    
    _renderPassDescriptor.colorAttachments[0].texture = _renderDestinationTexture;
    _renderPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
    _renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.1, 0.2, 0.3, 0);
    id<MTLRenderCommandEncoder> commandEncoder =
        [commandBuffer renderCommandEncoderWithDescriptor:_renderPassDescriptor];
    [commandEncoder setRenderPipelineState:_orbitRenderPipeline];
    
    // float ar = layer.frame.size.height / layer.frame.size.width;
    mss_orbit_vertex *orbits = [self getOrbitBufferContents];
    simd_float2 viewport = simd_make_float2(layer.frame.size.width, layer.frame.size.height);
    [commandEncoder setVertexBytes:&viewport length:sizeof(viewport) atIndex:MSSBufferIndexViewport];
    mss_orbit_vertex o = orbits[0];
    float r = ((o.h * o.h) / 0.01) / (1 + o.e * cos(o.rad));
    simd_float2 p = simd_make_float2(r * cos(o.rad), r * sin(o.rad));
    simd_float4x4 viewMatrix =
    /*
    simd_matrix(simd_make_float4(1, 0, 0, -p.x),
                                           simd_make_float4(0, 1, 0, -p.y),
                                           simd_make_float4(0, 0, 1, 0),
                                           simd_make_float4(0, 0, 0, 1)); */
        simd_mul(simd_matrix(simd_make_float4(1, 0, 0, -p.x),
                             simd_make_float4(0, 1, 0, -p.y),
                             simd_make_float4(0, 0, 1, 0),
                             simd_make_float4(0, 0, 0, 1)),
                 simd_matrix(simd_make_float4(cos(o.rad), -sin(o.rad), 0, 0),
                             simd_make_float4(sin(o.rad), cos(o.rad), 0, 0),
                             simd_make_float4(0, 0, 1, 0),
                             simd_make_float4(0, 0, 0, 1)));
    [commandEncoder setVertexBytes:&viewMatrix
                            length:sizeof(viewMatrix)
                           atIndex:MSSBufferIndexViewMatrix];
    [commandEncoder setVertexBuffer:_orbitBuffer offset:0 atIndex:MSSBufferIndexVertexData];
    [commandEncoder setFragmentTexture:_circleTexture atIndex:MSSTextureIndexIn];
    [commandEncoder drawPrimitives:MTLPrimitiveTypeTriangle
                       vertexStart:6
                       vertexCount:(kMSSOrbitCount - 1) * 6];
    [commandEncoder endEncoding];
    
    id<MTLComputeCommandEncoder> computeCommandEncoder = [commandBuffer computeCommandEncoder];
    [computeCommandEncoder setComputePipelineState:_fadeOutComputePipeline];
    [computeCommandEncoder setTexture:_renderDestinationTexture atIndex:MSSTextureIndexIn_0];
    [computeCommandEncoder setTexture:_displayTexture atIndex:MSSTextureIndexIn_1];
    [computeCommandEncoder setTexture:_displayTexture atIndex:MSSTextureIndexOut];
    [computeCommandEncoder
     dispatchThreadgroups:MTLSizeMake(64, 64, 1)
     threadsPerThreadgroup:MTLSizeMake((_displayTexture.width + 64 - 1) / 64,
                                       (_displayTexture.height + 64 - 1) / 64,
                                       1)];
    [computeCommandEncoder endEncoding];
    
    id<CAMetalDrawable> drawable = [layer nextDrawable];
    _renderPassDescriptor.colorAttachments[0].texture = drawable.texture;
    _renderPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
    /*
    _renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.1,
                                                                             0.2,
                                                                             0.1,
                                                                             1.00); */
    _renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(fabs(sin(o.rad)) * 0.1,
                                                                             fabs(cos(o.rad)) * 0.1,
                                                                             fabs(sin(o.rad)) * 0.1,
                                                                             1.00);
    commandEncoder = [commandBuffer renderCommandEncoderWithDescriptor:_renderPassDescriptor];
    [commandEncoder setRenderPipelineState:_quadTextureRenderPipeline];
    [commandEncoder setFragmentTexture:_displayTexture atIndex:MSSTextureIndexIn];
    [commandEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:6];
    [commandEncoder endEncoding];
    [commandBuffer presentDrawable:drawable];
    [commandBuffer commit];
    
    for (int i = 0; i < kMSSOrbitCount; ++i)
        orbits[i].rad += orbits[i].t;
}

@end
