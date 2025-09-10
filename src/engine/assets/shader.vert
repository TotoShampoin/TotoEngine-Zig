#version 460

layout (location = 0) in vec3 a_position;
layout (location = 1) in vec3 a_normal;
layout (location = 2) in vec2 a_texcoord;
layout (location = 3) in vec4 a_color;

layout (location = 0) out vec3 v_normal;
layout (location = 1) out vec2 v_uv;
layout (location = 2) out vec4 v_color;
layout (location = 3) out vec3 v_worldpos;

layout(std140, set = 1, binding = 0) uniform TransformBlock {
    mat4 u_model;
    mat4 u_view;
    mat4 u_projection;
    mat4 u_mv;
    mat4 u_mvp;
    mat3 u_normal_matrix;
};

void main()
{
    vec4 worldpos = u_model * vec4(a_position, 1.0f);
    gl_Position = u_mvp * vec4(a_position, 1.0f);
    v_uv = a_texcoord;
    v_normal = normalize(mat3(u_normal_matrix) * a_normal);
    v_color = a_color;
    v_worldpos = worldpos.xyz;
}
