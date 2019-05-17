//
//  KeplerPreviewView.m
//  KeplerPreview
//
//  Created by Felix Naredi on 2019-05-16.
//

@import Foundation;
@import QuartzCore;

#import "KeplerPreviewView.h"
#import "KeplerRenderer.h"

@implementation KeplerPreviewView
{
    KeplerRenderer *_renderer;
}

- (instancetype)initWithCoder:(NSCoder *)decoder
{
    self = [super initWithCoder:decoder];
    
    _renderer = [KeplerRenderer new];
    
    self.wantsLayer = true;
    return self;
}

- (CALayer *)makeBackingLayer
{
    CAMetalLayer *layer = [CAMetalLayer new];
    layer.delegate = self;
    layer.device = _renderer.device;
    layer.pixelFormat = MTLPixelFormatBGRA8Unorm;
    [layer setNeedsDisplay];
    [NSTimer scheduledTimerWithTimeInterval:1.0/60.0 repeats:true block:^(NSTimer *timer) {
        [layer setNeedsDisplay];
    }];
    return layer;
}

- (void)setFrameSize:(NSSize)newSize
{
    [super setFrameSize:newSize];
    CAMetalLayer *layer = (CAMetalLayer *)self.layer;
    layer.drawableSize = self.frame.size;
    [_renderer metalLayerDidResize:layer];
    [self.layer setNeedsLayout];
    [self.layer setNeedsDisplay];
}

- (void)displayLayer:(CALayer *)layer
{ [_renderer displayMetalLayer:(CAMetalLayer *)layer]; }

@end
