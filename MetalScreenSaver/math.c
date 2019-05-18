//
//  math.c
//  MetalScreenSaver
//
//  Created by Felix Naredi on 2019-05-14.
//

#include <simd/simd.h>
#include "math.h"

#define __mss_rotate(m, r) \
    simd_mul(m, simd_matrix(simd_make_float2(cos(r), -sin(r)), \
                            simd_make_float2(sin(r), cos(r))))

simd_float2  mss_rotate_float2(simd_float2 vector, float radian)
{ return __mss_rotate(vector, radian); }

float mss_radian_float2(simd_float2 vector)
{
    if (vector.y < 0)
        return 2 * M_PI - acosf(vector.x);
    return acosf(vector.x);
}
