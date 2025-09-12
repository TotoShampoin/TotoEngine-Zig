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

layout (location = 0) in vec2 v_uv;
layout (location = 1) in vec4 v_color;
layout (location = 2) in vec3 v_worldpos;
layout (location = 3) in mat3 v_tbn;

layout (location = 0) out vec4 FragColor;

layout(std140, set = 3, binding = 0) uniform CameraBlock {
    vec3 u_camera_worldpos;
};

layout(std140, set = 3, binding = 1) uniform LightBlock {
    Light u_lights[8];
    mat4 u_lights_matrix[8];
    int u_light_count;
};

layout(std140, set = 3, binding = 2) uniform MaterialBlock {
    vec4 u_color;
    vec4 u_specular;
    float u_shininess;
    float u_normal_strength;
};
layout(set = 2, binding = 0) uniform sampler2D u_tex;
layout(set = 2, binding = 1) uniform sampler2D u_emi;
layout(set = 2, binding = 2) uniform sampler2D u_normal;

void main()
{
    vec3 normalMap = texture(u_normal, v_uv).xyz * 2.0 - 1.0;
    normalMap = mix(vec3(0.0, 0.0, 1.0), normalMap, u_normal_strength);
    vec3 norm = normalize(v_tbn * normalMap);

    vec3 viewPos = u_camera_worldpos;
    vec3 fragPos = v_worldpos;
    vec3 viewDir = normalize(viewPos - fragPos);
    
    vec4 texColor = texture(u_tex, v_uv);

    vec3 diffuse = vec3(0);
    vec3 specular = vec3(0);
    vec3 emissive = vec3(0);

    for (int i = 0; i < u_light_count; ++i) {
        Light light = u_lights[i];
        vec3 lightColor = light.color.rgb * light.intensity;

        vec3 lightDir;
        float attenuation = 1.0;

        if (light.type == LIGHT_POINT) {
            vec3 lightPos = u_lights_matrix[i][3].xyz;
            lightDir = normalize(lightPos - fragPos);
            float dist = length(lightPos - fragPos);
            attenuation = 1.0 / (1.0 + dist * dist / (light.range * light.range));
        } else if (light.type == LIGHT_DIR) {
            lightDir = normalize(u_lights_matrix[i][2].xyz);
            attenuation = 1.0;
        } else if (light.type == LIGHT_SPOT) {
            vec3 lightPos = u_lights_matrix[i][3].xyz;
            lightDir = normalize(lightPos - fragPos);
            float dist = length(lightPos - fragPos);
            attenuation = 1.0 / (1.0 + dist * dist / (light.range * light.range));
            // Spot cone
            vec3 spotDir = normalize(u_lights_matrix[i][2].xyz);
            float spotEffect = dot(lightDir, -spotDir);
            float cutoff = 0.9; // adjust as needed
            attenuation *= clamp((spotEffect - cutoff) / (1.0 - cutoff), 0.0, 1.0);
        }

        // Diffuse
        float diff = max(dot(norm, lightDir), 0.0);
        diffuse += diff * lightColor * attenuation;

        // Specular (Blinn-Phong)
        vec3 halfDir = normalize(lightDir + viewDir);
        float spec = pow(max(dot(norm, halfDir), 0.0), u_shininess);
        specular += spec * lightColor * attenuation;
    }

    // Emissive
    emissive = texture(u_emi, v_uv).rgb;

    vec3 finalColor = vec3(0);
    finalColor += texColor.rgb * u_color.rgb * diffuse;
    finalColor += specular * u_specular.rgb;
    finalColor += emissive;
    FragColor = vec4(finalColor, texColor.a * u_color.a);
}
