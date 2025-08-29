const std = @import("std");
const sdl3 = @import("sdl3");
const zm = @import("zm");

pub fn mat4toMat3(m: zm.Mat4f) zm.Mat3f {
    return zm.Mat3f{
        .data = .{
            m.data[0], m.data[1], m.data[2],
            m.data[4], m.data[5], m.data[6],
            m.data[8], m.data[9], m.data[10],
        },
    };
}

pub fn mat3toMat4(m: zm.Mat3f) zm.Mat4f {
    return zm.Mat4f{
        .data = .{
            m.data[0], m.data[1], m.data[2], 0.0,
            m.data[3], m.data[4], m.data[5], 0.0,
            m.data[6], m.data[7], m.data[8], 0.0,
            0.0,       0.0,       0.0,       1.0,
        },
    };
}
pub fn mat3to4x3(m: zm.Mat3f) [12]f32 {
    return .{
        m.data[0], m.data[1], m.data[2], 0.0,
        m.data[3], m.data[4], m.data[5], 0.0,
        m.data[6], m.data[7], m.data[8], 0.0,
    };
}

pub fn parseAttributes(comptime t: type, comptime slot: u32, comptime offset: u32) [@typeInfo(t).@"struct".fields.len]sdl3.gpu.VertexAttribute {
    const info = @typeInfo(t);
    const attributes = comptime attr: {
        var attributes = [_]sdl3.gpu.VertexAttribute{undefined} ** info.@"struct".fields.len;

        for (info.@"struct".fields, 0..) |field, i| {
            attributes[i].location = i + offset;
            attributes[i].buffer_slot = slot;
            attributes[i].format = switch (field.type) {
                @Vector(1, i32), [1]i32, i32 => .i32x1,
                @Vector(2, i32), [2]i32 => .i32x2,
                @Vector(3, i32), [3]i32 => .i32x3,
                @Vector(4, i32), [4]i32 => .i32x4,
                @Vector(1, u32), [1]u32, u32 => .u32x1,
                @Vector(2, u32), [2]u32 => .u32x2,
                @Vector(3, u32), [3]u32 => .u32x3,
                @Vector(4, u32), [4]u32 => .u32x4,
                @Vector(1, f32), [1]f32, f32 => .f32x1,
                @Vector(2, f32), [2]f32 => .f32x2,
                @Vector(3, f32), [3]f32 => .f32x3,
                @Vector(4, f32), [4]f32 => .f32x4,
                @Vector(2, i8), [2]i8 => .i8x2,
                @Vector(4, i8), [4]i8 => .i8x4,
                @Vector(2, u8), [2]u8 => .u8x2,
                @Vector(4, u8), [4]u8 => .u8x4,
                @Vector(2, i16), [2]i16 => .i16x2,
                @Vector(4, i16), [4]i16 => .i16x4,
                @Vector(2, u16), [2]u16 => .u16x2,
                @Vector(4, u16), [4]u16 => .u16x4,
                @Vector(2, f16), [2]f16 => .f16x2,
                @Vector(4, f16), [4]f16 => .f16x4,
                zm.Mat4f => @panic("Unsupported type. Use 4 vec4s instead"),
                else => @panic("Unsupported type"),
            };
            attributes[i].offset = @offsetOf(t, field.name);
        }
        break :attr attributes;
    };
    return attributes;
}

pub fn uploadToBuffer(device: sdl3.gpu.Device, buffer: sdl3.gpu.Buffer, bytes: []const u8) !void {
    const transfer_buffer = try device.createTransferBuffer(.{
        .size = @intCast(bytes.len),
        .usage = .upload,
    });
    defer device.releaseTransferBuffer(transfer_buffer);

    var buffer_map = try device.mapTransferBuffer(transfer_buffer, false);
    for (bytes, buffer_map[0..]) |v, *d| {
        d.* = v;
    }
    device.unmapTransferBuffer(transfer_buffer);

    const copy_command_buffer = try device.acquireCommandBuffer();
    const copy_pass = copy_command_buffer.beginCopyPass();
    copy_pass.uploadToBuffer(
        .{
            .transfer_buffer = transfer_buffer,
            .offset = 0,
        },
        .{
            .buffer = buffer,
            .offset = 0,
            .size = @intCast(bytes.len),
        },
        false,
    );
    copy_pass.end();
    try copy_command_buffer.submit();
}

