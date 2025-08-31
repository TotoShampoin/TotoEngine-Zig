const std = @import("std");
const engine = @import("toto-engine");

const sdl3 = engine.sdl3;
const zm = engine.zm;

pub fn main() !void {
    try sdl3.init(.everything);
    defer sdl3.quit(.everything);

    // For the moment, zig's sdl3 can't seem to be able to load an image while the device is being used...
    const surface = img: {
        // const image = try sdl3.image.loadFile("res/image.png");
        const image = try sdl3.image.loadFile("res/image_indexed.png");
        errdefer image.deinit();
        try image.flip(.{ .vertical = true });
        break :img image;
    };
    defer surface.deinit();

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

    const placeholder_texture = try createTextureAndSampler(device, surface, .{});
    defer {
        device.releaseTexture(placeholder_texture.texture);
        device.releaseSampler(placeholder_texture.sampler);
    }

    const model: engine.Model = @import("./cube.zon");
    const mesh = try engine.Mesh.create(device, model.vertices, model.indices);
    defer mesh.release(device);

    const pipeline = try engine.RenderPass.createPipeline(device, window);
    defer device.releaseGraphicsPipeline(pipeline);

    var fps_capper = sdl3.extras.FramerateCapper(f32){ .mode = .{ .limited = 120 } };

    var camera = engine.Camera.createPerspective(.{
        .fov = std.math.degreesToRadians(60.0),
        .aspect = 4.0 / 3.0,
        .near = 0.1,
        .far = 100.0,
    });
    const a = std.math.degreesToRadians(36);
    const z = std.math.degreesToRadians(45);
    const r = 5;
    camera.transform.translation = .{
        std.math.sin(z) * std.math.cos(a) * r,
        std.math.sin(a) * r,
        std.math.cos(z) * std.math.cos(a) * r,
    };
    camera.transform.lookAt(zm.vec.zero(3, f32), zm.vec.up(f32));

    var transform = engine.Transform{};

    var running = true;
    while (running) {
        const dt = fps_capper.delay();
        // _ = dt;

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

        transform.rotation = transform.rotation.multiply(.fromAxisAngle(zm.vec.up(f32), dt));

        const command_buffer = try device.acquireCommandBuffer();
        const render_pass = try engine.RenderPass.begin(command_buffer, window, depth_texture) orelse {
            try command_buffer.cancel();
            continue;
        };

        render_pass.draw(pipeline, mesh, .{
            .color = .{ 1, 1, 1, 1 },
            .texture = placeholder_texture,
        }, transform, camera);

        render_pass.end();
        try command_buffer.submit();
    }
}

pub fn createTextureAndSampler(device: sdl3.gpu.Device, surface: sdl3.surface.Surface, sampler_info: sdl3.gpu.SamplerCreateInfo) !sdl3.gpu.TextureSamplerBinding {
    const image = try surface.convertFormat(.array_rgba_32);
    defer image.deinit();

    const width: u32 = @intCast(image.getWidth());
    const height: u32 = @intCast(image.getHeight());
    const pitch: u32 = @intCast(image.getPitch());
    const pixels = image.getPixels() orelse return error.NoPixels;
    const format = image.getFormat() orelse return error.NoFormal;
    const pixel_size: u32 = sdl3.pixels.Format.getBytesPerPixel(format);

    const texture = try device.createTexture(.{
        .format = .r8g8b8a8_unorm,
        .width = width,
        .height = height,
        .layer_count_or_depth = 1,
        .num_levels = 1,
        .sample_count = .no_multisampling,
        .texture_type = .two_dimensional,
        .usage = .{ .sampler = true },
    });
    errdefer device.releaseTexture(texture);

    const transfer_buffer = try device.createTransferBuffer(.{
        .size = height * pitch,
        .usage = .upload,
    });
    defer device.releaseTransferBuffer(transfer_buffer);

    var buffer_map = try device.mapTransferBuffer(transfer_buffer, false);
    for (pixels, buffer_map[0..]) |v, *d| d.* = v;

    device.unmapTransferBuffer(transfer_buffer);

    const copy_command_buffer = try device.acquireCommandBuffer();
    const copy_pass = copy_command_buffer.beginCopyPass();
    copy_pass.uploadToTexture(.{
        .transfer_buffer = transfer_buffer,
        .offset = 0,
        .pixels_per_row = pitch / pixel_size,
        .rows_per_layer = height,
    }, .{
        .texture = texture,
        .mip_level = 0,
        .layer = 0,
        .x = 0,
        .y = 0,
        .width = width,
        .height = height,
        .depth = 1,
    }, false);
    copy_pass.end();
    try copy_command_buffer.submit();

    const sampler = try device.createSampler(sampler_info);
    errdefer device.releaseSampler(sampler);

    return .{ .texture = texture, .sampler = sampler };
}
