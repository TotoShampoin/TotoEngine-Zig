const std = @import("std");
const sdl3 = @import("sdl3");

const RenderPass = @import("./RenderPass.zig");

window: sdl3.video.Window,
device: sdl3.gpu.Device,

pub var ctx: ?@This() = null;

pub fn init(
    title: [:0]const u8,
    width: usize,
    height: usize,
    flags: sdl3.video.Window.Flags,
) !void {
    if (ctx) |_| return error.DoubleInit;

    try sdl3.init(.everything);
    errdefer sdl3.quit(.everything);

    const window = try sdl3.video.Window.init(title, width, height, flags);
    errdefer window.deinit();
    const device = try sdl3.gpu.Device.init(.{ .spirv = true }, true, "vulkan");
    errdefer device.deinit();

    try device.claimWindow(window);
    try device.setSwapchainParameters(window, .sdr, .vsync);

    ctx = @This(){
        .window = window,
        .device = device,
    };
}
pub fn deinit() void {
    const c = ctx orelse return;
    c.device.deinit();
    c.window.deinit();
    sdl3.quit(.everything);
}
