const std = @import("std");
const engine = @import("toto-engine");

const sdl3 = engine.sdl3;
const zm = engine.zm;

pub fn main() !void {
    try sdl3.init(.everything);
    defer sdl3.quit(.everything);

    const window = try sdl3.video.Window.init("TotoEngine test", 960, 720, .{ .resizable = true });
    defer window.deinit();
    const device = try sdl3.gpu.Device.init(.{ .spirv = true }, true, "vulkan");
    defer device.deinit();

    try device.claimWindow(window);

    defer engine.RenderPass.deinit(device);

    const placeholder_texture = try engine.TextureSampler.load("res/image.png", .{
        .address_mode_u = .clamp_to_edge,
        .address_mode_v = .clamp_to_edge,
        .min_filter = .linear,
        .mag_filter = .linear,
        .mipmap_mode = .linear,
    }, device);
    defer placeholder_texture.deinit(device);
    try placeholder_texture.generateMipmaps(device);

    const model: engine.Model = @import("./cube.zon");
    const mesh = try engine.Mesh.create(model.vertices, model.indices, device);
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
        const dt = fps_capper.delay();

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

        transform.rotation = transform.rotation.multiply(.fromAxisAngle(zm.vec.up(f32), dt));

        const command_buffer = try device.acquireCommandBuffer();
        const render_pass = try engine.RenderPass.begin(command_buffer, window, device) orelse {
            try command_buffer.cancel();
            continue;
        };

        render_pass.draw(pipeline, mesh, .{
            .color = .{ 1, 1, 1, 1 },
            .texture = placeholder_texture.toBinding(),
        }, transform, camera);

        render_pass.end();
        try command_buffer.submit();
    }
}

// pub fn loadTextureAndSampler(device: sdl3.gpu.Device, image_path: [:0]const u8, sampler_info: sdl3.gpu.SamplerCreateInfo) !sdl3.gpu.TextureSamplerBinding {
//     const surface = try sdl3.image.loadFile(image_path);
//     defer surface.deinit();
//     try surface.flip(.{ .vertical = true });
//     return try createTextureAndSampler(device, surface, sampler_info);
// }
// pub fn deinitTextureAndSampler(device: sdl3.gpu.Device, texture_sampler: sdl3.gpu.TextureSamplerBinding) void {
//     device.releaseTexture(texture_sampler.texture);
//     device.releaseSampler(texture_sampler.sampler);
// }

// pub fn createTextureAndSampler(device: sdl3.gpu.Device, image: sdl3.surface.Surface, sampler_info: sdl3.gpu.SamplerCreateInfo) !sdl3.gpu.TextureSamplerBinding {
//     const surface = try image.convertFormat(.array_rgba_32);
//     defer surface.deinit();

//     const width: u32 = @intCast(surface.getWidth());
//     const height: u32 = @intCast(surface.getHeight());
//     const pitch: u32 = @intCast(surface.getPitch());
//     const pixels = surface.getPixels() orelse return error.NoPixels;
//     const format = surface.getFormat() orelse return error.NoFormal;
//     const pixel_size: u32 = sdl3.pixels.Format.getBytesPerPixel(format);

//     const texture = try device.createTexture(.{
//         .format = .r8g8b8a8_unorm,
//         .width = width,
//         .height = height,
//         .layer_count_or_depth = 1,
//         .num_levels = 1,
//         .sample_count = .no_multisampling,
//         .texture_type = .two_dimensional,
//         .usage = .{ .sampler = true },
//     });
//     errdefer device.releaseTexture(texture);

//     const transfer_buffer = try device.createTransferBuffer(.{
//         .size = height * pitch,
//         .usage = .upload,
//     });
//     defer device.releaseTransferBuffer(transfer_buffer);

//     var buffer_map = try device.mapTransferBuffer(transfer_buffer, false);
//     for (pixels, buffer_map[0..]) |v, *d| d.* = v;

//     device.unmapTransferBuffer(transfer_buffer);

//     const copy_command_buffer = try device.acquireCommandBuffer();
//     const copy_pass = copy_command_buffer.beginCopyPass();
//     copy_pass.uploadToTexture(.{
//         .transfer_buffer = transfer_buffer,
//         .offset = 0,
//         .pixels_per_row = pitch / pixel_size,
//         .rows_per_layer = height,
//     }, .{
//         .texture = texture,
//         .mip_level = 0,
//         .layer = 0,
//         .x = 0,
//         .y = 0,
//         .width = width,
//         .height = height,
//         .depth = 1,
//     }, false);
//     copy_pass.end();
//     try copy_command_buffer.submit();

//     const sampler = try device.createSampler(sampler_info);
//     errdefer device.releaseSampler(sampler);

//     return .{ .texture = texture, .sampler = sampler };
// }
