const std = @import("std");
const sdl3 = @import("sdl3");

const _context = @import("_context.zig");
const shorthands = @import("shorthands.zig");
const types = @import("types.zig");

const Vertex = types.Vertex;
const Model = types.Model;
const Geometry = @This();

vertex_buffer: sdl3.gpu.Buffer,
index_buffer: sdl3.gpu.Buffer,
count: u32,

pub fn create(model: Model) !Geometry {
    const c = _context.ctx orelse return error.NoInit;
    const device = c.device;
    const vertex_buffer = try device.createBuffer(.{
        .size = @intCast(@sizeOf(Vertex) * model.vertices.len),
        .usage = .{ .vertex = true },
        .props = .{ .name = "Vertex buffer" },
    });
    errdefer device.releaseBuffer(vertex_buffer);

    const index_buffer = try device.createBuffer(.{
        .size = @intCast(@sizeOf(u32) * model.indices.len),
        .usage = .{ .index = true },
        .props = .{ .name = "Index buffer" },
    });
    errdefer device.releaseBuffer(index_buffer);

    try shorthands.uploadToBuffer(device, vertex_buffer, std.mem.sliceAsBytes(model.vertices));
    try shorthands.uploadToBuffer(device, index_buffer, std.mem.sliceAsBytes(model.indices));

    return Geometry{
        .vertex_buffer = vertex_buffer,
        .index_buffer = index_buffer,
        .count = @intCast(model.indices.len),
    };
}

pub fn release(self: Geometry) void {
    const c = _context.ctx orelse return;
    const device = c.device;
    device.releaseBuffer(self.vertex_buffer);
    device.releaseBuffer(self.index_buffer);
}
