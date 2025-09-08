const std = @import("std");

const types = @import("toto-engine").types;
const Model = types.Model;
const Vertex = types.Vertex;

const lat = 32;
const lon = 24;
const flat: comptime_float = @floatFromInt(lat);
const flon: comptime_float = @floatFromInt(lon);

var vertices: [lat * lon]Vertex = undefined;
var indices: [lat * lon * 6]u32 = undefined;
var done = false;

pub fn sphere() Model {
    if (!done) {
        // Generate vertices
        for (0..lat) |i| {
            const fi: f32 = @floatFromInt(i);
            const theta = std.math.pi * fi / (flat - 1);
            const y = std.math.cos(theta);
            const r = std.math.sin(theta);
            for (0..lon) |j| {
                const fj: f32 = @floatFromInt(j);
                const phi = 2.0 * std.math.pi * fj / (flon - 1);
                const x = r * std.math.cos(phi);
                const z = r * std.math.sin(phi);

                const idx = i * lon + j;
                vertices[idx] = Vertex{
                    .position = .{ x, y, z },
                    .normal = .{ x, y, z },
                    .texcoords = .{ 1 - fj / (flon - 1), 1 - fi / (flat - 1) },
                    .color = .{ 1, 1, 1, 1 },
                };
            }
        }

        // Generate indices
        var k: usize = 0;
        for (0..lat - 1) |i| {
            for (0..lon - 1) |j| {
                const a = i * lon + j;
                const b = a + lon;
                const c = b + 1;
                const d = a + 1;

                indices[k] = @intCast(a);
                indices[k + 1] = @intCast(d);
                indices[k + 2] = @intCast(b);
                indices[k + 3] = @intCast(d);
                indices[k + 4] = @intCast(c);
                indices[k + 5] = @intCast(b);
                k += 6;
            }
        }
    }

    return .{
        .vertices = &vertices,
        .indices = &indices,
    };
}
