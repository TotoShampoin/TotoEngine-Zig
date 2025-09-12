const std = @import("std");
pub const sdl3 = @import("sdl3");
pub const zm = @import("zm");

pub const init = _context.init;
pub const deinit = _context.deinit;

pub const _context = @import("./engine/utils/_context.zig");
pub const defaults = @import("./engine/utils/defaults.zig");
pub const texture_loader = @import("./engine/utils/texture_loader.zig");
pub const modelling = @import("./engine/utils/modelling.zig");
pub const math_utils = @import("./engine/utils/math.zig");

pub const shorthands = @import("./engine/utils/shorthands.zig");
pub const uploadToBuffer = shorthands.uploadToBuffer;
pub const parseAttributes = shorthands.parseAttributes;

pub const Geometry = @import("./engine/Geometry.zig");
pub const Renderer = @import("./engine/Renderer.zig");
pub const RenderPass = @import("./engine/RenderPass.zig");
pub const Transform = @import("./engine/Transform.zig");

pub const types = @import("./engine/types.zig");
pub const Vertex = types.Vertex;
pub const Model = types.Model;
pub const Material = types.Material;

pub const Node = @import("./engine/Node.zig");
pub const Primitive = types.Primitive;
pub const Light = types.Light;
pub const Camera = types.Camera;
