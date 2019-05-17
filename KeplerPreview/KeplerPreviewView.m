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
    [NSTimer scheduledTimerWithTimeInterval:1.0/60.0 repeats:true block:^(NSTimer * _Nonnull timer) {
        [self.layer setNeedsDisplay];
    }];
    
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
    return layer;
}

- (void)setFrameSize:(NSSize)newSize
{
    [super setFrameSize:newSize];
    ((CAMetalLayer *)self.layer).drawableSize = self.frame.size;
    [self.layer setNeedsLayout];
    [self.layer setNeedsDisplay];
}

- (void)displayLayer:(CALayer *)layer
{ [_renderer displayMetalLayer:(CAMetalLayer *)layer]; }

@end
