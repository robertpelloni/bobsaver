#version 420

// original https://www.shadertoy.com/view/WdcfR4

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define MAX 64
#define EPS 0.05

float distance_estimator(vec3 pos) {
    pos = mod(pos, 2.0) - 1.0;
    return length(pos) - 0.2;
}

float march(vec3 ro, vec3 rd) {
    float dist = 0.0;
    for(int i = 0;i < MAX;++i) {
        vec3 pos = ro + rd * dist;
        float d = distance_estimator(pos);
        dist += d;
        if(d < EPS) break;
    }

    return dist / float(MAX) * 3.0;
}

void main(void) {
    float ar = resolution.x / resolution.y;
    vec2 uv = gl_FragCoord.xy / resolution.y - vec2(ar * 0.5, 0.5);

    vec3 ray_origin = vec3(sin(time), cos(time / 32.0) * 15.0, sin(time) / 45.0) * 10.0;
    vec3 ray_direction = normalize(vec3(uv, 1.0));
    
    float angle = time / 5.0;
    float s = sin(angle), c = cos(angle);
    mat2 rot = mat2(c, -s, s, c);
    ray_direction.xy *= rot;
    ray_direction.yz *= rot;
    
    float i = march(ray_origin, ray_direction);
    vec3 color = vec3(i, 0.0, 0.5);

    glFragColor = vec4(color, 1.0);
}
