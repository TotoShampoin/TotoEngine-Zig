const std = @import("std");
const sdl3 = @import("sdl3");
const zm = @import("zm");

const _context = @import("_context.zig");
const types = @import("types.zig");
const math_utils = @import("math_utils.zig");
const shorthands = @import("shorthands.zig");
const Geometry = @import("Geometry.zig");
const Transform = @import("Transform.zig");
const Renderer = @import("Renderer.zig");

const RenderPass = @This();

renderer: *Renderer,
command_buffer: sdl3.gpu.CommandBuffer,
pass: sdl3.gpu.RenderPass,
width: u32,
height: u32,

pub fn begin(renderer: *Renderer) !?RenderPass {
    const c = _context.ctx orelse return error.NoInit;
    const device = c.device;
    const window = c.window;

    const command_buffer = try device.acquireCommandBuffer();
    const swapchain = try command_buffer.waitAndAcquireSwapchainTexture(window);
    if (swapchain.texture == null) {
        try command_buffer.cancel();
        return null;
    }
    if (renderer.swapchain_texture == null or
        swapchain.texture.?.value != renderer.swapchain_texture.?.value)
    {
        if (renderer.depth_texture) |dt| {
            device.releaseTexture(dt);
            renderer.depth_texture = null;
        }
        renderer.swapchain_texture = swapchain.texture;
        renderer.depth_texture = try Renderer.createDepthTexture();
    }

    const pass = command_buffer.beginRenderPass(&.{
        sdl3.gpu.ColorTargetInfo{
            .clear_color = .{ .r = 0, .g = 0, .b = 0, .a = 1 },
            .load = .clear,
            .store = .store,
            .texture = swapchain.texture.?,
        },
    }, sdl3.gpu.DepthStencilTargetInfo{
        .texture = renderer.depth_texture.?,
        .clear_depth = 1.0,
        .clear_stencil = 0.0,
        .load = .clear,
        .store = .store,
        .stencil_load = .do_not_care,
        .stencil_store = .do_not_care,
        .cycle = true,
    });

    return .{
        .renderer = renderer,
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
    self.pass.bindGraphicsPipeline(self.renderer.pipeline);
    self.pass.bindVertexBuffers(0, &.{sdl3.gpu.BufferBinding{ .buffer = primitive.vertex_buffer, .offset = 0 }});
    self.pass.bindIndexBuffer(.{ .buffer = primitive.index_buffer, .offset = 0 }, .indices_32bit);
    self.pass.drawIndexedPrimitives(primitive.count, 1, 0, 0, 0);
}
