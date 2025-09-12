#version 460

layout (location = 0) in vec3 a_position;
layout (location = 1) in vec3 a_normal;
layout (location = 2) in vec4 a_tangent;
layout (location = 3) in vec2 a_texcoord;
layout (location = 4) in vec4 a_color;

layout (location = 0) out vec2 v_uv;
layout (location = 1) out vec4 v_color;
layout (location = 2) out vec3 v_worldpos;
layout (location = 3) out mat3 v_tbn;

layout(std140, set = 1, binding = 0) uniform CameraBlock {
    mat4 u_view;
    mat4 u_projection;
    mat4 u_vp;
};

layout(std140, set = 1, binding = 1) uniform TransformBlock {
    mat4 u_model;
    mat3 u_normal_matrix;
};

void main()
{
    vec4 worldpos = u_model * vec4(a_position, 1.0f);
    gl_Position = u_vp * worldpos;
    v_uv = a_texcoord;
    v_color = a_color;
    v_worldpos = worldpos.xyz;
    vec3 normal = normalize(u_normal_matrix * a_normal);
    vec3 tangent = normalize(u_normal_matrix * a_tangent.xyz) * a_tangent.w;
    vec3 bitangent = cross(normal, tangent);
    v_tbn = mat3(tangent, bitangent, normal);
}
