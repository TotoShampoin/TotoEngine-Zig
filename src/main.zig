const std = @import("std");
const engine = @import("toto-engine");

const sdl3 = engine.sdl3;
const zm = engine.zm;

pub fn main() !void {
    try engine.init("TotoEngine test", 960, 720, .{ .resizable = true, .vulkan = true });
    defer engine.deinit();

    try engine.RenderPass.init();
    defer engine.RenderPass.deinit();

    const placeholder_texture = try engine.TextureSampler.load("res/image.png", .{
        .address_mode_u = .clamp_to_edge,
        .address_mode_v = .clamp_to_edge,
        .min_filter = .linear,
        .mag_filter = .linear,
        .mipmap_mode = .linear,
    });
    defer placeholder_texture.deinit();
    try placeholder_texture.generateMipmaps();

    const model: engine.Model = @import("./cube.zon");
    const mesh = try engine.Mesh.create(model.vertices, model.indices);
    defer mesh.release();

    // var fps_capper = sdl3.extras.FramerateCapper(f32){ .mode = .{ .limited = 120 } };
    var fps_capper = sdl3.extras.FramerateCapper(f32){ .mode = .unlimited };

    var camera = engine.Camera.createPerspective(.{
        .fov = std.math.degreesToRadians(30.0),
        .aspect = 4.0 / 3.0,
        .near = 0.1,
        .far = 100.0,
    });
    const a = std.math.degreesToRadians(36);
    const z = std.math.degreesToRadians(45);
    const r = 4;
    camera.transform.translation = .{
        std.math.sin(z) * std.math.cos(a) * r,
        std.math.sin(a) * r,
        std.math.cos(z) * std.math.cos(a) * r,
    };
    camera.transform.lookAt(zm.vec.zero(3, f32), zm.vec.up(f32));

    var transform = engine.Transform{};

    var running = true;
    while (running) {
        const t = @as(f32, @floatFromInt(fps_capper.elapsed_ns)) / @as(f32, @floatFromInt(std.time.ns_per_s));
        const dt = fps_capper.delay();

        _ = dt;

        while (sdl3.events.poll()) |ev|
            switch (ev) {
                .window_resized => |e| {
                    camera.setPerspective(.{
                        .fov = std.math.degreesToRadians(30.0),
                        .aspect = @as(f32, @floatFromInt(e.width)) / @as(f32, @floatFromInt(e.height)),
                        .near = 0.1,
                        .far = 100.0,
                    });
                },
                .quit => running = false,
                else => {},
            };

        // transform.rotation = transform.rotation.multiply(.fromAxisAngle(zm.vec.up(f32), dt));
        transform.rotation = zm.Quaternionf.fromAxisAngle(zm.vec.up(f32), t)
            .multiply(.fromAxisAngle(zm.vec.right(f32), t))
            .multiply(.fromAxisAngle(zm.vec.forward(f32), t));

        const render_pass = try engine.RenderPass.begin() orelse continue;

        render_pass.draw(mesh, .{
            .color = .{ 1, 1, 1, 1 },
            .texture = placeholder_texture,
        }, transform, camera);

        try render_pass.end();
    }
}
