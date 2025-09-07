const std = @import("std");
const sdl3 = @import("sdl3");

const TextureSampler = @This();

texture: sdl3.gpu.Texture,
sampler: sdl3.gpu.Sampler,

pub inline fn toBinding(self: TextureSampler) sdl3.gpu.TextureSamplerBinding {
    return .{ .texture = self.texture, .sampler = self.sampler };
}

pub fn load(device: sdl3.gpu.Device, image_path: [:0]const u8, sampler_info: sdl3.gpu.SamplerCreateInfo) !TextureSampler {
    const surface = try sdl3.image.loadFile(image_path);
    defer surface.deinit();
    try surface.flip(.{ .vertical = true });
    return try create(device, surface, sampler_info);
}

pub fn generateMipmaps(self: TextureSampler, device: sdl3.gpu.Device) !void {
    const command_buffer = try device.acquireCommandBuffer();
    command_buffer.generateMipmapsForTexture(self.texture);
    try command_buffer.submit();
}

pub fn setSampler(self: TextureSampler, device: sdl3.gpu.Device, sampler_info: sdl3.gpu.SamplerCreateInfo) !void {
    const sampler = try device.createSampler(sampler_info);
    device.releaseSampler(self.sampler);
    self.sampler = sampler;
}

pub fn create(device: sdl3.gpu.Device, image: sdl3.surface.Surface, sampler_info: sdl3.gpu.SamplerCreateInfo) !TextureSampler {
    const surface = try image.convertFormat(.array_rgba_32);
    defer surface.deinit();

    const width: u32 = @intCast(surface.getWidth());
    const height: u32 = @intCast(surface.getHeight());
    const pitch: u32 = @intCast(surface.getPitch());
    const pixels = surface.getPixels() orelse return error.NoPixels;
    const format = surface.getFormat() orelse return error.NoFormal;
    const pixel_size: u32 = sdl3.pixels.Format.getBytesPerPixel(format);

    const texture = try device.createTexture(.{
        .format = .r8g8b8a8_unorm,
        .width = width,
        .height = height,
        .layer_count_or_depth = 1,
        .num_levels = std.math.log2_int(u32, @min(width, height)),
        .sample_count = .no_multisampling,
        .texture_type = .two_dimensional,
        .usage = .{ .sampler = true, .color_target = true },
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
pub fn deinit(texsam: TextureSampler, device: sdl3.gpu.Device) void {
    device.releaseTexture(texsam.texture);
    device.releaseSampler(texsam.sampler);
}
