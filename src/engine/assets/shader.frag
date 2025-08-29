#version 460

layout (location = 0) in vec3 v_normal;
layout (location = 1) in vec2 v_uv;
layout (location = 2) in vec4 v_color;

layout (location = 0) out vec4 FragColor;

layout(std140, set = 3, binding = 0) uniform MaterialBlock {
    vec4 u_color;
};
// layout(set = 2, binding = 0) uniform sampler2D u_tex;

void main()
{
    // FragColor = u_color * v_color * texture(u_tex, v_uv);
    // FragColor = u_color * v_color;
    // FragColor = v_color;
    // FragColor = vec4(v_uv, 0, 1);
    FragColor = vec4(normalize(v_normal), 1);
}
