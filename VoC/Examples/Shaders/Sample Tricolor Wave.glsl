#version 420

// original https://neort.io/art/bvsuo6s3p9f30ks57bvg

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;
uniform sampler2D backbuffer;

out vec4 glFragColor;

float random(vec3 v) { 
    return fract(sin(dot(v, vec3(12.9898, 78.233, 19.8321))) * 43758.5453);
}

float random(vec2 v) { 
    return fract(sin(dot(v, vec2(12.9898, 78.233))) * 43758.5453);
}

float random(float v) {
    return fract(sin(v * 12.9898) * 43758.5453);
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

float valueNoise(vec2 v) {
    vec2 i = floor(v);
    vec2 f = smoothstep(0.0, 1.0, fract(v));
    return mix(
        mix(random(i), random(i + vec2(1.0, 0.0)), f.x),
        mix(random(i + vec2(0.0, 1.0)), random(i + vec2(1.0, 1.0)), f.x),
        f.y
    );
}

float valueNoise(float v) {
    float i = floor(v);
    float f = smoothstep(0.0, 1.0, fract(v));
    return mix(random(i), random(i + 1.0), f);
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

float fbm(vec2 x) {
    float n = 0.0;
    float a = 0.5;
    for (int i = 0; i < 5; i++) {
        n += a * valueNoise(x);
        x *= 2.0;
        a *= 0.5;
    }
    return n;
}

float fbm(float v) {
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
    vec3 subColor1 = vec3(step(fract(uv.y*5.0-time*4.0), 0.3));
    vec3 subColor2 = vec3(step(fract(uv.y*5.0-time*3.5), 0.4));
    vec3 subColor3 = vec3(step(fract(uv.y*5.0-time*3.0), 0.5));
    float uvYR = uv.x + sin(uv.y * 20.0 + time + 4.0) * 0.5 * fbm(vec3(uv, time));
    float uvYG = uv.x + sin(uv.y * 20.1 + time + 6.0) * 0.75 * fbm(vec3(uv,time));
    float uvYB = uv.x + sin(uv.y * 20.2 + time + 8.0) * 1.0 * fbm(vec3(uv, time));
    vec3 mainColor1 = step(abs(uvYR), 0.1) * vec3(0.9255, 0.1255, 0.1255);
    vec3 mainColor2 = step(abs(uvYG), 0.1) * vec3(1.0, 1.0, 1.0);
    vec3 mainColor3 = step(abs(uvYB), 0.1) * vec3(0.1529, 0.1255, 0.9255);
    vec3 color = vec3(0.0);
    color += min(mainColor1, subColor1);
    color += min(mainColor2, subColor2);
    color += min(mainColor3, subColor3);
    glFragColor = vec4(color, 1.0);
}

