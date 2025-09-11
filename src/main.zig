const std = @import("std");
const engine = @import("toto-engine");

const sdl3 = engine.sdl3;
const zm = engine.zm;

pub fn main() !void {
    try engine.init("TotoEngine test", 960, 720, .{ .resizable = true, .vulkan = true });
    defer engine.deinit();

    try engine.RenderPass.init();
    defer engine.RenderPass.deinit();

    const white_texture = try engine.TextureSampler.create(.{
        .width = 1,
        .height = 1,
        .format = .r8g8b8a8_unorm_srgb,
        .layer_count_or_depth = 1,
        .num_levels = 1,
        .usage = .{ .sampler = true, .color_target = true },
    }, .{});
    defer white_texture.deinit();
    {
        const surface = try sdl3.surface.Surface.initFrom(1, 1, sdl3.pixels.Format.array_rgba_32, &.{ 255, 255, 255, 255 });
        defer surface.deinit();
        try white_texture.fillFromSurface(surface);
    }

    const earth_texture = try engine.TextureSampler.load("res/earth_noClouds.0330.jpg", .{
        .address_mode_u = .clamp_to_edge,
        .address_mode_v = .clamp_to_edge,
        .min_filter = .linear,
        .mag_filter = .linear,
        .mipmap_mode = .linear,
        .max_anisotropy = 16,
    });
    defer earth_texture.deinit();
    try earth_texture.generateMipmaps();

    const moon_texture = try engine.TextureSampler.load("res/lroc_color_poles_2k.jpg", .{
        .address_mode_u = .clamp_to_edge,
        .address_mode_v = .clamp_to_edge,
        .min_filter = .linear,
        .mag_filter = .linear,
        .mipmap_mode = .linear,
        .max_anisotropy = 16,
    });
    defer moon_texture.deinit();
    try moon_texture.generateMipmaps();

    const sphere_model: engine.Model = @import("./shapes/sphere.zig").sphere();
    const sphere_mesh = try engine.Mesh.create(sphere_model.vertices, sphere_model.indices);
    defer sphere_mesh.release();

    // var fps_capper = sdl3.extras.FramerateCapper(f32){ .mode = .{ .limited = 120 } };
    var fps_capper = sdl3.extras.FramerateCapper(f32){ .mode = .unlimited };

    const fov = 60.0;
    var camera = engine.Camera{
        .projection = .perspective(
            std.math.degreesToRadians(fov),
            4.0 / 3.0,
            0.1,
            100.0,
        ),
    };
    const a = std.math.degreesToRadians(36);
    const z = std.math.degreesToRadians(45);
    const r = 4;
    camera.transform.translation = .{
        std.math.sin(z) * std.math.cos(a) * r,
        std.math.sin(a) * r,
        std.math.cos(z) * std.math.cos(a) * r,
    };
    camera.transform.lookAt(.{ 0, 0, 0 }, .{ 0, 1, 0 });

    var light = engine.LightObject{
        .light = .{},
        .transform = .{},
    };
    light.transform.translation = .{ 0, 3, 3 };
    light.transform.lookAt(.{ 0, 0, 0 }, .{ 0, 1, 0 });

    var buffer: [1]*engine.Transform = undefined;
    var earth_transform = engine.Transform{
        .children = .initBuffer(&buffer),
    };
    var moon_transform = engine.Transform{
        .translation = .{ 0, 1, 1.5 },
        .scaling = .{ 0.25, 0.25, 0.25 },
        .parent = &earth_transform,
    };
    earth_transform.children.appendAssumeCapacity(&moon_transform);

    const up = zm.vec.up(f32);
    const axisAngle = zm.Quaternionf.fromAxisAngle;

    var running = true;
    while (running) {
        const dt = fps_capper.delay();
        // _ = dt;
        // const t = @as(f32, @floatFromInt(fps_capper.elapsed_ns)) / @as(f32, @floatFromInt(std.time.ns_per_s));

        while (sdl3.events.poll()) |ev|
            switch (ev) {
                .window_resized => |e| {
                    camera.projection = .perspective(
                        std.math.degreesToRadians(fov),
                        @as(f32, @floatFromInt(e.width)) / @as(f32, @floatFromInt(e.height)),
                        0.1,
                        100.0,
                    );
                },
                .quit => running = false,
                else => {},
            };

        light.transform.rotation = axisAngle(up, -3 * dt).multiply(light.transform.rotation);
        earth_transform.rotation = axisAngle(up, 1 * dt).multiply(earth_transform.rotation);
        moon_transform.rotation = axisAngle(up, -2 * dt).multiply(moon_transform.rotation);

        const render_pass = try engine.RenderPass.begin() orelse continue;

        render_pass.setCamera(camera);
        render_pass.setLights(&.{light});

        render_pass.renderMeshObject(.{
            .mesh = sphere_mesh,
            .material = .{
                .color = .{ 1, 1, 1, 1 },
                .texture = earth_texture,
            },
            .transform = earth_transform,
        });

        render_pass.renderMeshObject(.{
            .mesh = sphere_mesh,
            .material = .{
                .color = .{ 1, 1, 1, 1 },
                .texture = moon_texture,
            },
            .transform = moon_transform,
        });

        try render_pass.end();
    }
}
