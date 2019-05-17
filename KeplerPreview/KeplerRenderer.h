//
//  KeplerRenderer.h
//  KeplerPreview
//
//  Created by Felix Naredi on 2019-05-16.
//

@import Metal;
@import QuartzCore;

NS_ASSUME_NONNULL_BEGIN

@interface KeplerRenderer : NSObject

@property (readonly, getter=getDevice) id<MTLDevice> device;

- (void)displayMetalLayer:(CAMetalLayer *)layer;

@end

NS_ASSUME_NONNULL_END
