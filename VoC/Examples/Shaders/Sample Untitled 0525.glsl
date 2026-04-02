#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14159265358979323846

float radian(float degrees) { return degrees * PI / 180.0; }

// [-1, 1] => [0, 1]
float one(float a) { return a * 0.5 + 0.5; }

// wave
float sin1(float a) { return one(sin(a)); }

// 0 ~ 1
float triWave(float t) { return abs(fract(t) - 0.5) * 2.; }

float sigmoid(float t, float a) {
    float s = (t - a * t) / (a - 2. * a * abs(t) + 1.);
    return s;
}

vec3 saturate_(vec3 x) { return clamp(x, 0., 1.); }

// random
float rand(vec2 s){
    return fract(sin(dot(s.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

// Interpolation
float eiq(float t) { return t * t; }

float eic(float t) { return t * t * t; }

float eie(float t) { return (t == 0.) ? 0. : pow(2., 10. * (t - 1.)); }

// Shape
float plot(vec2 uv, vec2 point, float r){
    float d = distance(uv, point);
    return smoothstep(r, 0., d);
}

// Color
vec3 hue(float h) {
    return saturate_(abs(fract(h + vec3(0.,2.,1.)/3.) * 6. - 3.) - 1.);
}

// Transform
float scale(float s) { return 1. / s; }

mat2 rot(float a) {
    float c = cos(a), s = sin(a);
    return mat2(c, -s, s, c);
}

vec2 rotate(vec2 p, float a) { return rot(a) * p; }

// bloom
vec3 bloom(float d, vec3 color, float l) {  // 距離、色、強さ
    return saturate_(color * (1. - eiq(d)) * l);
}

vec3 sigmoidLaser(vec2 uv) {
    vec3 c = vec3(0);
    for(float a = -0.9; a <= 0.9; a+=0.2) {
        float sig = plot(uv, vec2(uv.x, sigmoid(uv.x, a)), 0.04);
        sig *= sin( (uv.x * 10. + time * 10. + rand(vec2(a, a)) * 97.) * .1);
        vec3 color = hue(a * 0.1 * triWave(time) + time * 0.1);
        c += bloom(1. - sig, color, 2.3);
    }
    return c;
}

void main() {
    vec2 uv = (gl_FragCoord.xy / resolution - .5) * vec2(resolution.x / resolution.y, 1.);
    uv = rotate(uv, time * 0.1);
    vec3 c = vec3(0.);
    for(int i=0; i< 10; i++) {
        vec2 st = uv * (0.1 + 10. * sin1(time * 0.2));
        st = rotate(st, rand(vec2(i, i)) * PI * sin1(time * 0.2));
        c += sigmoidLaser(st);
    }
    vec3 bloomColor = hue(0.1 * triWave(time) + time * 0.1);
    c += 0.3 * bloom(length(uv * scale(0.5)), bloomColor, 1. + sin1(time * 4.));

    glFragColor = vec4(c, 1.);
}
