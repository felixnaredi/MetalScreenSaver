//
//  math.h
//  MetalScreenSaver
//
//  Created by Felix Naredi on 2019-05-14.
//

#ifndef mss_math_h
#define mss_math_h

#include <simd/simd.h>

simd_float2 mss_rotate_float2(simd_float2 vector, float radian);
float mss_radian_float2(simd_float2 vector);

#endif /* MSSMath_h */
