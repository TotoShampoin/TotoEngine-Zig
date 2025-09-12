pub const zm = @import("zm");
pub const types = @import("../types.zig");

pub fn calculateNormals(vertices: []types.Vertex, indices: []u32) void {
    // Zero out all normals
    for (vertices) |*v| {
        v.normal = zm.Vec3{ 0, 0, 0 };
    }

    // Calculate face normals and accumulate
    var i: usize = 0;
    while (i + 2 < indices.len) : (i += 3) {
        const _i0 = indices[i];
        const _i1 = indices[i + 1];
        const _i2 = indices[i + 2];

        const v0 = vertices[_i0].position;
        const v1 = vertices[_i1].position;
        const v2 = vertices[_i2].position;

        const edge1 = zm.sub(v1, v0);
        const edge2 = zm.sub(v2, v0);
        const normal = zm.normalize(zm.cross(edge1, edge2));

        vertices[_i0].normal = zm.add(vertices[_i0].normal, normal);
        vertices[_i1].normal = zm.add(vertices[_i1].normal, normal);
        vertices[_i2].normal = zm.add(vertices[_i2].normal, normal);
    }

    // Normalize all normals
    for (vertices) |*v| {
        v.normal = zm.vec.normalize(v.normal);
    }
}

pub fn calculateTangents(vertices: []types.Vertex, indices: []u32) void {
    // Zero out all tangents
    for (vertices) |*v| {
        v.tangent = zm.Vec4{ 0, 0, 0, 0 };
    }

    var i: usize = 0;
    while (i + 2 < indices.len) : (i += 3) {
        const _i0 = indices[i];
        const _i1 = indices[i + 1];
        const _i2 = indices[i + 2];

        const v0 = vertices[_i0];
        const v1 = vertices[_i1];
        const v2 = vertices[_i2];

        const p0 = v0.position;
        const p1 = v1.position;
        const p2 = v2.position;

        const uv0 = v0.texcoord;
        const uv1 = v1.texcoord;
        const uv2 = v2.texcoord;

        const edge1 = p1 - p0;
        const edge2 = p2 - p0;

        const deltaUV1 = uv1 - uv0;
        const deltaUV2 = uv2 - uv0;

        const r = 1.0 / (deltaUV1[0] * deltaUV2[1] - deltaUV2[0] * deltaUV1[1]);

        const tangent = zm.vec.scale(zm.vec.scale(edge1, deltaUV2[1]) - zm.vec.scale(edge2, deltaUV1[1]), r);
        // const tangent = zm.vec.scale(zm.vec.scale(edge2, deltaUV2[1]) - zm.vec.scale(edge1, deltaUV1[1]), r);

        vertices[_i0].tangent = zm.Vec4f{ tangent[0], tangent[1], tangent[2], 0 } + vertices[_i0].tangent;
        vertices[_i1].tangent = zm.Vec4f{ tangent[0], tangent[1], tangent[2], 0 } + vertices[_i1].tangent;
        vertices[_i2].tangent = zm.Vec4f{ tangent[0], tangent[1], tangent[2], 0 } + vertices[_i2].tangent;
    }

    // Normalize tangents and compute handedness (w)
    for (vertices) |*v| {
        const n = v.normal;
        var t = zm.Vec3f{ v.tangent[0], v.tangent[1], v.tangent[2] };
        t = zm.vec.normalize(t);

        // Gram-Schmidt orthogonalize
        t = zm.vec.normalize(t - zm.vec.scale(n, zm.vec.dot(n, t)));

        // Calculate handedness
        const bitangent = zm.vec.cross(n, t);
        const w: f32 = if (zm.vec.dot(bitangent, zm.Vec3f{ v.tangent[0], v.tangent[1], v.tangent[2] }) < 0.0) -1.0 else 1.0;

        v.tangent = zm.Vec4f{ t[0], t[1], t[2], w };
    }
}