const gpu_buffer_size = 1024;
pub fn prepareUniformsForGpu(T: type, data: T) struct {
    [gpu_buffer_size]u8,
    usize,
} {
    var buffer: [gpu_buffer_size]u8 = undefined;

    var output = std.ArrayList(u8).initBuffer(&buffer);
    prepareUniformsForGpuImpl(T, data, &output);

    return .{ buffer, output.items.len };
}

pub fn prepareSamplersForGpu(T: type, data: T) struct {
    [@typeInfo(T).@"struct".fields.len]sdl3.gpu.TextureSamplerBinding,
    usize,
} {
    const info = @typeInfo(T);
    var count: usize = 0;
    var textures: [info.@"struct".fields.len]sdl3.gpu.TextureSamplerBinding = undefined;
    inline for (info.@"struct".fields) |f| {
        switch (f.type) {
            sdl3.gpu.TextureSamplerBinding => {
                textures[count] = @field(data, f.name);
                count += 1;
            },
            else => {},
        }
    }

    return .{ textures, count };
}

fn prepareUniformsForGpuImpl(T: type, data: T, output: *std.ArrayList(u8)) void {
    const bytes = std.mem.toBytes;
    const info = @typeInfo(T);
    switch (T) {
        @Vector(1, i32), [1]i32, i32 => output.appendSliceAssumeCapacity(&bytes(data)),
        @Vector(1, u32), [1]u32, u32 => output.appendSliceAssumeCapacity(&bytes(data)),
        @Vector(1, f32), [1]f32, f32 => output.appendSliceAssumeCapacity(&bytes(data)),
        @Vector(2, i32), [2]i32 => output.appendSliceAssumeCapacity(&bytes(data)),
        @Vector(2, u32), [2]u32 => output.appendSliceAssumeCapacity(&bytes(data)),
        @Vector(2, f32), [2]f32 => output.appendSliceAssumeCapacity(&bytes(data)),
        @Vector(3, i32), [3]i32 => output.appendSliceAssumeCapacity(&bytes([4]i32{ data[0], data[1], data[2], 0 })),
        @Vector(3, u32), [3]u32 => output.appendSliceAssumeCapacity(&bytes([4]u32{ data[0], data[1], data[2], 0 })),
        @Vector(3, f32), [3]f32 => output.appendSliceAssumeCapacity(&bytes([4]f32{ data[0], data[1], data[2], 0 })),
        @Vector(4, i32), [4]i32 => output.appendSliceAssumeCapacity(&bytes(data)),
        @Vector(4, u32), [4]u32 => output.appendSliceAssumeCapacity(&bytes(data)),
        @Vector(4, f32), [4]f32 => output.appendSliceAssumeCapacity(&bytes(data)),
        zm.Mat2f => output.appendSliceAssumeCapacity(&bytes(data.transpose().data)),
        zm.Mat3f => output.appendSliceAssumeCapacity(&bytes(mat3to4x3(data.transpose()))),
        zm.Mat4f => output.appendSliceAssumeCapacity(&bytes(data.transpose().data)),
        sdl3.gpu.Texture, sdl3.gpu.Sampler => {}, // Must be handled separately
        else => switch (info) {
            .@"enum" => output.appendSliceAssumeCapacity(&bytes(
                @as(u32, @intCast(@intFromEnum(data))),
            )),
            .bool => output.appendSliceAssumeCapacity(&bytes(
                @as(u32, @intFromBool(data)),
            )),
            .@"struct" => |t| {
                inline for (t.fields) |f| {
                    prepareUniformsForGpuImpl(f.type, @field(data, f.name), output);
                }
            },

            .array => |t| {
                for (data) |el| {
                    try prepareUniformsForGpuImpl(t.child, el, output);
                }
            },
            else => {
                std.log.err("[prepareForGpu] info = {any}", info);
                @panic("Not implemented");
            },
        },
    }
}
