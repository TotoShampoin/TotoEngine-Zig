const std = @import("std");
const zm = @import("zm");

const Node = @This();

const math_utils = @import("math_utils.zig");
const types = @import("types.zig");
const Transform = @import("Transform.zig");
const Primitive = types.Primitive;
const Camera = types.Camera;
const Light = types.Light;

pub const Object = union(enum) {
    mesh: []const Primitive,
    light: *const Light,
    camera: *const Camera,
};

parent: ?*Node = null,
children: []const *const Node = &.{},
transform: Transform = .{},
object: ?Object = null,

pub fn worldMatrix(self: Node) zm.Mat4f {
    if (self.parent) |p| {
        return p.worldMatrix().multiply(self.transform.matrix());
    } else {
        return self.transform.matrix();
    }
}

pub fn lookAtWorld(self: *Node, world_target: zm.Vec3f, up: zm.Vec3f) void {
    const world_to_local = self.worldMatrix().inverse();
    const node_space_target = math_utils.multiplyPoint(world_to_local, world_target);
    const rotation_matrix = zm.Mat4f.lookAt(self.transform.translation, node_space_target, up);
    self.transform.rotation = zm.Quaternionf.fromMatrix4(rotation_matrix).inverse();
}
