const sdl3 = @import("sdl3");
const zm = @import("zm");

pub const Vertex = struct {
    position: zm.Vec3f = .{ 0, 0, 0 },
    normal: zm.Vec3f = .{ 0, 0, 0 },
    texcoords: zm.Vec2f = .{ 0, 0 },
    color: zm.Vec4f = .{ 0, 0, 0, 0 },
    tangent: zm.Vec3f = .{ 0, 0, 0 },
};

pub const Material = struct {
    color: zm.Vec4f,
    // texture: sdl3.gpu.TextureSamplerBinding,
};
