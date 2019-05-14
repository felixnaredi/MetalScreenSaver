//
//  MSSRenderer.m
//  IntersectPreview
//
//  Created by Felix Naredi on 2019-05-05.
//

@import Foundation;
@import Metal;
@import QuartzCore;
@import simd;
#import "../MetalScreenSaver/MetalScreenSaver.h"
#import "../MetalScreenSaver/MSSMath.h"
#import "../MetalScreenSaver/MSSClockVector.h"

#import <os/log.h>
#import "Metal-Bridging-Header.h"
#import "MSSRenderer.h"

#define kMSSTextureSampleCount 4


static simd_float3 colorAtRadian(float radian)
{
    float d = M_PI * 2 / 3;
    return simd_make_float3(simd_max(0, cos(radian + d * 0) * (2.0/3.0) + (1.0/3.0)),
                            simd_max(0, cos(radian + d * 1) * (2.0/3.0) + (1.0/3.0)),
                            simd_max(0, cos(radian + d * 2) * (2.0/3.0) + (1.0/3.0)));
}

@implementation MSSRenderer
{
    id<MTLDevice> _device;
    id<MTLCommandQueue> _commandQueue;
    id<MTLRenderPipelineState> _renderPipelineState;
    id<MTLTexture> _msaaTexture;
    MTLRenderPassDescriptor *_renderPassDescriptor;
    simd_float2 _viewportSize;
    MSSClockVector _clockVector;
}

- (id<MTLDevice>)getDevice
{ return _device; }


- (id)init
{
    self = [super init];
    if (!self)
        return NULL;
    
    _device = MTLCreateSystemDefaultDevice();
    if (!_device) {
        os_log_error(OS_LOG_DEFAULT, "Metal not supported");
        return NULL;
    }
    
    MTLRenderPipelineDescriptor *pipelineDescriptor = [MTLRenderPipelineDescriptor new];
    id<MTLLibrary> library = MSSNewDefaultBundleLibrary(_device, kMSSBundleIdentifier);
    pipelineDescriptor.vertexFunction = [library newFunctionWithName:@"vertexShader"];
    pipelineDescriptor.fragmentFunction = [library newFunctionWithName:@"fragmentShader"];
    pipelineDescriptor.sampleCount = kMSSTextureSampleCount;
    MTLRenderPipelineColorAttachmentDescriptor *pipelineColorAttachment =
        pipelineDescriptor.colorAttachments[0];
    pipelineColorAttachment.pixelFormat = MTLPixelFormatBGRA8Unorm;
    pipelineColorAttachment.blendingEnabled = true;
    pipelineColorAttachment.rgbBlendOperation = MTLBlendOperationAdd;
    pipelineColorAttachment.alphaBlendOperation = MTLBlendOperationAdd;
    pipelineColorAttachment.sourceRGBBlendFactor = MTLBlendFactorSourceAlpha;
    pipelineColorAttachment.sourceAlphaBlendFactor = MTLBlendFactorSourceAlpha;
    pipelineColorAttachment.destinationRGBBlendFactor = MTLBlendFactorOneMinusSourceAlpha;
    pipelineColorAttachment.destinationAlphaBlendFactor = MTLBlendFactorOneMinusSourceAlpha;
    
    if (!(_renderPipelineState = MSSMakeRenderPipelineState(_device, pipelineDescriptor)))
        return NULL;

    _renderPassDescriptor = [MTLRenderPassDescriptor renderPassDescriptor];
    MTLRenderPassColorAttachmentDescriptor __weak *renderPassColorAttachment =
    _renderPassDescriptor.colorAttachments[0];
    renderPassColorAttachment.loadAction = MTLLoadActionClear;
    renderPassColorAttachment.clearColor = MTLClearColorMake(0, 0, 0, 1);
    renderPassColorAttachment.storeAction = MTLStoreActionMultisampleResolve;
    
    _commandQueue = [_device newCommandQueue];
    _clockVector = MSSClockVectorInitNow();
    return self;
}

