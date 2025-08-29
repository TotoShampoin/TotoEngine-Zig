const std = @import("std");
const engine = @import("toto-engine");

const sdl3 = engine.sdl3;
const zm = engine.zm;

const Model = struct {
    vertices: []const engine.Vertex,
    indices: []const u32,
};

pub fn main() !void {
    try sdl3.init(.everything);
    defer sdl3.quit(.everything);

    const window = try sdl3.video.Window.init("TotoEngine test", 960, 720, .{ .resizable = true });
    defer window.deinit();
    const device = try sdl3.gpu.Device.init(.{ .spirv = true }, true, "vulkan");
    defer device.deinit();
    try device.claimWindow(window);

    var depth_texture = try device.createTexture(.{
        .format = .depth24_unorm_s8_uint,
        .width = 960,
        .height = 720,
        .layer_count_or_depth = 1,
        .num_levels = 1,
        .sample_count = .no_multisampling,
        .texture_type = .two_dimensional,
        .usage = .{ .depth_stencil_target = true },
    });
    defer device.releaseTexture(depth_texture);

    const model: Model = @import("./cube.zon");
    const mesh = try engine.Mesh.create(device, model.vertices, model.indices);
    defer mesh.release(device);

    const pipeline = try engine.RenderPass.createPipeline(device, window);
    defer device.releaseGraphicsPipeline(pipeline);

    var fps_capper = sdl3.extras.FramerateCapper(f32){ .mode = .{ .limited = 120 } };

    var camera = engine.Camera.createPerspective(.{
        .fov = std.math.degreesToRadians(30.0),
        .aspect = 4.0 / 3.0,
        .near = 0.1,
        .far = 100.0,
    });
    const a = std.math.degreesToRadians(36);
    const z = std.math.degreesToRadians(45);
    camera.transform.translation = .{
        std.math.sin(z) * std.math.cos(a) * 20,
        std.math.sin(a) * 20,
        std.math.cos(z) * std.math.cos(a) * 20,
    };
    camera.transform.lookAt(zm.vec.zero(3, f32), zm.vec.up(f32));

    var running = true;
    while (running) {
        const dt = fps_capper.delay();
        _ = dt;

        while (sdl3.events.poll()) |ev|
            switch (ev) {
                .window_resized => |e| {
                    device.releaseTexture(depth_texture);
                    depth_texture = try device.createTexture(.{
                        .format = .depth24_unorm_s8_uint,
                        .width = @intCast(e.width),
                        .height = @intCast(e.height),
                        .layer_count_or_depth = 1,
                        .num_levels = 1,
                        .sample_count = .no_multisampling,
                        .texture_type = .two_dimensional,
                        .usage = .{ .depth_stencil_target = true },
                    });
                },
                .quit => running = false,
                else => {},
            };

        const command_buffer = try device.acquireCommandBuffer();
        const render_pass = try engine.RenderPass.begin(command_buffer, window, depth_texture) orelse {
            try command_buffer.cancel();
            continue;
        };

        render_pass.draw(pipeline, mesh, .{ .color = .{ 1, 1, 1, 1 } }, .{}, camera);

        render_pass.end();
        try command_buffer.submit();
    }
}
