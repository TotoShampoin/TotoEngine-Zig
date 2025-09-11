const std = @import("std");
const zm = @import("zm");

const Node = @This();

const types = @import("types.zig");
const Transform = @import("Transform.zig");
const Primitive = types.Primitive;
const Camera = types.Camera;
const Light = types.Light;

pub const Object = union(enum) {
    mesh: std.ArrayList(*Primitive),
    light: Light,
    camera: Camera,
};

parent: ?*Node = null,
children: std.ArrayList(*Node) = .empty,
transform: Transform = .{},
object: ?Object = null,

pub fn worldMatrix(self: *Node) zm.Mat4f {
    if (self.parent) |p| {
        return p.worldMatrix().multiply(self.transform.matrix());
    } else {
        return self.transform.matrix();
    }
}
