//
//  DavidView.m
//  David
//
//  Created by Felix Naredi on 2019-05-11.
//

#import "DavidView.h"
#import "MSSRenderer.h"

@implementation DavidView
{
    MSSRenderer *_renderer;
}

- (instancetype)initWithFrame:(NSRect)frame isPreview:(BOOL)isPreview
{
    self = [super initWithFrame:frame isPreview:isPreview];
    if (!self)
        return NULL;
    
    if(!(_renderer = [[MSSRenderer alloc] init]))
        return NULL;
    self.wantsLayer = true;
    self.animationTimeInterval = 1.0/60.0;
    return self;
}

- (CALayer *)makeBackingLayer
{
    CAMetalLayer *layer = [[CAMetalLayer alloc] init];
    layer.delegate = self;
    layer.device = _renderer.device;
    layer.pixelFormat = MTLPixelFormatBGRA8Unorm;
    [_renderer setLayerSize:layer toSize:self.frame.size];
    return layer;
}

- (void)animateOneFrame
{ [self.layer setNeedsDisplay]; }

- (void)displayLayer:(CALayer *)layer
{ [_renderer displayLayer:(CAMetalLayer *)layer]; }

- (BOOL)hasConfigureSheet
{ return NO; }

- (NSWindow*)configureSheet
{ return nil; }

@end
