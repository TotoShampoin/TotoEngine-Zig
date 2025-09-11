pub const sdl3 = @import("sdl3");
pub const zm = @import("zm");

pub const Mesh = @import("./engine/Mesh.zig");
pub const RenderPass = @import("./engine/RenderPass.zig");
pub const TextureSampler = @import("./engine/TextureSampler.zig");
pub const Transform = @import("./engine/Transform.zig");

pub const shorthands = @import("./engine/shorthands.zig");
pub const uploadToBuffer = shorthands.uploadToBuffer;
pub const parseAttributes = shorthands.parseAttributes;

pub const types = @import("./engine/types.zig");
pub const Vertex = types.Vertex;
pub const Model = types.Model;
pub const Material = types.Material;
pub const Light = types.Light;

pub const MeshObject = types.MeshObject;
pub const LightObject = types.LightObject;
pub const Camera = types.Camera;

pub const _context = @import("./engine/_context.zig");

pub const init = _context.init;
pub const deinit = _context.deinit;
