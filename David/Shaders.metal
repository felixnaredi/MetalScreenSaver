//
//  Shaders.metal
//  IntersectPreview
//
//  Created by Felix Naredi on 2019-05-06.
//

#include <metal_stdlib>
#include "Metal-Bridging-Header.h"

#define kMSSPi 3.14159
#define MSSMax(a, b) ((a) > (b) ? a : b)

using namespace metal;

namespace mss {
    
    template <class T>
    T balancedAspectRatioMatrix(float2 size);
    
    
    template<>
    float2x2 balancedAspectRatioMatrix(float2 size)
    {
        float total = size.x + size.y;
        return float2x2(1 / (size.x / total), 0, 0, 1 / (size.y / total));
    }
    
    template<>
    float4x4 balancedAspectRatioMatrix(float2 size)
    {
        float total = size.x + size.y;
        return float4x4(1 / (size.x / total), 0, 0, 0,
                        0, 1 / (size.x / total), 0, 0,
                        0, 0, 1, 0,
                        0, 0, 0, 1);
    }
    
    float3 colorAtRadian(float radian)
    {
        float d = 2 * kMSSPi / 3;
        return float3(cos(radian + d * 0) * (1 - (1.0/3.0)) + (1.0/3.0),
                      cos(radian + d * 1) * (1 - (1.0/3.0)) + (1.0/3.0),
                      cos(radian + d * 2) * (1 - (1.0/3.0)) + (1.0/3.0));
    }
    
    float aspectRatio(float2 size)
    { return size.y / size.x; }

    struct RasterizerData {
        float4 position [[position]];
        float4 color;
    };
    
    /// \class TriangleVertex
    ///
    /// Gets properties for a single TriangleVertex given a certain index.
    struct TriangleVertex {
        
        struct RasterizerData {
            float4 position [[position]];
            float4 color;
            float4 p;
        };
        
        const uint index;
        
        float radian() const
        {
            if (normalizedPosition().y < 0)
                return kMSSPi * 2 - acos(normalizedPosition().x);
            return acos(normalizedPosition().x);
        }
        
        float4 color() const
        { return float4(colorAtRadian(radian()), 1); }
        
        float4 position() const
        { return normalizedPosition(); }
        
        RasterizerData rasterizerData(float4x4 transform, float aspectRatio = 1) const {
            return (RasterizerData) {
                .position = position() * transform * perspectiveMatrix(aspectRatio),
                .color = color(),
                .p = position() * transform * perspectiveMatrix(aspectRatio),
            };
        }
        
    private:
        constexpr float z() const
        { return (index / 6) + float((index / 3) % 4) * (1.0 / 16); }
        
        constexpr float4 normalizedPosition() const
        {
            float d = 2 * kMSSPi / 4;
            float offs = 2 * kMSSPi / 3.0 * float(index % 3);
            switch ((index / 3) % 4) {
                case 0: return float4(cos(offs + d * 0), sin(offs + d * 0), z(), 1);
                case 1: return float4(cos(offs + d * 2), sin(offs + d * 2), z(), 1);
                case 2: return float4(cos(offs + d * 1), sin(offs + d * 1), z(), 1);
                case 3: return float4(cos(offs + d * 3), sin(offs + d * 3), z(), 1);
                default: return float4(0);
            }
        }
        
        static float4x4 perspectiveMatrix(float aspectRatio = 1)
        {
            float s = 1.0 / tan(kMSSPi / 6.0);
            float n = 1.0 / kMSSTriangleCount;
            float f = n + kMSSTriangleCount;
            return float4x4(float4 {aspectRatio * s, 0, 0, 0},
                            float4 {0, s, 0, 0},
                            float4 {0, 0, -(n + f) / (n - f), f * n / (n - f)},
                            float4 {0, 0, 1, 0});
        }
    };
}

using namespace mss;


vertex TriangleVertex::RasterizerData
vertexShader(uint vertexID [[vertex_id]],
             constant float2& viewportSize [[buffer(kMSSBufferIndexViewport)]],
             constant float4x4& transformMatrix [[buffer(kMSSBufferIndexTransformMatrix)]])
{
    return (TriangleVertex { .index = vertexID }).rasterizerData(transformMatrix,
                                                                 aspectRatio(viewportSize));
}

fragment float4
fragmentShader(TriangleVertex::RasterizerData in [[stage_in]])
{ return float4(in.color.rgb, sin(in.p.z / kMSSTriangleCount * 2 * kMSSPi)); }
