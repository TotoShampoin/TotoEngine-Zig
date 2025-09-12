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

    const c = engine._context.ctx.?;
    const device = c.device;

    try engine.RenderPass.init();
    defer engine.RenderPass.deinit();

    // const white_texture = engine.defaults.white_texture;
    const black_texture = engine.defaults.black_texture;

    const sampler = try device.createSampler(.{
        .address_mode_u = .clamp_to_edge,
        .address_mode_v = .clamp_to_edge,
        .min_filter = .linear,
        .mag_filter = .linear,
        .mipmap_mode = .linear,
        .max_anisotropy = 16,
    });
    defer device.releaseSampler(sampler);

    const earth_texture = try engine.texture_loader.load("res/earth_noClouds.0330.jpg", true);
    defer device.releaseTexture(earth_texture);

    const earth_lights_texture = try engine.texture_loader.load("res/earth_lights.jpg", true);
    defer device.releaseTexture(earth_lights_texture);

    const moon_texture = try engine.texture_loader.load("res/lroc_color_poles_2k.jpg", true);
    defer device.releaseTexture(moon_texture);

    const moon_normal_texture = try engine.texture_loader.load("res/ldem_3_8bit_normal.png", true);
    defer device.releaseTexture(moon_normal_texture);

    const sphere_geometry = try engine.Geometry.create(@import("shapes/sphere.zig").sphere());
    defer sphere_geometry.release();

    var camera = engine.Camera{
        .projection = .perspective(std.math.degreesToRadians(fov), 4.0 / 3.0, 0.1, 100.0),
    };
    var camera_transform = engine.Transform{ .translation = .{ 0, 2, 2 } };
    camera_transform.lookAtLocal(zero, up);

    const sun = engine.Light{ .type = .directional };
    var sun_transform = engine.Transform{ .translation = .{ -1, 2, -1 } };
    sun_transform.lookAtLocal(zero, up);

    var earth_node: engine.Node = undefined;
    var moon_node: engine.Node = undefined;

    var moon_probe_node = engine.Node{
        .object = .{ .light = &.{
            .type = .point,
            .color = .{ 1, 0, 1, 1 },
            .range = 1,
        } },
        .parent = &moon_node,
        .transform = .{
            .translation = .{ 1.5, 0, 0 },
        },
    };

    const earth_material = engine.Material{
        .color = .{ 1, 1, 1, 1 },
        .specular = .{ 0, 0, 0, 0 },
        .shininess = 1,
        .normal_strength = 0,
        .albedo = .{
            .texture = earth_texture,
            .sampler = sampler,
        },
        .emissive = .{
            .texture = earth_lights_texture,
            .sampler = sampler,
        },
        .normal = .{
            .texture = engine.defaults.normal_texture,
            .sampler = sampler,
        },
    };
    const moon_material = engine.Material{
        .color = .{ 1, 1, 1, 1 },
        .specular = .{ 0.5, 0.5, 0.5, 1 },
        .shininess = 8,
        .normal_strength = 0.25,
        .albedo = .{
            .texture = moon_texture,
            .sampler = sampler,
        },
        .emissive = .{
            .texture = black_texture,
            .sampler = sampler,
        },
        .normal = .{
            .texture = moon_normal_texture,
            .sampler = sampler,
        },
    };

    moon_node = engine.Node{
        .object = .{
            .mesh = &.{.{
                .geometry = &sphere_geometry,
                .material = &earth_material,
                // .material = &moon_material,
            }},
        },
        .parent = &earth_node,
        .children = &.{&moon_probe_node},
        .transform = .{
            .translation = .{ 2, 0, 0 },
            .scaling = .{ 0.25, 0.25, 0.25 },
        },
    };

    earth_node = engine.Node{
        .object = .{
            .mesh = &.{.{
                .geometry = &sphere_geometry,
                .material = &moon_material,
                // .material = &earth_material,
            }},
        },
        .children = &.{&moon_node},
    };

    var fps_capper = sdl3.extras.FramerateCapper(f32){ .mode = .unlimited };

    var running = true;
    while (running) {
        const dt = fps_capper.delay();

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

        earth_node.transform.rotation = zm.Quaternionf.fromAxisAngle(up, 0.1 * dt).multiply(earth_node.transform.rotation);
        moon_node.transform.rotation = zm.Quaternionf.fromAxisAngle(up, 0.5 * dt).multiply(moon_node.transform.rotation);

        const render_pass = try engine.RenderPass.begin() orelse continue;

        render_pass.setCamera(camera, camera_transform.matrix());
        render_pass.setLights(
            &.{ sun, moon_probe_node.object.?.light.* },
            &.{ sun_transform.matrix(), moon_probe_node.worldMatrix() },
        );

        render_pass.setTransform(earth_node.worldMatrix());
        for (earth_node.object.?.mesh) |primitive| {
            render_pass.setMaterial(primitive.material.*);
            render_pass.draw(primitive.geometry.*);
        }
        render_pass.setTransform(moon_node.worldMatrix());
        for (moon_node.object.?.mesh) |primitive| {
            render_pass.setMaterial(primitive.material.*);
            render_pass.draw(primitive.geometry.*);
        }

        try render_pass.end();
    }
}
