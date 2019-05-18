//
//  Metal-Bridging-Header.h
//  MetalScreenSaver
//
//  Created by Felix Naredi on 2019-05-16.
//

#ifndef Metal_Bridging_Header_h
#define Metal_Bridging_Header_h

#include <simd/simd.h>

typedef enum {
    MSSBufferIndexModelMatrix,
    MSSBufferIndexViewMatrix,
    MSSBufferIndexVertexData,
    MSSBufferIndexViewport,
} MSSBufferIndex;

typedef enum {
    MSSTextureIndexIn,
    MSSTextureIndexIn_0,
    MSSTextureIndexIn_1,
    MSSTextureIndexOut,
} MSSTextureIndex;

typedef struct {
    float h;
    float e;
    float rad;
    float t;
    vector_float3 color;
} mss_orbit_vertex;

#define kMSSCircleTextureSideCount 128
#define kMSSOrbitCount (1024 * 4)

#endif /* Metal_Bridging_Header_h */
