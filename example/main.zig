const std = @import("std");
const engine = @import("toto-engine");
const main_gfx = @import("main_gfx.zig");

const sdl3 = engine.sdl3;
const zm = engine.zm;

const fov = 60.0;

const zero = zm.vec.zero(3, f32);
const up = zm.vec.up(f32);
const cast = engine.math_utils.cast;

pub fn main() !void {
    try engine.init("TotoEngine test", 960, 720, .{ .resizable = true, .vulkan = true });
    defer engine.deinit();

    var renderer = try engine.Renderer.init();
    defer renderer.deinit();

    try main_gfx.init();
    defer main_gfx.deinit();

    var fps_capper = sdl3.extras.FramerateCapper(f32){ .mode = .unlimited };

    var running = true;
    while (running) {
        const dt = fps_capper.delay();

        while (sdl3.events.poll()) |ev|
            switch (ev) {
                .window_resized => |e| {
                    main_gfx.camera = .perspective(std.math.degreesToRadians(fov), cast(f32, e.width) / cast(f32, e.height), 0.1, 100.0);
                },
                .quit => running = false,
                else => {},
            };

        main_gfx.earth_node.transform.rotation = zm.Quaternionf.fromAxisAngle(up, 0.1 * dt).multiply(main_gfx.earth_node.transform.rotation);
        main_gfx.moon_node.transform.rotation = zm.Quaternionf.fromAxisAngle(up, 0.5 * dt).multiply(main_gfx.moon_node.transform.rotation);

        const render_pass = try renderer.begin() orelse continue;

        render_pass.setCamera(main_gfx.camera, main_gfx.camera_transform.matrix());
        render_pass.setLights(
            &.{ main_gfx.sun, main_gfx.moon_probe_node.object.?.light.* },
            &.{ main_gfx.sun_transform.matrix(), main_gfx.moon_probe_node.worldMatrix() },
        );

        render_pass.setTransform(main_gfx.earth_node.worldMatrix());
        if (main_gfx.earth_node.asMesh()) |m| for (m) |primitive| {
            render_pass.setMaterial(primitive.material.*);
            render_pass.draw(primitive.geometry.*);
        };
        render_pass.setTransform(main_gfx.moon_node.worldMatrix());
        if (main_gfx.moon_node.asMesh()) |m| for (m) |primitive| {
            render_pass.setMaterial(primitive.material.*);
            render_pass.draw(primitive.geometry.*);
        };

        try render_pass.end();
    }
}
