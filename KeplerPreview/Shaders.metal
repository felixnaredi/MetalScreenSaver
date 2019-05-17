//
//  Shaders.metal
//  KeplerPreview
//
//  Created by Felix Naredi on 2019-05-17.
//

#include "Metal-Bridging-Header.h"
#include <metal_stdlib>

using namespace metal;

namespace mss {
    
    /// circle_texture
    ///
    /// Pipeline that renders a solid circle.
    namespace circle_texture {
        
        struct rasterizer_data_t {
            float4 position [[position]];
        };
        
        vertex rasterizer_data_t
        vertex_circle_texture(uint vid [[vertex_id]])
        {
            if (vid % 3 == 0)
                return rasterizer_data_t { .position = float4(0, 0, 0, 1) };
            float r = M_PI_F * 2.0 * (vid / 3 + vid % 3 - 1) / kMSSCircleTextureSideCount;
            return rasterizer_data_t { .position = float4(cos(r), sin(r), 0, 1) };
        }
        
        fragment half4
        fragment_circle_texture(rasterizer_data_t in [[stage_in]])
        { return half4(1, 1, 1, 1); }
        
    } // namespace circle_texture
    
    
    /// render_texture_quad
    ///
    /// Renders a texture onto a quad.
    namespace render_texture_quad {
        
        struct rasterizer_data_t {
            float4 position [[position]];
            float2 texcoord;
        };
        
        constant rasterizer_data_t quad_texture_vertices[] = {
            { .position = float4(1, -1, 0, 1), .texcoord = float2(1, 1) },
            { .position = float4(-1, -1, 0, 1), .texcoord = float2(0, 1) },
            { .position = float4(-1, 1, 0, 1), .texcoord = float2(0, 0) },
            { .position = float4(1, -1, 0, 1), .texcoord = float2(1, 1) },
            { .position = float4(-1, 1, 0, 1), .texcoord = float2(0, 0) },
            { .position = float4(1, 1, 0, 1), .texcoord = float2(1, 0) },
        };
        
        vertex rasterizer_data_t
        vertex_render_texture_quad(
            uint vid [[vertex_id]],
            constant float4x4& model_matrix [[buffer(MSSBufferIndexModelMatrix)]])
        {
            const auto v = quad_texture_vertices[vid];
            return rasterizer_data_t {
                .position = v.position * model_matrix,
                .texcoord = v.texcoord
            };
        }
        
        fragment half4
        fragment_render_texture_quad(rasterizer_data_t in [[stage_in]],
                                     texture2d<half> texture [[texture(0)]])
        {
            return half4(
                texture.sample(sampler(mag_filter::linear, min_filter::linear), in.texcoord));
        }
        
    } // namespace render_textured_quad
    
}
