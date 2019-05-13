//
//  Shaders.metal
//  MetalScreenSaver
//
//  Created by Felix Naredi on 2019-04-29.
//

#include <metal_stdlib>
using namespace metal;


struct RasterizerData {
    float4 position [[position]];
    float4 color;
    
    RasterizerData(float4 position, float4 color)
        : position(position)
        , color(color)
    {}
};

vertex RasterizerData
vertexShader(uint vertexID [[vertex_id]])
{
    switch (vertexID) {
    case 0: return RasterizerData(float4(-0.8, -0.8, 0.0, 1.0), float4(1, 0, 0, 1));
    case 1: return RasterizerData(float4( 0.8, -0.8, 0.0, 1.0), float4(0, 1, 0, 1));
    case 2: return RasterizerData(float4( 0.0,  0.8, 0.0, 1.0), float4(0, 0, 1, 1));
    default: return RasterizerData(float4(0), float4(0));
    }
}

fragment half4
fragmentShader(RasterizerData in [[stage_in]])
{ return half4(in.color); }
