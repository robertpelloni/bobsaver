#version 420

// original https://neort.io/art/bvsttsc3p9f30ks57a90

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;
uniform sampler2D backbuffer;

out vec4 glFragColor;

float random(vec3 v) { 
    return fract(sin(dot(v, vec3(12.9898, 78.233, 19.8321))) * 43758.5453);
}

float valueNoise(vec3 v) {
    vec3 i = floor(v);
    vec3 f = smoothstep(0.0, 1.0, fract(v));
    return  mix(
        mix(
            mix(random(i), random(i + vec3(1.0, 0.0, 0.0)), f.x),
            mix(random(i + vec3(0.0, 1.0, 0.0)), random(i + vec3(1.0, 1.0, 0.0)), f.x),
            f.y
        ),
        mix(
            mix(random(i + vec3(0.0, 0.0, 1.0)), random(i + vec3(1.0, 0.0, 1.0)), f.x),
            mix(random(i + vec3(0.0, 1.0, 1.0)), random(i + vec3(1.0, 1.0, 1.0)), f.x),
            f.y
        ),
        f.z
    );
}

float fbm(vec3 v) {
    float n = 0.0;
    float a = 0.5;
    for (int i = 0; i < 5; i++) {
        n += a * valueNoise(v);
        v *= 2.0;
        a *= 0.5;
    }
    return n;
}

void main(){
    vec2 uv = (gl_FragCoord.xy * 2.0 - resolution)/min(resolution.x, resolution.y);
    vec3 color = vec3(0.0);
    float uvYR = uv.y + sin(uv.x * 10.0 * fbm(vec3(uv*3.0, time+1.0)) + time*4.0) * 0.8  * fbm(vec3(uv, time+1.0));
    float uvYG = uv.y + sin(uv.x * 9.0 * fbm(vec3(uv*4.0, time)) + time*4.0) * 0.81 * fbm(vec3(uv, time));
    float uvYB = uv.y + sin(uv.x * 11.0 * fbm(vec3(uv*3.5, time-1.0)) + time*4.0) * 0.79 * fbm(vec3(uv, time-1.0));
    color += (1.0 - smoothstep(abs(uvYR), 0.0, 0.05)) * vec3(0.1255, 0.9255, 0.1412);
    color += (1.0 - smoothstep(abs(uvYG), 0.0, 0.05)) * vec3(0.1529, 0.1255, 0.9255);
    color += (1.0 - smoothstep(abs(uvYB), 0.0, 0.05)) * vec3(0.9255, 0.1255, 0.1255);
    glFragColor = vec4(vec3(color), 1.0);
}
