//
//  MSSMath.c
//  MetalScreenSaver
//
//  Created by Felix Naredi on 2019-05-14.
//

#include <simd/simd.h>
#include "MSSMath.h"

#define __MSSRotate(m, r) \
    simd_mul(m, simd_matrix(simd_make_float2(cos(r), -sin(r)), \
    simd_make_float2(sin(r), cos(r))))

simd_float2  MSSRotate_float2(simd_float2 vector, float radian)
{ return __MSSRotate(vector, radian); }

float MSSRadian_float2(simd_float2 vector)
{
    if (vector.y < 0)
        return 2 * M_PI - acosf(vector.x);
    return acosf(vector.x);
}
