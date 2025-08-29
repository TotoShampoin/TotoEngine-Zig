const sdl3 = @import("sdl3");
const zm = @import("zm");

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
