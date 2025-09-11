pub const sdl3 = @import("sdl3");
const TextureSampler = @import("TextureSampler.zig");

pub var white_texture: TextureSampler = undefined;
pub var black_texture: TextureSampler = undefined;
pub var normal_texture: TextureSampler = undefined;

pub fn init() !void {
    white_texture = tex: {
        const surface = try sdl3.surface.Surface.initFrom(1, 1, sdl3.pixels.Format.array_rgba_32, &.{ 255, 255, 255, 255 });
        defer surface.deinit();
        break :tex try TextureSampler.fromSurface(surface, .{});
    };
    errdefer white_texture.deinit();
    black_texture = tex: {
        const surface = try sdl3.surface.Surface.initFrom(1, 1, sdl3.pixels.Format.array_rgba_32, &.{ 0, 0, 0, 255 });
        defer surface.deinit();
        break :tex try TextureSampler.fromSurface(surface, .{});
    };
    errdefer black_texture.deinit();
    normal_texture = tex: {
        const surface = try sdl3.surface.Surface.initFrom(1, 1, sdl3.pixels.Format.array_rgba_32, &.{ 128, 128, 255, 255 });
        defer surface.deinit();
        break :tex try TextureSampler.fromSurface(surface, .{});
    };
    errdefer normal_texture.deinit();
}

pub fn deinit() void {
    normal_texture.deinit();
    black_texture.deinit();
    white_texture.deinit();
}