- (void)setLayerSize:(CAMetalLayer *)layer toSize:(NSSize)size
{
    layer.drawableSize = size;
    [layer setNeedsDisplay];
    _viewportSize = simd_make_float2(size.width, size.height);
    _msaaTexture = MSSNewMSAATexture(_device, size.width, size.height, kMSSTextureSampleCount);
}

- (void)displayLayer:(CAMetalLayer *)layer
{
    id<MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
    id<CAMetalDrawable> drawable = [layer nextDrawable];
    _renderPassDescriptor.colorAttachments[0].texture = _msaaTexture;
    _renderPassDescriptor.colorAttachments[0].resolveTexture = drawable.texture;

    float tA = MSSClockVectorRadianWithPeriod(_clockVector, 11.269427669);
    float tB = MSSClockVectorRadianWithPeriod(_clockVector, 22.427661492);
    float tZR = MSSClockVectorRadianWithPeriod(_clockVector, 2);
    simd_float3 t = simd_make_float3(cos(sin(tA)) * sin(tB),
                                     cos(sin(tB)) * sin(tA),
                                     2 * cos(2.09 * (tZR / (M_PI * 4) + 0.5)) - 1);
    float r = MSSClockVectorRadianWithPeriod(_clockVector, 7);
    float zoom = 1 + sin(MSSClockVectorRadianWithPeriod(_clockVector, 17)) * 0.4;
    
    simd_float3 clearColor =
        colorAtRadian(MSSRadian_float2(MSSRotate_float2(simd_normalize(t.xy), r)));
    float luminosity = sqrt(t.x * t.x + t.y * t.y) * 0.1;
    _renderPassDescriptor.colorAttachments[0].clearColor =
        MTLClearColorMake(clearColor.r * luminosity,
                          clearColor.g * luminosity,
                          clearColor.b * luminosity,
                          1);
    
    simd_float4x4 transformMatrix =
        simd_mul(
            simd_mul(
                simd_matrix(simd_make_float4(1, 0, 0, 0),
                            simd_make_float4(0, 1, 0, 0),
                            simd_make_float4(0, 0, 1, t.z),
                            simd_make_float4(0, 0, 0, 1)),
                simd_matrix(simd_make_float4(cos(r), -sin(r), 0, 0),
                            simd_make_float4(sin(r), cos(r), 0, 0),
                            simd_make_float4(0, 0, 1, 0),
                            simd_make_float4(0, 0, 0, 1))),
            simd_matrix(simd_make_float4(zoom, 0, 0, t.x),
                        simd_make_float4(0, zoom, 0, t.y),
                        simd_make_float4(0, 0, 1, 0),
                        simd_make_float4(0, 0, 0, 1)));
    
    simd_float4x4 viewMatrix = simd_matrix(simd_make_float4(1, 0, 0, -t.x),
                                           simd_make_float4(0, 1, 0, -t.y),
                                           simd_make_float4(0, 0, 1, 0),
                                           simd_make_float4(0, 0, 0, 1));
    
    id<MTLRenderCommandEncoder> renderEncoder =
        [commandBuffer renderCommandEncoderWithDescriptor:_renderPassDescriptor];
    [renderEncoder setRenderPipelineState:_renderPipelineState];
    [renderEncoder setVertexBytes:&_viewportSize
                           length:sizeof(_viewportSize)
                          atIndex:kMSSBufferIndexViewport];
    [renderEncoder setVertexBytes:&transformMatrix
                           length:sizeof(transformMatrix)
                          atIndex:kMSSBufferIndexModelMatrix];
    [renderEncoder setVertexBytes:&viewMatrix
                           length:sizeof(viewMatrix)
                          atIndex:kMSSBufferIndexViewMatrix];
    
    [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle
                      vertexStart:0
                      vertexCount:kMSSTriangleCount * 3 + 12];
    [renderEncoder endEncoding];
    
    [commandBuffer presentDrawable:drawable];
    [commandBuffer commit];
    
    _clockVector = MSSClockVectorNext(_clockVector);
}

@end
