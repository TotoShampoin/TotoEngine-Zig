const zm = @import("zm");
const Transform = @import("Transform.zig");

const Camera = @This();

transform: Transform = .{},
projection: zm.Mat4f,

pub const PerspectiveData = struct {
    fov: f32,
    aspect: f32,
    near: f32,
    far: f32,
};
pub const OrthographicData = struct {
    left: f32,
    right: f32,
    bottom: f32,
    top: f32,
    near: f32,
    far: f32,
};

pub fn createPerspective(data: PerspectiveData) Camera {
    return .{ .projection = zm.Mat4f.perspective(
        data.fov,
        data.aspect,
        data.near,
        data.far,
    ) };
}
pub fn createOrthographic(data: OrthographicData) Camera {
    return .{ .projection = zm.Mat4f.orthographic(
        data.left,
        data.right,
        data.bottom,
        data.top,
        data.near,
        data.far,
    ) };
}

pub fn setPerspective(self: *Camera, data: PerspectiveData) void {
    self.projection = zm.Mat4f.perspective(
        data.fov,
        data.aspect,
        data.near,
        data.far,
    );
}
pub fn setOrthographic(self: *Camera, data: OrthographicData) void {
    self.projection = zm.Mat4f.orthographic(
        data.left,
        data.right,
        data.bottom,
        data.top,
        data.near,
        data.far,
    );
}
