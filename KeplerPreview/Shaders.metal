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
            float distance_center;
        };
        
        vertex rasterizer_data_t
        vertex_circle_texture(uint vid [[vertex_id]])
        {
            if (vid % 3 == 0)
                return rasterizer_data_t { .position = float4(0, 0, 0, 1) };
            float r = M_PI_F * 2.0 * (vid / 3 + vid % 3 - 1) / kMSSCircleTextureSideCount;
            return rasterizer_data_t {
                .position = float4(cos(r), sin(r), 0, 1),
                .distance_center = length(float2(cos(r), sin(r)))
            };
        }
        
        fragment half4
        fragment_circle_texture(rasterizer_data_t in [[stage_in]])
        { return half4(0.8 - in.distance_center, 0.8, 1, 1.0 - pow(in.distance_center, 16)); }
        
    } // namespace circle_texture
    
    struct texture_vertex_t {
        float4 position [[position]];
        float2 texcoord;
    };
    
    constant texture_vertex_t quad_texture_vertices[] = {
        { .position = float4(1, -1, 0, 1), .texcoord = float2(1, 1) },
        { .position = float4(-1, -1, 0, 1), .texcoord = float2(0, 1) },
        { .position = float4(-1, 1, 0, 1), .texcoord = float2(0, 0) },
        { .position = float4(1, -1, 0, 1), .texcoord = float2(1, 1) },
        { .position = float4(-1, 1, 0, 1), .texcoord = float2(0, 0) },
        { .position = float4(1, 1, 0, 1), .texcoord = float2(1, 0) },
    };
    
    /// render_texture_quad
    ///
    /// Renders a texture onto a quad.
    namespace render_texture_quad {
        
        vertex texture_vertex_t
        vertex_render_texture_quad(uint vid [[vertex_id]])
        {
            const auto v = quad_texture_vertices[vid];
            return texture_vertex_t {
                .position = v.position,
                .texcoord = v.texcoord
            };
        }
        
        fragment half4
        fragment_render_texture_quad(texture_vertex_t in [[stage_in]],
                                     texture2d<half> texture [[texture(MSSTextureIndexIn)]])
        { return texture.sample(sampler(mag_filter::linear, min_filter::linear), in.texcoord); }
        
    } // namespace render_textured_quad
    
    namespace render_orbit_vertices {
        
        struct rasterizer_data_t {
            float4 attr_position [[position]];
            float2 texcoord;
            float4 color;
        };
        
        static float4x4 perspectiveMatrix(float aspectRatio = 1)
        {
            constexpr float s = 1.0 / 256.0;
            constexpr float n = 0.5;
            constexpr float f = 2.0;
            return float4x4(float4 {aspectRatio * s, 0, 0, 0},
                            float4 {0, s, 0, 0},
                            float4 {0, 0, -(n + f) / (n - f), f * n / (n - f)},
                            float4 {0, 0, 1, 0});
        }
        
        
        vertex rasterizer_data_t
        vertex_render_orbits(uint vid [[vertex_id]],
                             constant float2& viewport [[buffer(MSSBufferIndexViewport)]],
                             constant mss_orbit_vertex* orbits [[buffer(MSSBufferIndexVertexData)]],
                             constant float4x4& view_matrix [[buffer(MSSBufferIndexViewMatrix)]])
        {
            const auto v = quad_texture_vertices[vid % 6];
            const auto o = orbits[vid / 6];
            const auto r = ((o.h * o.h) / 0.01) / (1 + o.e * cos(o.rad));
            const float2 p(cos(o.rad) * r, sin(o.rad) * r);
            return rasterizer_data_t {
                .attr_position =
                v.position *
                float4x4(float4(1, 0, 0, p.x),
                         float4(0, 1, 0, p.y),
                         float4(0, 0, 1, 1),
                         float4(0, 0, 0, 1)) *
                view_matrix *
                perspectiveMatrix(viewport.y / viewport.x),
                .texcoord = v.texcoord,
                .color = float4(o.color, 1),
            };
        }
        
        fragment half4
        fragment_render_orbits(rasterizer_data_t in [[stage_in]],
                               texture2d<half> texture [[texture(MSSTextureIndexIn)]])
        {
            return half4(in.color) * texture.sample(
                sampler(mag_filter::linear, min_filter::linear), in.texcoord);
        }
    } // namespace render_orbit_vertices
    
    namespace fade_out {
        
        kernel void
        kernel_fade_out_append_frame(
            uint2 gid [[thread_position_in_grid]],
            texture2d<half, access::read> texin0 [[texture(MSSTextureIndexIn_0)]],
            texture2d<half, access::read> texin1 [[texture(MSSTextureIndexIn_1)]],
            texture2d<half, access::write> texout [[texture(MSSTextureIndexOut)]])
        {
            auto c0 = texin0.read(gid);
            auto c1 = texin1.read(gid);
            texout.write(half4(fmax(c1.rgb, c0.rgb), c0.a + fmax(0, c1.a - 0.128)), gid);
        }
        
    } // namespace fade_out
    
}
