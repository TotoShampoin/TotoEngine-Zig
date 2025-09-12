const std = @import("std");
const sdl3 = @import("sdl3");
const zm = @import("zm");

const _context = @import("_context.zig");
const defaults = @import("defaults.zig");
const types = @import("types.zig");
const math_utils = @import("math_utils.zig");
const shorthands = @import("shorthands.zig");
const Geometry = @import("Geometry.zig");
const Transform = @import("Transform.zig");

const RenderPass = @This();

var swapchain_texture: ?sdl3.gpu.Texture = null;
var depth_texture: ?sdl3.gpu.Texture = null;
var pipeline: ?sdl3.gpu.GraphicsPipeline = null;

command_buffer: sdl3.gpu.CommandBuffer,
pass: sdl3.gpu.RenderPass,
width: u32,
height: u32,

pub fn init() !void {
    pipeline = try createPipeline();
    try defaults.init();
}
pub fn deinit() void {
    const c = _context.ctx orelse return;
    const device = c.device;
    defaults.deinit();
    if (depth_texture) |t| device.releaseTexture(t);
    if (pipeline) |p| device.releaseGraphicsPipeline(p);
}

pub fn begin() !?RenderPass {
    const c = _context.ctx orelse return error.NoInit;
    const device = c.device;
    const window = c.window;

    const command_buffer = try device.acquireCommandBuffer();
    const swapchain = try command_buffer.waitAndAcquireSwapchainTexture(window);
    if (swapchain.texture == null) {
        try command_buffer.cancel();
        return null;
    }
    if (swapchain_texture == null or swapchain.texture.?.value != swapchain_texture.?.value) {
        if (depth_texture) |dt| {
            device.releaseTexture(dt);
            depth_texture = null;
        }
        swapchain_texture = swapchain.texture;
        depth_texture = try createDepthTexture();
    }

    const pass = command_buffer.beginRenderPass(&.{
        sdl3.gpu.ColorTargetInfo{
            .clear_color = .{ .r = 0, .g = 0, .b = 0, .a = 1 },
            .load = .clear,
            .store = .store,
            .texture = swapchain.texture.?,
        },
    }, sdl3.gpu.DepthStencilTargetInfo{
        .texture = depth_texture.?,
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
        .width = swapchain.width,
        .height = swapchain.height,
    };
}

pub fn end(self: RenderPass) !void {
    self.pass.end();
    try self.command_buffer.submit();
}

fn pushVertexUniform(self: RenderPass, T: type, data: T, slot: u32) void {
    const buffer, const size = shorthands.prepareUniformsForGpu(T, data);
    self.command_buffer.pushVertexUniformData(slot, buffer[0..size]);
}
fn pushFragmentUniform(self: RenderPass, T: type, data: T, slot: u32) void {
    const buffer, const size = shorthands.prepareUniformsForGpu(T, data);
    self.command_buffer.pushFragmentUniformData(slot, buffer[0..size]);
}
fn pushFragmentSamplers(self: RenderPass, T: type, data: T, slot: u32) void {
    const bindings, const count = shorthands.prepareSamplersForGpu(T, data);
    self.pass.bindFragmentSamplers(slot, bindings[0..count]);
}

const CameraUniform = struct {
    view: zm.Mat4f,
    projection: zm.Mat4f,
    vp: zm.Mat4f,
};
pub fn setCamera(self: RenderPass, camera: types.Camera, world_matrix: zm.Mat4f) void {
    const view = world_matrix.inverse();
    const projection = camera.projection;
    const position = zm.Vec3f{ world_matrix.data[3], world_matrix.data[7], world_matrix.data[11] };

    const cu = CameraUniform{
        .view = view,
        .projection = projection,
        .vp = projection.multiply(view),
    };

    self.pushVertexUniform(CameraUniform, cu, 0);
    self.pushFragmentUniform(zm.Vec3f, position, 0);
}

const LightUniform = struct {
    lights: [8]types.Light,
    matrices: [8]zm.Mat4f,
    light_count: i32,
};
pub fn setLights(self: RenderPass, lights: []const types.Light, world_matrices: []const zm.Mat4f) void {
    std.debug.assert(lights.len == world_matrices.len);

    var lu = LightUniform{
        .lights = undefined,
        .matrices = undefined,
        .light_count = @intCast(lights.len),
    };
    for (lights, world_matrices, 0..) |l, m, i| {
        const sx = zm.vec.len(zm.vec.xyz(m.multiplyVec4(.{ 1, 0, 0, 0 })));
        const sy = zm.vec.len(zm.vec.xyz(m.multiplyVec4(.{ 0, 1, 0, 0 })));
        const sz = zm.vec.len(zm.vec.xyz(m.multiplyVec4(.{ 0, 0, 1, 0 })));
        const max_scale = @max(sx, @max(sy, sz));

        lu.lights[i] = l;
        lu.lights[i].range = l.range * max_scale;
        lu.matrices[i] = m;
    }

    self.pushFragmentUniform(LightUniform, lu, 1);
}

const TransformUniform = struct {
    model: zm.Mat4f,
    normal_matix: zm.Mat3f,
};
pub fn setTransform(self: RenderPass, model: zm.Mat4f) void {
    const tu = TransformUniform{
        .model = model,
        .normal_matix = math_utils.mat4toMat3(model.inverse().transpose()),
    };

    self.pushVertexUniform(TransformUniform, tu, 1);
}
pub fn setMaterial(self: RenderPass, material: types.Material) void {
    self.pushFragmentUniform(types.Material, material, 2);
    self.pushFragmentSamplers(types.Material, material, 0);
}

pub fn draw(self: RenderPass, primitive: Geometry) void {
    self.pass.bindGraphicsPipeline(pipeline.?);
    self.pass.bindVertexBuffers(0, &.{sdl3.gpu.BufferBinding{ .buffer = primitive.vertex_buffer, .offset = 0 }});
    self.pass.bindIndexBuffer(.{ .buffer = primitive.index_buffer, .offset = 0 }, .indices_32bit);
    self.pass.drawIndexedPrimitives(primitive.count, 1, 0, 0, 0);
}

pub fn createPipeline() !sdl3.gpu.GraphicsPipeline {
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

    const pip = try device.createGraphicsPipeline(.{
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
    errdefer device.releaseGraphicsPipeline(pip);

    return pip;
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
