const std = @import("std");
const engine = @import("toto-engine");

const sdl3 = engine.sdl3;
const zm = engine.zm;

pub fn main() !void {
    try engine.init("TotoEngine test", 960, 720, .{ .resizable = true, .vulkan = true });
    defer engine.deinit();

    try engine.RenderPass.init();
    defer engine.RenderPass.deinit();

    const placeholder_texture = try engine.TextureSampler.load("res/1024px-Equirectangular-projection.jpg", .{
        .address_mode_u = .clamp_to_edge,
        .address_mode_v = .clamp_to_edge,
        .min_filter = .linear,
        .mag_filter = .linear,
        .mipmap_mode = .linear,
        .max_anisotropy = 16,
    });
    defer placeholder_texture.deinit();
    try placeholder_texture.generateMipmaps();

    // const model: engine.Model = @import("./shapes/cube.zon");
    const model: engine.Model = @import("./shapes/sphere.zig").sphere();
    const mesh = try engine.Mesh.create(model.vertices, model.indices);
    defer mesh.release();

    // var fps_capper = sdl3.extras.FramerateCapper(f32){ .mode = .{ .limited = 120 } };
    var fps_capper = sdl3.extras.FramerateCapper(f32){ .mode = .unlimited };

    const fov = 60.0;
    var camera = engine.Camera.createPerspective(.{
        .fov = std.math.degreesToRadians(fov),
        .aspect = 4.0 / 3.0,
        .near = 0.1,
        .far = 100.0,
    });
    const a = std.math.degreesToRadians(36);
    const z = std.math.degreesToRadians(45);
    const r = 3;
    camera.transform.translation = .{
        std.math.sin(z) * std.math.cos(a) * r,
        std.math.sin(a) * r,
        std.math.cos(z) * std.math.cos(a) * r,
    };
    camera.transform.lookAt(.{ 0, 0, 0 }, .{ 0, 1, 0 });

    var light = engine.LightTransform{
        .light = .{},
        .transform = .{},
    };
    light.transform.translation = .{ 0, 3, 3 };
    light.transform.lookAt(.{ 0, 0, 0 }, .{ 0, 1, 0 });

    var transform = engine.Transform{};

    var running = true;
    while (running) {
        const dt = fps_capper.delay();
        // _ = dt;
        // const t = @as(f32, @floatFromInt(fps_capper.elapsed_ns)) / @as(f32, @floatFromInt(std.time.ns_per_s));

        while (sdl3.events.poll()) |ev|
            switch (ev) {
                .window_resized => |e| {
                    camera.setPerspective(.{
                        .fov = std.math.degreesToRadians(fov),
                        .aspect = @as(f32, @floatFromInt(e.width)) / @as(f32, @floatFromInt(e.height)),
                        .near = 0.1,
                        .far = 100.0,
                    });
                },
                .quit => running = false,
                else => {},
            };

        transform.rotation = transform.rotation.multiply(.fromAxisAngle(zm.vec.up(f32), dt));
        // transform.rotation = .fromEulerAngles(.{ t * 2 / 4.0, t * 3 / 4.0, t * 5 / 4.0 });

        const render_pass = try engine.RenderPass.begin() orelse continue;

        render_pass.draw(mesh, .{
            .color = .{ 1, 1, 1, 1 },
            .texture = placeholder_texture,
        }, transform, camera, &.{ light, light });

        try render_pass.end();
    }
}
