const sdl3 = @import("sdl3");
const zm = @import("zm");

const Geometry = @import("Geometry.zig");
const Transform = @import("Transform.zig");

pub const Vertex = struct {
    position: zm.Vec3f = .{ 0, 0, 0 },
    normal: zm.Vec3f = .{ 0, 0, 0 },
    tangent: zm.Vec4f = .{ 0, 0, 0, 1 },
    texcoord: zm.Vec2f = .{ 0, 0 },
    color: zm.Vec4f = .{ 0, 0, 0, 0 },
};

pub const Model = struct {
    vertices: []const Vertex,
    indices: []const u32,
};

pub const Material = struct {
    color: zm.Vec4f,
    specular: zm.Vec4f,
    shininess: f32,
    normal_strength: f32,
    albedo: sdl3.gpu.TextureSamplerBinding,
    emissive: sdl3.gpu.TextureSamplerBinding,
    normal: sdl3.gpu.TextureSamplerBinding,
};

pub const Light = struct {
    color: zm.Vec4f = .{ 1, 1, 1, 1 },
    intensity: f32 = 1,
    type: LightType = .directional,
    range: f32 = 1,
};
pub const LightType = enum { point, spot, directional };

pub const Primitive = struct {
    geometry: *const Geometry,
    material: *const Material,
};
pub const Camera = struct {
    projection: zm.Mat4f,
};
