//
//  MSSView.m
//  IntersectPreview
//
//  Created by Felix Naredi on 2019-05-06.
//

@import Cocoa;

#import "MSSView.h"
#import "MSSRenderer.h"

@implementation MSSView
{
    MSSRenderer *_renderer;
    NSTimer *_timer;
}

- (instancetype)initWithCoder:(NSCoder *)decoder
{
    self = [super initWithCoder:decoder];
    if (!self)
        return NULL;
    if(!(_renderer = [[MSSRenderer alloc] init]))
        return NULL;
    self.wantsLayer = true;
    
    _timer = [NSTimer
              scheduledTimerWithTimeInterval:1.0/60.0
              repeats:true
              block:^(NSTimer * _Nonnull timer) { [self.layer setNeedsDisplay]; }];
    
    return self;
}

- (CALayer *)makeBackingLayer
{
    CAMetalLayer *layer = [[CAMetalLayer alloc] init];
    layer.delegate = self;
    layer.device = _renderer.device;
    layer.pixelFormat = MTLPixelFormatBGRA8Unorm;
    [layer setNeedsDisplay];
    return layer;
}

- (void)setFrameSize:(NSSize)newSize
{
    [super setFrameSize:newSize];
    [_renderer setLayerSize:(CAMetalLayer *)self.layer toSize:self.frame.size];
}

- (void)displayLayer:(CALayer *)layer
{ [_renderer displayLayer:(CAMetalLayer *)layer]; }

@end
