const std = @import("std");
const engine = @import("toto-engine");

const sdl3 = engine.sdl3;
const zm = engine.zm;

const fov = 60.0;

const zero = zm.vec.zero(3, f32);
const up = zm.vec.up(f32);

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
    const black_texture = try engine.TextureSampler.create(.{
        .width = 1,
        .height = 1,
        .format = .r8g8b8a8_unorm_srgb,
        .layer_count_or_depth = 1,
        .num_levels = 1,
        .usage = .{ .sampler = true, .color_target = true },
    }, .{});
    defer black_texture.deinit();
    {
        const surface = try sdl3.surface.Surface.initFrom(1, 1, sdl3.pixels.Format.array_rgba_32, &.{ 0, 0, 0, 255 });
        defer surface.deinit();
        try black_texture.fillFromSurface(surface);
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

    const earth_lights_texture = try engine.TextureSampler.load("res/earth_lights.jpg", .{
        .address_mode_u = .clamp_to_edge,
        .address_mode_v = .clamp_to_edge,
        .min_filter = .linear,
        .mag_filter = .linear,
        .mipmap_mode = .linear,
        .max_anisotropy = 16,
    });
    defer earth_lights_texture.deinit();
    try earth_lights_texture.generateMipmaps();

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

    var fps_capper = sdl3.extras.FramerateCapper(f32){ .mode = .unlimited };

    var camera_node = engine.Node{
        .object = .{ .camera = .{
            .projection = .perspective(std.math.degreesToRadians(fov), 4.0 / 3.0, 0.1, 100.0),
        } },
    };
    camera_node.transform.translation = .{ 2, 2, 2 };
    camera_node.transform.lookAt(zero, up);

    var sun_node = engine.Node{ .object = .{ .light = .{} } };
    sun_node.transform.translation = .{ -1, 2, 1 };
    sun_node.transform.lookAt(zero, up);

    const sphere_geometry = try engine.Geometry.create(@import("shapes/sphere.zig").sphere());
    defer sphere_geometry.release();

    var earth_primitive = engine.Primitive{
        .geometry = sphere_geometry,
        .material = .{
            .color = .{ 1, 1, 1, 1 },
            .specular = .{ 0, 0, 0, 0 },
            .shininess = 0,
            .albedo = earth_texture,
            .emissive = earth_lights_texture,
        },
    };
    var earth_mesh = [_]*engine.Primitive{&earth_primitive};
    var earth_children: [1]*engine.Node = undefined;
    var earth_node = engine.Node{
        .object = .{ .mesh = .fromOwnedSlice(earth_mesh[0..]) },
        .children = .initBuffer(&earth_children),
    };

    var moon_primitive = engine.Primitive{
        .geometry = sphere_geometry,
        .material = .{
            .color = .{ 1, 1, 1, 1 },
            .specular = .{ 0.5, 0.5, 0.5, 1 },
            .shininess = 8,
            .albedo = moon_texture,
            .emissive = black_texture,
        },
    };
    var moon_mesh = [_]*engine.Primitive{&moon_primitive};
    var moon_node = engine.Node{
        .object = .{ .mesh = .fromOwnedSlice(moon_mesh[0..]) },
        .parent = &earth_node,
        .transform = .{
            .translation = .{ 1.5, 0, 0 },
            .scaling = .{ 0.25, 0.25, 0.25 },
        },
    };
    earth_node.children.appendAssumeCapacity(&moon_node);

    var running = true;
    while (running) {
        const dt = fps_capper.delay();

        while (sdl3.events.poll()) |ev|
            switch (ev) {
                .window_resized => |e| {
                    camera_node.object.?.camera.projection = .perspective(
                        std.math.degreesToRadians(fov),
                        @as(f32, @floatFromInt(e.width)) / @as(f32, @floatFromInt(e.height)),
                        0.1,
                        100.0,
                    );
                },
                .quit => running = false,
                else => {},
            };

        earth_node.transform.rotation = zm.Quaternionf.fromAxisAngle(up, 0.1 * dt).multiply(earth_node.transform.rotation);
        moon_node.transform.rotation = zm.Quaternionf.fromAxisAngle(up, 0.5 * dt).multiply(moon_node.transform.rotation);

        const render_pass = try engine.RenderPass.begin() orelse continue;

        render_pass.setCamera(camera_node.object.?.camera, camera_node.worldMatrix());
        render_pass.setLights(&.{sun_node.object.?.light}, &.{sun_node.worldMatrix()});

        render_pass.setTransform(earth_node.worldMatrix());
        for (earth_node.object.?.mesh.items) |primitive| {
            render_pass.setMaterial(primitive.material);
            render_pass.draw(primitive.geometry);
        }
        render_pass.setTransform(moon_node.worldMatrix());
        for (moon_node.object.?.mesh.items) |primitive| {
            render_pass.setMaterial(primitive.material);
            render_pass.draw(primitive.geometry);
        }

        try render_pass.end();
    }
}
