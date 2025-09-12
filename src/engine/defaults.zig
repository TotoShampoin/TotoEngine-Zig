pub const sdl3 = @import("sdl3");

const _context = @import("_context.zig");
const texture_loader = @import("texture_loader.zig");

pub var white_texture: sdl3.gpu.Texture = undefined;
pub var black_texture: sdl3.gpu.Texture = undefined;
pub var normal_texture: sdl3.gpu.Texture = undefined;

pub fn init() !void {
    const c = _context.ctx orelse return error.NoInit;
    const device = c.device;

    white_texture = tex: {
        const surface = try sdl3.surface.Surface.initFrom(1, 1, sdl3.pixels.Format.array_rgba_32, &.{ 255, 255, 255, 255 });
        defer surface.deinit();
        break :tex try texture_loader.fromSurface(surface, false);
    };
    errdefer device.releaseTexture(white_texture);
    black_texture = tex: {
        const surface = try sdl3.surface.Surface.initFrom(1, 1, sdl3.pixels.Format.array_rgba_32, &.{ 0, 0, 0, 255 });
        defer surface.deinit();
        break :tex try texture_loader.fromSurface(surface, false);
    };
    errdefer device.releaseTexture(black_texture);
    normal_texture = tex: {
        const surface = try sdl3.surface.Surface.initFrom(1, 1, sdl3.pixels.Format.array_rgba_32, &.{ 128, 128, 255, 255 });
        defer surface.deinit();
        try surface.setColorspace(.srgb_linear);
        break :tex try texture_loader.fromSurface(surface, false);
    };
    errdefer device.releaseTexture(normal_texture);
}

pub fn deinit() void {
    const c = _context.ctx orelse return;
    const device = c.device;

    device.releaseTexture(white_texture);
    device.releaseTexture(black_texture);
    device.releaseTexture(normal_texture);
}
