//
//  clockvector.h
//  MetalScreenSaver
//
//  Created by Felix Naredi on 2019-05-14.
//

#ifndef mss_clockvector_h
#define mss_clockvector_h

#include <simd/simd.h>

#define MSS_CLOCKVECTOR_RADIANS_PER_SECOND (1.0 / 1024.0)
#define MSS_CLOCKVECTOR_RADIANS_PER_FRAME (MSS_CLOCKVECTOR_RADIANS_PER_SECOND / 60.0)

typedef simd_float2 mss_clockvector;

mss_clockvector mss_clockvector_init_now(void);
float mss_clockvector_radian(mss_clockvector clock);
float mss_clockvector_radian_with_period(mss_clockvector clock, float period);
mss_clockvector mss_clockvector_next(mss_clockvector clock);

#endif /* MSSClockVector_h */
