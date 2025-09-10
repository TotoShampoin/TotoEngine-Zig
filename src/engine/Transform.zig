const std = @import("std");
const zm = @import("zm");

const Transform = @This();

translation: zm.Vec3f = .{ 0, 0, 0 },
rotation: zm.Quaternionf = .identity(),
scaling: zm.Vec3f = .{ 1, 1, 1 },

parent: ?*Transform = null,
children: std.ArrayList(*Transform) = .empty,

pub fn matrix(self: Transform) zm.Mat4f {
    return zm.Mat4f.translationVec3(self.translation)
        .multiply(zm.Mat4f.fromQuaternion(self.rotation))
        .multiply(zm.Mat4f.scaling(self.scaling[0], self.scaling[1], self.scaling[2]));
}
pub fn worldMatrix(self: Transform) zm.Mat4f {
    if (self.parent) |p| {
        return p.worldMatrix().multiply(self.matrix());
    } else {
        return self.matrix();
    }
}

pub fn lookAt(self: *Transform, target: zm.Vec3f, up: zm.Vec3f) void {
    self.rotation = zm.Quaternionf
        .fromMatrix4(zm.Mat4f.lookAt(self.translation, target, up))
        .inverse();
}
