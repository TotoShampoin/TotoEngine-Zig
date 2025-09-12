const zm = @import("zm");

pub fn multiplyPoint(m: zm.Mat4f, p: zm.Vec3f) zm.Vec3f {
    return .{
        m.data[0] * p[0] + m.data[1] * p[1] + m.data[2] * p[2] + m.data[3] * 1.0,
        m.data[4] * p[0] + m.data[5] * p[1] + m.data[6] * p[2] + m.data[7] * 1.0,
        m.data[8] * p[0] + m.data[9] * p[1] + m.data[10] * p[2] + m.data[11] * 1.0,
    };
}

pub fn getColumn(m: zm.Mat4f, i: usize) zm.Vec4f {
    return .{
        m.data[0 + i],
        m.data[4 + i],
        m.data[8 + i],
        m.data[12 + i],
    };
}

pub fn mat4toMat3(m: zm.Mat4f) zm.Mat3f {
    return zm.Mat3f{
        .data = .{
            m.data[0], m.data[1], m.data[2],
            m.data[4], m.data[5], m.data[6],
            m.data[8], m.data[9], m.data[10],
        },
    };
}

pub fn mat3toMat4(m: zm.Mat3f) zm.Mat4f {
    return zm.Mat4f{
        .data = .{
            m.data[0], m.data[1], m.data[2], 0.0,
            m.data[3], m.data[4], m.data[5], 0.0,
            m.data[6], m.data[7], m.data[8], 0.0,
            0.0,       0.0,       0.0,       1.0,
        },
    };
}
pub fn mat3to4x3(m: zm.Mat3f) [12]f32 {
    return .{
        m.data[0], m.data[1], m.data[2], 0.0,
        m.data[3], m.data[4], m.data[5], 0.0,
        m.data[6], m.data[7], m.data[8], 0.0,
    };
}
pub fn mat2ToVecs(m: zm.Mat2f) [2]zm.Vec2f {
    return .{
        .{ m.data[0], m.data[2] },
        .{ m.data[1], m.data[3] },
    };
}
pub fn mat3ToVecs(m: zm.Mat3f) [3]zm.Vec3f {
    return .{
        .{ m.data[0], m.data[3], m.data[6] },
        .{ m.data[1], m.data[4], m.data[7] },
        .{ m.data[2], m.data[5], m.data[8] },
    };
}
pub fn mat4ToVecs(m: zm.Mat4f) [4]zm.Vec4f {
    return .{
        .{ m.data[0], m.data[4], m.data[8], m.data[12] },
        .{ m.data[1], m.data[5], m.data[9], m.data[13] },
        .{ m.data[2], m.data[6], m.data[10], m.data[14] },
        .{ m.data[3], m.data[7], m.data[11], m.data[15] },
    };
}
