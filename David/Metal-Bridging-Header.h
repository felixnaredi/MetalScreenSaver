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
    kMSSBufferIndexScaleMatrix,
    kMSSBufferIndexRotationMatrix,
    kMSSBufferIndexTriangleData,
    kMSSBufferIndexFrameCounter,
    kMSSBufferIndexStarDuration,
    kMSSBufferIndexTransformMatrix
} MSSBufferIndex;

#define kMSSTriangleCount 8


typedef struct __MSSTriangleDescriptor
{
    const matrix_float2x2 rotationMatrix;
    const vector_float3 color;
    float scale;
} MSSTriangleDescriptor;

#endif /* Metal_Bridging_Header_h */
