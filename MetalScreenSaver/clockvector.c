//
//  mss_clockvector
//  MetalScreenSaver
//
//  Created by Felix Naredi on 2019-05-14.
//

#include "clockvector.h"
#include "math.h"
#include <simd/simd.h>
#include <assert.h>
#include <math.h>
#include <time.h>

mss_clockvector mss_clockvector_init_now(void)
{
    return mss_rotate_float2(simd_make_float2(1, 0),
                            M_PI * 2 * (float)(time(NULL) % 3600) / 1024);
}

mss_clockvector mss_clockvector_next(mss_clockvector clock)
{ return mss_rotate_float2(clock, MSS_CLOCKVECTOR_RADIANS_PER_FRAME); }

float mss_clockvector_radian(mss_clockvector clock)
{ return mss_radian_float2(clock); }

float mss_clockvector_radian_with_period(mss_clockvector clock, float period)
{
    return fmodf(
        mss_clockvector_radian(clock) * (M_PI / MSS_CLOCKVECTOR_RADIANS_PER_SECOND / period),
        2 * M_PI);
}
