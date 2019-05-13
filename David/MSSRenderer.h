//
//  MSSRenderer.h
//  IntersectPreview
//
//  Created by Felix Naredi on 2019-05-05.
//

@import Foundation;
@import Metal;
@import QuartzCore;

NS_ASSUME_NONNULL_BEGIN

@interface MSSRenderer : NSObject

@property (readonly, getter=getDevice) id<MTLDevice> device;

- (void)displayLayer:(nonnull CAMetalLayer *)layer;
- (void)setLayerSize:(CAMetalLayer *)layer toSize:(NSSize)size;

@end

NS_ASSUME_NONNULL_END
