//
//  Metal-Bridging-Header.h
//  MetalScreenSaver
//
//  Created by Felix Naredi on 2019-05-11.
//

#ifndef Metal_Bridging_Header_h
#define Metal_Bridging_Header_h

#include <simd/simd.h>

typedef enum {
    kMSSBufferIndexViewport = 0,
    kMSSBufferIndexModelMatrix,
    kMSSBufferIndexViewMatrix,
} MSSBufferIndex;

#define kMSSTriangleCount 32

#endif /* Metal_Bridging_Header_h */
