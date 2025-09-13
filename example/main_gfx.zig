const std = @import("std");
const engine = @import("toto-engine");
const sdl3 = engine.sdl3;
const zm = engine.zm;

pub const fov = 60.0;
pub const zero = zm.vec.zero(3, f32);
pub const up = zm.vec.up(f32);
pub const cast = engine.math_utils.cast;

pub var sampler: sdl3.gpu.Sampler = undefined;
pub var earth_texture: sdl3.gpu.Texture = undefined;
pub var earth_lights_texture: sdl3.gpu.Texture = undefined;
pub var moon_texture: sdl3.gpu.Texture = undefined;
pub var moon_normal_texture: sdl3.gpu.Texture = undefined;

pub var sun: engine.Light = undefined;
pub var sun_transform: engine.Transform = undefined;

pub var camera: engine.Camera = undefined;
pub var camera_transform: engine.Transform = undefined;

pub var sphere_geometry: engine.Geometry = undefined;
pub var earth_node: engine.Node = undefined;
pub var earth_material: engine.Material = undefined;
pub var moon_node: engine.Node = undefined;
pub var moon_material: engine.Material = undefined;
pub var moon_probe_node: engine.Node = undefined;
pub var moon_probe_material: engine.Material = undefined;

pub fn init() !void {
    const c = engine._context.ctx.?;
    const device = c.device;

    sampler = try device.createSampler(.{
        .address_mode_u = .clamp_to_edge,
        .address_mode_v = .clamp_to_edge,
        .min_filter = .linear,
        .mag_filter = .linear,
        .mipmap_mode = .linear,
        .max_anisotropy = 16,
    });
    errdefer device.releaseSampler(sampler);

    earth_texture = try engine.texture_loader.load("res/earth_noClouds.0330.jpg", true);
    errdefer device.releaseTexture(earth_texture);

    earth_lights_texture = try engine.texture_loader.load("res/earth_lights.jpg", true);
    errdefer device.releaseTexture(earth_lights_texture);

    moon_texture = try engine.texture_loader.load("res/lroc_color_poles_2k.jpg", true);
    errdefer device.releaseTexture(moon_texture);

    moon_normal_texture = try engine.texture_loader.load("res/ldem_3_8bit_normal.png", true);
    errdefer device.releaseTexture(moon_normal_texture);

    sphere_geometry = try engine.Geometry.create(@import("shapes/sphere.zig").sphere());
    errdefer sphere_geometry.release();

    camera = .perspective(std.math.degreesToRadians(fov), 4.0 / 3.0, 0.1, 100.0);
    camera_transform = engine.Transform{ .translation = .{ 2, 2, 2 } };
    camera_transform.lookAtLocal(zero, up);

    sun = engine.Light{ .type = .directional };
    sun_transform = engine.Transform{ .translation = .{ -2, 2, 2 } };
    sun_transform.lookAtLocal(zero, up);

    earth_material = .{
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
    moon_material = .{
        .color = .{ 1, 1, 1, 1 },
        .specular = .{ 0.5, 0.5, 0.5, 1 },
        .shininess = 8,
        .normal_strength = 0.25,
        .albedo = .{
            .texture = moon_texture,
            .sampler = sampler,
        },
        .emissive = .{
            .texture = engine.defaults.black_texture,
            .sampler = sampler,
        },
        .normal = .{
            .texture = moon_normal_texture,
            .sampler = sampler,
        },
    };

    moon_probe_node = engine.Node{
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
    earth_node = engine.Node{
        .object = .{
            .mesh = &.{.{
                .geometry = &sphere_geometry,
                .material = &earth_material,
            }},
        },
        .children = &.{&moon_node},
    };
    moon_node = engine.Node{
        .object = .{
            .mesh = &.{.{
                .geometry = &sphere_geometry,
                .material = &moon_material,
            }},
        },
        .parent = &earth_node,
        .children = &.{&moon_probe_node},
        .transform = .{
            .translation = .{ 2, 0, 0 },
            .scaling = .{ 0.25, 0.25, 0.25 },
        },
    };
}
pub fn deinit() void {
    const c = engine._context.ctx.?;
    const device = c.device;

    sphere_geometry.release();
    device.releaseTexture(moon_normal_texture);
    device.releaseTexture(moon_texture);
    device.releaseTexture(earth_lights_texture);
    device.releaseTexture(earth_texture);
    device.releaseSampler(sampler);
}
