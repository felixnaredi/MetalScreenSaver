//
//  HelloScreenSaverView.m
//  HelloScreenSaver
//
//  Created by Felix Naredi on 2019-04-29.
//

@import Metal;
@import QuartzCore;

#import <os/log.h>
#import "HelloScreenSaverView.h"


_Nullable id<MTLLibrary> MSSNewDefaultBundleLibrary(const id<MTLDevice> device)
{
    NSBundle *bundle = [NSBundle bundleWithIdentifier:@"com.peppi.HelloScreenSaver"];
    NSError *error = NULL;
    id<MTLLibrary> library = [device newDefaultLibraryWithBundle:bundle error:&error];
    if (!library) {
        os_log_error(OS_LOG_DEFAULT, "Failed to create library %@", error);
        return NULL;
    }
    return library;
}

_Nullable id<MTLRenderPipelineState>
MSSMakeRenderPipelineState(_Nonnull id<MTLDevice> device,
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


@implementation HelloScreenSaverView
{
    id<MTLDevice> _device;
    id<MTLCommandQueue> _commandQueue;
    id<MTLRenderPipelineState> _renderPipelineState;
    MTLRenderPassDescriptor *_renderPassDescriptor;
    MTLRenderPassColorAttachmentDescriptor *_renderPassColorAttachmentDescriptor;
}

- (BOOL)setupMetal
{
    _device = MTLCreateSystemDefaultDevice();
    if (!_device) {
        os_log_error(OS_LOG_DEFAULT, "Metal is not supported.");
        return false;
    }
    
    MTLRenderPipelineDescriptor *pipelineDescriptor = [MTLRenderPipelineDescriptor new];
    id<MTLLibrary> library = MSSNewDefaultBundleLibrary(_device);
    pipelineDescriptor.vertexFunction = [library newFunctionWithName:@"vertexShader"];
    pipelineDescriptor.fragmentFunction = [library newFunctionWithName:@"fragmentShader"];
    pipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
    if (!(_renderPipelineState = MSSMakeRenderPipelineState(_device, pipelineDescriptor)))
        return false;
    
    _commandQueue = [_device newCommandQueue];
    
    _renderPassDescriptor = [MTLRenderPassDescriptor renderPassDescriptor];
    _renderPassColorAttachmentDescriptor = _renderPassDescriptor.colorAttachments[0];
    _renderPassColorAttachmentDescriptor.clearColor = MTLClearColorMake(0.1, 0.2, 0.3, 1.0);
    _renderPassColorAttachmentDescriptor.loadAction = MTLLoadActionClear;
    _renderPassColorAttachmentDescriptor.storeAction = MTLStoreActionStore;
    
    return true;
}

- (instancetype)initWithFrame:(NSRect)frame isPreview:(BOOL)isPreview
{
    self = [super initWithFrame:frame isPreview:isPreview];
    if (!self)
        return NULL;
    if (![self setupMetal])
        return NULL;
    self.animationTimeInterval = 1.0/30.0;
    self.wantsLayer = true;
    
    return self;
}

- (CALayer *)makeBackingLayer
{
    CAMetalLayer *layer = [[CAMetalLayer alloc] init];
    layer.delegate = self;
    layer.device = _device;
    layer.pixelFormat = MTLPixelFormatBGRA8Unorm;
    layer.needsDisplayOnBoundsChange = true;
    layer.drawableSize = self.frame.size;
    
    return layer;
}

- (void)displayLayer:(CALayer *)layer
{
    id<CAMetalDrawable> drawable = [(CAMetalLayer *)layer nextDrawable];
    _renderPassColorAttachmentDescriptor.texture = drawable.texture;
    
    id<MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
    id<MTLRenderCommandEncoder> commandEncoder =
        [commandBuffer renderCommandEncoderWithDescriptor:_renderPassDescriptor];
    
    [commandEncoder setRenderPipelineState:_renderPipelineState];
    [commandEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:3];
    [commandEncoder endEncoding];
    
    [commandBuffer presentDrawable:drawable];
    [commandBuffer commit];
}

- (BOOL)hasConfigureSheet
{ return NO; }

- (NSWindow*)configureSheet
{ return nil; }

@end
