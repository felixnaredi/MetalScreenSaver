//
//  AppDelegate.m
//  IntersectPreview
//
//  Created by Felix Naredi on 2019-05-05.
//

#import "AppDelegate.h"

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    CALayer *layer = _window.contentView.layer;
    NSLog(@"layer: %@, delegate: %@", layer, layer.delegate);
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}


@end
