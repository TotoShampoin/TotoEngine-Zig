#version 460

layout(location = 0) in vec3 a_position;
layout(location = 1) in vec3 a_normal;
layout(location = 2) in vec2 a_texcoords;
layout(location = 3) in vec4 a_color;

layout(location = 0) out vec4 v_color;

void main()
{
	gl_Position = vec4(a_position, 1.0);
	v_color = a_color;
}
