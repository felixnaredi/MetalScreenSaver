//
//  MetalScreenSaver.m
//  MetalScreenSaver
//
//  Created by Felix Naredi on 2019-05-05.
//


@import Foundation;
@import Metal;

#import <os/log.h>
#import "MetalScreenSaver.h"

/// Creates a new default library for the device. Also works for bundles that are loaded from
/// Preferences.
///
/// @param device Device used to create the library.
_Nullable id<MTLLibrary> MSSNewDefaultBundleLibrary(const id<MTLDevice> device,
                                                    char * _Nonnull bundleIdentifier)
{
    NSBundle *bundle =
        [NSBundle bundleWithIdentifier:[NSString stringWithCString:bundleIdentifier
                                                          encoding:NSUTF8StringEncoding]];
    NSError *error = NULL;
    id<MTLLibrary> library = [device newDefaultLibraryWithBundle:bundle error:&error];
    if (!library) {
        os_log_error(OS_LOG_DEFAULT, "Failed to create library %@", error);
        return NULL;
    }
    return library;
}

/// Creates a `MTLRenderPipelineState` object. On failure NULL is returned and proper logs are made.
///
/// @param device Device used to create pipeline state.
/// @param descriptor Descriptor used to create pipeline state.
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
