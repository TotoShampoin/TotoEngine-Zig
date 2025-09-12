const std = @import("std");
const sdl3 = @import("sdl3");

const _context = @import("_context.zig");
const shorthands = @import("shorthands.zig");
const types = @import("types.zig");
const RenderPass = @import("RenderPass.zig");

const Renderer = @This();

pipeline: sdl3.gpu.GraphicsPipeline,
swapchain_texture: ?sdl3.gpu.Texture = null,
depth_texture: ?sdl3.gpu.Texture = null,

pub fn init() !Renderer {
    return .{
        .pipeline = try createPipeline(),
    };
}

pub fn deinit(self: Renderer) void {
    const c = _context.ctx orelse return;
    const device = c.device;
    if (self.depth_texture) |d| device.releaseTexture(d);
    device.releaseGraphicsPipeline(self.pipeline);
}

pub const begin = RenderPass.begin;

fn createPipeline() !sdl3.gpu.GraphicsPipeline {
    const c = _context.ctx orelse return error.NoInit;
    const device = c.device;
    const window = c.window;

    const vertex = try device.createShader(.{
        .stage = .vertex,
        .entry_point = "main",
        .code = @embedFile("shader_vert"),
        .format = .{ .spirv = true },
        .props = .{ .name = "Vertex shader" },
        .num_uniform_buffers = 2,
    });
    defer device.releaseShader(vertex);
    const fragment = try device.createShader(.{
        .stage = .fragment,
        .entry_point = "main",
        .code = @embedFile("shader_frag"),
        .format = .{ .spirv = true },
        .props = .{ .name = "Fragment shader" },
        .num_uniform_buffers = 3,
        .num_samplers = 3,
    });
    defer device.releaseShader(fragment);

    const pipeline = try device.createGraphicsPipeline(.{
        .vertex_shader = vertex,
        .fragment_shader = fragment,
        .primitive_type = .triangle_list,
        .vertex_input_state = .{
            .vertex_attributes = &(shorthands.parseAttributes(types.Vertex, 0, 0)),
            .vertex_buffer_descriptions = &.{.{
                .slot = 0,
                .pitch = @sizeOf(types.Vertex),
                .input_rate = .vertex,
            }},
        },
        .depth_stencil_state = .{
            .enable_depth_test = true,
            .enable_depth_write = true,
            .compare = .less,
        },
        .target_info = .{
            .color_target_descriptions = &.{
                sdl3.gpu.ColorTargetDescription{
                    .format = try device.getSwapchainTextureFormat(window),
                    .blend_state = .{
                        .enable_blend = true,
                        .source_color = .src_alpha,
                        .destination_color = .one_minus_src_alpha,
                        .color_blend = .add,
                        .source_alpha = .one,
                        .destination_alpha = .one_minus_src_alpha,
                        .alpha_blend = .add,
                    },
                },
            },
            .depth_stencil_format = .depth24_unorm_s8_uint,
        },
        .rasterizer_state = .{
            .cull_mode = .back,
        },
        .props = .{ .name = "Pipeline" },
    });
    errdefer device.releaseGraphicsPipeline(pipeline);

    return pipeline;
}

pub fn createDepthTexture() !sdl3.gpu.Texture {
    const c = _context.ctx orelse return error.NoInit;
    const device = c.device;
    const window = c.window;
    const size = try window.getSize();

    return try device.createTexture(.{
        .format = .depth24_unorm_s8_uint,
        .width = @intCast(size.width),
        .height = @intCast(size.height),
        .layer_count_or_depth = 1,
        .num_levels = 1,
        .sample_count = .no_multisampling,
        .texture_type = .two_dimensional,
        .usage = .{ .depth_stencil_target = true },
    });
}
