const zm = @import("zm");

pub const Vertex = struct {
    position: zm.Vec3f = .{ 0, 0, 0 },
    normal: zm.Vec3f = .{ 0, 0, 0 },
    texcoords: zm.Vec2f = .{ 0, 0 },
    color: zm.Vec4f = .{ 0, 0, 0, 0 },
};
