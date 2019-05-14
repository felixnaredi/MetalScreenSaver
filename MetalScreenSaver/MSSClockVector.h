//
//  MSSClockVector.h
//  MetalScreenSaver
//
//  Created by Felix Naredi on 2019-05-14.
//

#ifndef MSSClockVector_h
#define MSSClockVector_h

#include <simd/simd.h>

#define kMSSClockVectorRadiansPerSecond (1.0 / 1024.0)
#define kMSSClockVectorRadiansPerFrame (kMSSClockVectorRadiansPerSecond / 60.0)

typedef simd_float2 MSSClockVector;

MSSClockVector MSSClockVectorInitNow(void);
float MSSClockVectorRadian(MSSClockVector clock);
float MSSClockVectorRadianWithPeriod(MSSClockVector clock, float period);
MSSClockVector MSSClockVectorNext(MSSClockVector clock);

#endif /* MSSClockVector_h */
