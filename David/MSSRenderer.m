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

#import <os/log.h>
#import "Metal-Bridging-Header.h"
#import "MSSRenderer.h"

#define kMSSTextureSampleCount 4

static id<MTLTexture> MSSNewMSAATexture(_Nonnull id<MTLDevice> device,
                                        NSUInteger width,
                                        NSUInteger height)
{
    MTLTextureDescriptor *textureDescriptor =
        [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatBGRA8Unorm
                                                           width:width
                                                          height:height
                                                       mipmapped:false];
    textureDescriptor.storageMode = MTLStorageModePrivate;
    textureDescriptor.sampleCount = kMSSTextureSampleCount;
    textureDescriptor.textureType = MTLTextureType2DMultisample;
    textureDescriptor.usage = MTLTextureUsageRenderTarget;
    return [device newTextureWithDescriptor:textureDescriptor];
}

static float matrixRadian2D(simd_float2x2 matrix)
{
    simd_float2 p = simd_max(simd_min(simd_mul(simd_make_float2(1, 0), matrix),
                                      simd_make_float2(1, 1)),
                             simd_make_float2(-1, -1));
    if (p.y < 0)
        return 2 * M_PI - acosf(p.x);
    return acosf(p.x);
}

#define rotate(m, r) \
    simd_mul(m, simd_matrix(simd_make_float2(cos(r), -sin(r)), \
                               simd_make_float2(sin(r), cos(r))))

static float float2_radian(simd_float2 vector)
{
    // vector = simd_normalize(vector);
    if (vector.y < 0)
        return 2 * M_PI - acosf(vector.x);
    return acosf(vector.x);
}

static simd_float3 colorAtRadian(float radian)
{
    float d = M_PI * 2 / 3;
    return simd_make_float3(simd_max(0, cos(radian + d * 0) * (2.0/3.0) + (1.0/3.0)),
                            simd_max(0, cos(radian + d * 1) * (2.0/3.0) + (1.0/3.0)),
                            simd_max(0, cos(radian + d * 2) * (2.0/3.0) + (1.0/3.0)));
}

static simd_float2x2 rotate2x2(const simd_float2x2 matrix, float radian)
{
    return simd_mul(matrix, simd_matrix(simd_make_float2(cos(radian), -sin(radian)),
                                        simd_make_float2(sin(radian), cos(radian))));
}

static simd_float2x2 float2x2_id()
{ return simd_diagonal_matrix(simd_make_float2(1, 1)); }

@implementation MSSRenderer
{
    id<MTLDevice> _device;
    id<MTLCommandQueue> _commandQueue;
    id<MTLRenderPipelineState> _renderPipelineState;
    id<MTLTexture> _msaaTexture;
    MTLRenderPassDescriptor *_renderPassDescriptor;
    simd_float2x2 _scaleMatrix;
    simd_float2x2 _rotationMatrix;
    simd_float2x2 _colorMatrix;
    simd_float2 _clockVector;
    simd_float2 _viewportSize;
    float _translationZ;
    float _r;
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
    
    _scaleMatrix = simd_diagonal_matrix(simd_make_float2(64, 64));
    _rotationMatrix = simd_diagonal_matrix(simd_make_float2(1, 1));
    _colorMatrix = simd_matrix(simd_make_float2(1, 0), simd_make_float2(0, 1));
    _clockVector = rotate(simd_make_float2(1, 0), 2 * M_PI * (float)(time(NULL) % 3600) / 3600.0);
    _translationZ = 0;
    return self;
}

- (void)setLayerSize:(CAMetalLayer *)layer toSize:(NSSize)size
{
    layer.drawableSize = size;
    [layer setNeedsDisplay];
    _viewportSize = simd_make_float2(size.width, size.height);
    _msaaTexture = MSSNewMSAATexture(_device, size.width, size.height);
}

- (void)displayLayer:(CAMetalLayer *)layer
{
    id<MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
    id<CAMetalDrawable> drawable = [layer nextDrawable];
    float r = float2_radian(_clockVector);
    _renderPassDescriptor.colorAttachments[0].texture = _msaaTexture;
    _renderPassDescriptor.colorAttachments[0].resolveTexture = drawable.texture;
    simd_float3 clearColor = colorAtRadian(r * 180);
    _renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(clearColor.r / 6.4,
                                                                             clearColor.g / 6.4,
                                                                             clearColor.b / 6.4,
                                                                             1);
    // NSLog(@"r: %f", r);
    simd_float4x4 transformMatrix =
        simd_mul(
            simd_mul(
                simd_matrix(
                    simd_make_float4(1, 0, 0, 0),
                    simd_make_float4(0, 1, 0, 0),
                    simd_make_float4(0, 0, 1, _translationZ),
                    simd_make_float4(0, 0, 0, 1)),
                simd_matrix(simd_make_float4(cos(r * 360), -sin(r * 360), 0, 0),
                            simd_make_float4(sin(r * 360), cos(r * 360), 0, 0),
                            simd_make_float4(0, 0, 1, 0),
                            simd_make_float4(0, 0, 0, 1))),
            simd_matrix(simd_make_float4(0.8 + sin(r * 240) / 5,
                                         0,
                                         0,
                                         sin(r * 787) * cos(r * 1021)),
                        simd_make_float4(0,
                                         0.8 + sin(r * 240) / 5,
                                         0,
                                         sin(r * 1021) * cos(r * 787)),
                        simd_make_float4(0, 0, 1, 0),
                        simd_make_float4(0, 0, 0, 1)));
    
    id<MTLRenderCommandEncoder> renderEncoder =
        [commandBuffer renderCommandEncoderWithDescriptor:_renderPassDescriptor];
    [renderEncoder setRenderPipelineState:_renderPipelineState];
    [renderEncoder setVertexBytes:&_viewportSize
                           length:sizeof(_viewportSize)
                          atIndex:kMSSBufferIndexViewport];
    [renderEncoder setVertexBytes:&transformMatrix
                           length:sizeof(transformMatrix)
                          atIndex:kMSSBufferIndexTransformMatrix];
    
    [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle
                      vertexStart:0
                      vertexCount:kMSSTriangleCount * 3 + 12];
    [renderEncoder endEncoding];
    
    [commandBuffer presentDrawable:drawable];
    [commandBuffer commit];
    
    if ((_translationZ -= 1.0 / 60.0) < -2)
        _translationZ += 2;
    _clockVector = simd_max(
        simd_min(rotate(_clockVector, M_PI / 3600.0 / 60.0),
                 simd_make_float2(1, 1)),
        simd_make_float2(-1, -1));
}

@end
