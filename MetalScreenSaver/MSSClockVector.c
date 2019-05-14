//
//  MSSClockVector.c
//  MetalScreenSaver
//
//  Created by Felix Naredi on 2019-05-14.
//

#include "MSSClockVector.h"
#include "MSSMath.h"
#include <assert.h>
#include <math.h>
#include <time.h>
#include <simd/simd.h>

MSSClockVector MSSClockVectorInitNow(void)
{
    return MSSRotate_float2(simd_make_float2(1, 0),
                            M_PI * 2 * (float)(time(NULL) % 3600) / 1024);
}

MSSClockVector MSSClockVectorNext(MSSClockVector clock)
{ return MSSRotate_float2(clock, kMSSClockVectorRadiansPerFrame); }

float MSSClockVectorRadian(MSSClockVector clock)
{ return MSSRadian_float2(clock); }

float MSSClockVectorRadianWithPeriod(MSSClockVector clock, float period)
{
    return fmodf(MSSClockVectorRadian(clock) * (M_PI / kMSSClockVectorRadiansPerSecond / period),
                 2 * M_PI);
}
