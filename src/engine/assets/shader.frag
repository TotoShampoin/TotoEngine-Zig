#version 460

struct Light {
    vec4 color;
    float intensity;
    int type;
    float range;
};
#define LIGHT_POINT 0
#define LIGHT_SPOT 1
#define LIGHT_DIR 2

layout (location = 0) in vec3 v_normal;
layout (location = 1) in vec2 v_uv;
layout (location = 2) in vec4 v_color;

layout (location = 0) out vec4 FragColor;

layout(std140, set = 3, binding = 0) uniform MaterialBlock {
    vec4 u_color;
};
layout(set = 2, binding = 0) uniform sampler2D u_tex;

layout(std140, set = 3, binding = 1) uniform LightBlock {
    Light u_lights[8];
    mat4 u_lights_view_matrix[8];
    int u_light_count;
};

void main()
{
    FragColor = u_color * v_color * texture(u_tex, v_uv);
    // FragColor = u_color * v_color;
    // FragColor = v_color;
    // FragColor = vec4(v_uv, 0, 1);
    // FragColor = vec4(normalize(v_normal), 1);

    vec3 norm = normalize(v_normal);
    vec3 viewPos = vec3(0.0, 0.0, 0.0); // Assuming camera at origin
    vec3 fragPos = vec3(0.0); // If you have fragment position, use it here

    vec3 result = vec3(0.0);

    for (int i = 0; i < u_light_count; ++i) {
        Light light = u_lights[i];
        mat4 light_view_matrix = u_lights_view_matrix[i];
        vec3 lightDir;
        float attenuation = 1.0;

        if (light.type == LIGHT_POINT) {
            vec3 lightPos = vec3(light_view_matrix[3]);
            lightDir = normalize(lightPos - fragPos);
            float dist = length(lightPos - fragPos);
            attenuation = 1.0 / (1.0 + dist / light.range);
        } else if (light.type == LIGHT_DIR) {
            lightDir = normalize(vec3(light_view_matrix[2]));
        } else {
            continue; // skip unsupported types
        }

        // Ambient
        vec3 ambient = 0.1 * light.color.rgb * light.intensity;

        // Diffuse
        float diff = max(dot(norm, lightDir), 0.0);
        vec3 diffuse = diff * light.color.rgb * light.intensity;

        // Specular
        vec3 viewDir = normalize(viewPos - fragPos);
        vec3 reflectDir = reflect(-lightDir, norm);
        float spec = pow(max(dot(viewDir, reflectDir), 0.0), 32.0);
        vec3 specular = spec * light.color.rgb * light.intensity * 0.5;

        result += attenuation * (ambient + diffuse + specular);
    }

    FragColor.rgb *= result;
}
