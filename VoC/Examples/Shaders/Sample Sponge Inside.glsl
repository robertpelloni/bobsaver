#version 420

// original https://www.shadertoy.com/view/wlj3D1

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define BLACK_COL vec3(23, 32, 38) / 255.0
#define WHITE_COL vec3(245, 248, 250) / 255.0

float map(vec3 p) {
    return length(mod(p, 2.0) - 1.0) - 1.3;
}

vec3 getNormal(vec3 p) {
    float t = map(p);
    vec2 d = vec2(0.001, 0.0);
    return normalize(vec3(t - map(p + d.xyy), t - map(p + d.yxy), t - map(p + d.yyx)));
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy - resolution.xy * 0.5) / resolution.y;

    vec3 camDir = normalize(vec3(uv * 1.0, (sin(time) * 0.5 + 0.5) * 0.75 + 0.25));
    vec3 camPos = vec3(1.0, (cos(time) * 3.0) - 1.57 , - time * 2.5);

    float t = -0.5;
    for(int i = 0 ; i < 100; i += 1) {
        t += map(camDir * t + camPos);
    }
    vec3 surf = camDir * t + camPos;
    vec3 light = normalize(vec3(0.0, 0.0, 1.0));
    vec3 normal = getNormal(surf);

    vec3 col = mix(BLACK_COL, WHITE_COL, dot(light, normal));
    
    glFragColor = vec4(col, 1.0);
}
