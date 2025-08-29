const sdl3 = @import("sdl3");
const zm = @import("zm");

const types = @import("types.zig");
const shorthands = @import("shorthands.zig");
const Mesh = @import("Mesh.zig");
const Transform = @import("Transform.zig");
const Camera = @import("Camera.zig");

const RenderPass = @This();

command_buffer: sdl3.gpu.CommandBuffer,
pass: sdl3.gpu.RenderPass,
swapchain: sdl3.gpu.Texture,
width: u32,
height: u32,

pub fn begin(command_buffer: sdl3.gpu.CommandBuffer, window: sdl3.video.Window, depth_texture: sdl3.gpu.Texture) !?RenderPass {
    const swapchain = try command_buffer.waitAndAcquireSwapchainTexture(window);
    if (swapchain.texture == null) return null;

    const pass = command_buffer.beginRenderPass(&.{
        sdl3.gpu.ColorTargetInfo{
            .clear_color = .{ .r = 0, .g = 0, .b = 0, .a = 1 },
            .load = .clear,
            .store = .store,
            .texture = swapchain.texture.?,
        },
    }, sdl3.gpu.DepthStencilTargetInfo{
        .texture = depth_texture,
        .clear_depth = 1.0,
        .clear_stencil = 0.0,
        .load = .clear,
        .store = .store,
        .stencil_load = .do_not_care,
        .stencil_store = .do_not_care,
        .cycle = true,
    });

    return .{
        .command_buffer = command_buffer,
        .pass = pass,
        .swapchain = swapchain.texture.?,
        .width = swapchain.width,
        .height = swapchain.height,
    };
}

pub fn end(self: RenderPass) void {
    self.pass.end();
}

const TransformUniform = struct {
    model: zm.Mat4f,
    view: zm.Mat4f,
    projection: zm.Mat4f,
    mv: zm.Mat4f,
    mvp: zm.Mat4f,
    normal_matix: zm.Mat3f,
};

pub fn draw(
    self: RenderPass,
    pipeline: sdl3.gpu.GraphicsPipeline,
    mesh: Mesh,
    material: types.Material,
    transform: Transform,
    camera: Camera,
) void {
    const model = transform.matrix();
    const view = camera.transform.matrix().inverse();
    const projection = camera.projection;

    const tu = TransformUniform{
        .model = model,
        .view = view,
        .projection = projection,
        .mv = view.multiply(model),
        .mvp = projection.multiply(view).multiply(model),
        .normal_matix = shorthands.mat4toMat3(model.inverse().transpose()),
    };
    const transform_buffer, const transform_buffer_size = shorthands.prepareUniformsForGpu(TransformUniform, tu);
    self.command_buffer.pushVertexUniformData(0, transform_buffer[0..transform_buffer_size]);
    const material_buffer, const material_buffer_size = shorthands.prepareUniformsForGpu(types.Material, material);
    self.command_buffer.pushFragmentUniformData(0, material_buffer[0..material_buffer_size]);
    const texture_sampler_bindings, const count = shorthands.prepareSamplersForGpu(types.Material, material);
    self.pass.bindFragmentSamplers(0, texture_sampler_bindings[0..count]);

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
        .code = @embedFile("shader_vert"),
        .format = .{ .spirv = true },
        .props = .{ .name = "Vertex shader" },
        .num_uniform_buffers = 1,
    });
    defer device.releaseShader(vertex);
    const fragment = try device.createShader(.{
        .stage = .fragment,
        .entry_point = "main",
        .code = @embedFile("shader_frag"),
        .format = .{ .spirv = true },
        .props = .{ .name = "Fragment shader" },
        .num_uniform_buffers = 1,
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
                .{ .format = device.getSwapchainTextureFormat(window) },
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
