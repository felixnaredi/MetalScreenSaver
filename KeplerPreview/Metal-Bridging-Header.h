//
//  Metal-Bridging-Header.h
//  MetalScreenSaver
//
//  Created by Felix Naredi on 2019-05-16.
//

#ifndef Metal_Bridging_Header_h
#define Metal_Bridging_Header_h

typedef enum {
    MSSBufferIndexModelMatrix,
    MSSBufferIndexViewMatrix,
    MSSBufferIndexVertexData,
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
} mss_orbit;

#define kMSSCircleTextureSideCount 128

#endif /* Metal_Bridging_Header_h */
