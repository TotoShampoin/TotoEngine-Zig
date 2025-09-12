const std = @import("std");
const sdl3 = @import("sdl3");

const _context = @import("./utils/_context.zig");

pub fn load(image_path: [:0]const u8, with_mipmaps: bool) !sdl3.gpu.Texture {
    const surface = try sdl3.image.loadFile(image_path);
    defer surface.deinit();
    try surface.flip(.{ .vertical = true });
    return try fromSurface(surface, with_mipmaps);
}

pub fn fromSurface(surface: sdl3.surface.Surface, with_mipmaps: bool) !sdl3.gpu.Texture {
    const c = _context.ctx orelse return error.NoInit;
    const device = c.device;

    const width: u32 = @intCast(surface.getWidth());
    const height: u32 = @intCast(surface.getHeight());

    const texture = try device.createTexture(.{
        .format = .r8g8b8a8_unorm_srgb,
        .width = width,
        .height = height,
        .layer_count_or_depth = 1,
        .num_levels = 1 + std.math.log2_int(u32, @min(width, height)),
        .sample_count = .no_multisampling,
        .texture_type = .two_dimensional,
        .usage = .{ .sampler = true, .color_target = true },
    });
    errdefer device.releaseTexture(texture);

    try fillFromSurface(texture, surface, with_mipmaps);

    return texture;
}

pub fn fillFromSurface(texture: sdl3.gpu.Texture, surface: sdl3.surface.Surface, with_mipmaps: bool) !void {
    const c = _context.ctx orelse return error.NoInit;
    const device = c.device;
    // const formatted_surface = try surface.convertFormat(.array_rgba_32);
    const formatted_surface = try surface.convertFormatAndColorspace(.array_rgba_32, null, .srgb, null);
    defer formatted_surface.deinit();

    const width: u32 = @intCast(formatted_surface.getWidth());
    const height: u32 = @intCast(formatted_surface.getHeight());
    const pitch: u32 = @intCast(formatted_surface.getPitch());
    const pixels = formatted_surface.getPixels() orelse return error.NoPixels;
    const format = formatted_surface.getFormat() orelse return error.NoFormal;
    const pixel_size: u32 = sdl3.pixels.Format.getBytesPerPixel(format);

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

    if (with_mipmaps) try generateMipmaps(texture);
}

pub fn generateMipmaps(texture: sdl3.gpu.Texture) !void {
    const c = _context.ctx orelse return error.NoInit;
    const device = c.device;
    const command_buffer = try device.acquireCommandBuffer();
    command_buffer.generateMipmapsForTexture(texture);
    try command_buffer.submit();
}
