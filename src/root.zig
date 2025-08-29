pub const sdl3 = @import("sdl3");
pub const zm = @import("zm");

pub const Mesh = @import("./engine/Mesh.zig");
pub const RenderPass = @import("./engine/RenderPass.zig");
pub const Transform = @import("./engine/Transform.zig");
pub const Camera = @import("./engine/Camera.zig");

pub const shorthands = @import("./engine/shorthands.zig");
pub const uploadToBuffer = shorthands.uploadToBuffer;
pub const parseAttributes = shorthands.parseAttributes;

pub const types = @import("./engine/types.zig");
pub const Vertex = types.Vertex;
