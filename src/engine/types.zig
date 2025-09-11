const sdl3 = @import("sdl3");
const zm = @import("zm");

const Mesh = @import("Mesh.zig");
const Transform = @import("Transform.zig");
const TextureSampler = @import("TextureSampler.zig");

pub const Vertex = struct {
    position: zm.Vec3f = .{ 0, 0, 0 },
    normal: zm.Vec3f = .{ 0, 0, 0 },
    texcoords: zm.Vec2f = .{ 0, 0 },
    color: zm.Vec4f = .{ 0, 0, 0, 0 },
};

pub const Model = struct {
    vertices: []const Vertex,
    indices: []const u32,
};

pub const Material = struct {
    color: zm.Vec4f,
    texture: TextureSampler,
};

pub const Light = struct {
    color: zm.Vec4f = .{ 1, 1, 1, 1 },
    intensity: f32 = 1,
    type: LightType = .directional,
    range: f32 = 1,
};
pub const LightType = enum { point, spot, directional };

pub const MeshObject = struct {
    mesh: Mesh,
    material: Material,
    transform: Transform = .{},
};
pub const LightObject = struct {
    light: Light,
    transform: Transform = .{},
};
pub const Camera = struct {
    projection: zm.Mat4f,
    transform: Transform = .{},
};
