const std = @import("std");
const zm = @import("zm");

const Node = @This();

const types = @import("types.zig");
const Transform = @import("Transform.zig");
const Primitive = types.Primitive;
const Camera = types.Camera;
const Light = types.Light;

pub const Object = union(enum) {
    mesh: std.ArrayList(Primitive),
    light: Light,
    camera: Camera,
};

parent: ?*Node = null,
children: std.ArrayList(*Node) = .empty,
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
    const node_space_target = multiplyPoint(world_to_local, world_target);
    const rotation_matrix = zm.Mat4f.lookAt(self.transform.translation, node_space_target, up);
    self.transform.rotation = zm.Quaternionf.fromMatrix4(rotation_matrix).inverse();
}

fn multiplyPoint(m: zm.Mat4f, p: zm.Vec3f) zm.Vec3f {
    return .{
        m.data[0] * p[0] + m.data[1] * p[1] + m.data[2] * p[2] + m.data[3] * 1.0,
        m.data[4] * p[0] + m.data[5] * p[1] + m.data[6] * p[2] + m.data[7] * 1.0,
        m.data[8] * p[0] + m.data[9] * p[1] + m.data[10] * p[2] + m.data[11] * 1.0,
    };
}
