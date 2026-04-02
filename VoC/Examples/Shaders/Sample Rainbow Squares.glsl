#version 420

// original https://www.shadertoy.com/view/tlySDm

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.1415926

vec3 xs[6];

mat2 rotm(float angle) {
    return mat2(cos(angle), sin(angle), -sin(angle), cos(angle));
}

vec3 color(float loc) {
    vec3 result = vec3(0.0);
    for (int i = 0; i < 6; ++i) {
        float fi = float(i);
        float inSection = step(fi, loc) - step(fi + 1.0, loc);
        vec3 inverted = 1.0 - xs[i];
        
        vec3 stepColor = mix(xs[i], sqrt(inverted), mod(time * 1.0 + fi / 6.0, 1.0) * inSection);
        result += stepColor * (step(fi - 0.1, loc) - step(fi + 0.1, loc));
    }

    return result;
}

vec2 rot(vec2 uv, float angle) {
    return rotm(angle) * (uv - 0.5) + 0.5;
}

vec3 pattern(vec2 uv) {
    vec2 sv = vec2(uv.x, 1.0 - uv.y) * 6.0;
    
    float mi = min(sv.x, sv.y);
    float moat = 0.0;
    for (int i = 0; i < 6; ++i) {
        float fi = float(i);
        moat += smoothstep(fi - 0.04, fi + 0.04, mi) - smoothstep(fi + 0.06, fi + 0.14, mi);
    }
    moat = clamp(moat, 0.0, 1.0);
    
    vec2 iv = floor(sv);
    vec2 fv = fract(sv);
    return color(min(iv.x, iv.y)) * (1.0 - moat);
}

void main(void) {
    xs[0] = vec3(0.92, 0.0, 0.0);
    xs[1] = vec3(1.0, 0.5, 0.0);
    xs[2] = vec3(1.0, 0.9, 0.0);
    xs[3] = vec3(0.0, 0.5, 0.1);
    xs[4] = vec3(0.25, 0.4, 0.95);
    xs[5] = vec3(0.5, 0.0, 0.5);
    
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    uv.x *= resolution.x / resolution.y;
    
    vec2 mv = mouse*resolution.xy.xy / resolution.xy;
    vec2 cv = mv - 0.5;
    
    float compensation = -atan(-0.5, -0.5 * resolution.x / resolution.y) - PI / 4.0;

    float angle = -atan(cv.y, cv.x * resolution.x / resolution.y) - compensation;
    float d = length(cv);
    
    vec2 sv = rot(uv, angle);
    float scale = 2.0 + 8.0 * d;
    sv *= scale;
    
    vec2 iv = floor(sv);
    vec2 fv = fract(sv);

    glFragColor = vec4(pattern(fv), 1.0);
}
