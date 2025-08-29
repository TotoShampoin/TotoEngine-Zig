const sdl3 = @import("sdl3");

const types = @import("types.zig");
const shorthands = @import("shorthands.zig");
const Mesh = @import("Mesh.zig");

const RenderPass = @This();

pass: sdl3.gpu.RenderPass,
swapchain: sdl3.gpu.Texture,
width: u32,
height: u32,

pub fn begin(command_buffer: sdl3.gpu.CommandBuffer, window: sdl3.video.Window) !?RenderPass {
    const swapchain = try command_buffer.acquireSwapchainTexture(window);
    if (swapchain.texture == null) return null;

    const pass = command_buffer.beginRenderPass(&.{
        sdl3.gpu.ColorTargetInfo{
            .clear_color = .{ .r = 0, .g = 0, .b = 0, .a = 1 },
            .load = .clear,
            .store = .store,
            .texture = swapchain.texture.?,
        },
    }, null);

    return .{
        .pass = pass,
        .swapchain = swapchain.texture.?,
        .width = swapchain.width,
        .height = swapchain.height,
    };
}

pub fn end(self: RenderPass) void {
    self.pass.end();
}

pub fn draw(
    self: RenderPass,
    pipeline: sdl3.gpu.GraphicsPipeline,
    mesh: Mesh,
) void {
    self.pass.bindGraphicsPipeline(pipeline);
    self.pass.bindVertexBuffers(0, &.{
        sdl3.gpu.BufferBinding{ .buffer = mesh.vertex_buffer, .offset = 0 },
    });
    self.pass.bindIndexBuffer(.{ .buffer = mesh.index_buffer, .offset = 0 }, .indices_32bit);
    self.pass.drawIndexedPrimitives(mesh.count, 1, 0, 0, 0);
}

pub fn createPipeline(device: sdl3.gpu.Device, window: sdl3.video.Window) !sdl3.gpu.GraphicsPipeline {
    const vertex = try device.createShader(.{
        .stage = .vertex,
        .entry_point = "main",
        .code = @embedFile("assets/shader.vert.spv"),
        .format = .{ .spirv = true },
        .props = .{ .name = "Vertex shader" },
    });
    defer device.releaseShader(vertex);
    const fragment = try device.createShader(.{
        .stage = .fragment,
        .entry_point = "main",
        .code = @embedFile("assets/shader.frag.spv"),
        .format = .{ .spirv = true },
        .props = .{ .name = "Fragment shader" },
    });
    defer device.releaseShader(fragment);

    const pipeline = try device.createGraphicsPipeline(.{
        .vertex_shader = vertex,
        .fragment_shader = fragment,
        .vertex_input_state = .{
            .vertex_attributes = &(shorthands.parseAttributes(types.Vertex, 0, 0)),
            .vertex_buffer_descriptions = &.{.{
                .slot = 0,
                .pitch = @sizeOf(types.Vertex),
                .input_rate = .vertex,
            }},
        },
        .target_info = .{
            .color_target_descriptions = &.{
                .{ .format = device.getSwapchainTextureFormat(window) },
            },
            .depth_stencil_format = null,
        },
        .props = .{ .name = "Pipeline" },
    });
    errdefer device.releaseGraphicsPipeline(pipeline);

    return pipeline;
}
