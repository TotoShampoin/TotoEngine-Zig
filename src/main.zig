const std = @import("std");
const engine = @import("toto-engine");

const sdl3 = engine.sdl3;
const zm = engine.zm;

const vertices = [_]engine.Vertex{
    .{ .position = .{ 0.0, 0.5, 0.0 }, .color = .{ 1.0, 0.0, 0.0, 1.0 } },
    .{ .position = .{ -0.5, -0.5, 0.0 }, .color = .{ 0.0, 1.0, 0.0, 1.0 } },
    .{ .position = .{ 0.5, -0.5, 0.0 }, .color = .{ 0.0, 0.0, 1.0, 1.0 } },
};

pub fn main() !void {
    try sdl3.init(.everything);
    defer sdl3.quit(.everything);

    const window = try sdl3.video.Window.init("TotoEngine test", 960, 720, .{ .resizable = true });
    defer window.deinit();
    const device = try sdl3.gpu.Device.init(.{ .spirv = true, .msl = true }, true, "vulkan");
    defer device.deinit();
    try device.claimWindow(window);

    const mesh = try engine.Mesh.create(device, &vertices, &.{ 0, 1, 2 });
    defer mesh.release(device);

    const pipeline = try engine.RenderPass.createPipeline(device, window);
    defer device.releaseGraphicsPipeline(pipeline);

    var fps_capper = sdl3.extras.FramerateCapper(f32){ .mode = .{ .limited = 120 } };

    var running = true;
    while (running) {
        const dt = fps_capper.delay();
        _ = dt;

        while (sdl3.events.poll()) |e|
            switch (e) {
                .quit => running = false,
                else => {},
            };

        const command_buffer = try device.acquireCommandBuffer();
        const render_pass = try engine.RenderPass.begin(command_buffer, window) orelse {
            try command_buffer.cancel();
            continue;
        };

        render_pass.draw(pipeline, mesh);

        render_pass.end();
        try command_buffer.submit();
    }
}
