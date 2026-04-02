#version 420

// original https://www.shadertoy.com/view/3dfcDH

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float PI = 3.1415926535897932384626433832795;
vec2 cmul (vec2 a, vec2 b) {
    return vec2(a.x * b.x - a.y * b.y, a.x * b.y + b.x * a.y);
}
vec2 cexp (vec2 z) {
    return exp(z.x) * vec2(cos(z.y), sin(z.y));
}
vec2 clog (vec2 z) {
    return vec2(log(length(z)), atan(z.y, z.x));
}
vec2 cpow (vec2 z, vec2 a) {
    return cexp(cmul(a, clog(z)));
}
// Any complex-valued function. The inverse of this function is graphed.
vec2 transformation (vec2 uv) {
    vec2 ret = cpow(uv, vec2(-1.0f * cos(time / 5.0f) * 0.999f + 1.001f, 0.0f));
    return ret;
}
// Compute "Distortion" to prevent variable line width
float divergence (vec2 uv, vec2 delta) {
    return length((transformation(uv + delta) - transformation(uv)) / delta);
}
// Creates smooth lines
vec2 smoothstep2d (float lineWidth, vec2 pos) {
    vec2 ret;
    ret.x = smoothstep(-lineWidth, 0.0f, pos.x) - smoothstep(0.0f, lineWidth, pos.x);
    ret.y = smoothstep(-lineWidth, 0.0f, pos.y) - smoothstep(0.0f, lineWidth, pos.y);
    return ret;
}
vec2 mod2d (vec2 a, vec2 b) {
    return vec2(mod(a.x, b.x), mod(a.y, b.y));
}
vec3 drawGrid(vec2 uv, float lineWidth) {
    float modulator = 0.25f;
    
    // Prevent Distortion
    lineWidth *= divergence(uv, vec2(0.0005f));
    
    vec2 tv = transformation(uv) + vec2(modulator / 2.0f);
    vec2 gv = vec2(floor(tv.x / modulator), floor(tv.y / modulator));
       vec2 mv = mod(tv, vec2(modulator));
    vec2 line = smoothstep2d(lineWidth, mv - vec2(modulator / 2.0f));
    
    // Color lines
    vec3 col = vec3(0.0f, 0.15f, 0.2f) * length(line);
    if (mod(gv.x, 2.0f) == 0.0f) col = max(col, vec3(0.0f, 0.6f, 0.8f) * vec3(line.x));
    if (mod(gv.y, 2.0f) == 0.0f) col = max(col, vec3(0.0f, 0.6f, 0.8f) * vec3(line.y));
    if (gv.x == 0.0f) col = max(col, vec3(line.x));
    if (gv.y == 0.0f) col = max(col, vec3(line.y));
    
    return col;
}
void main(void) {
    float lineWidth = 0.015f;
    int sampleCount = 3;
    float sampleSize = 0.001f;
    vec2 uv = (gl_FragCoord.xy - 0.5f * resolution.xy) / (resolution.y) * vec2(5.0f, -5.0f);
    vec3 col = drawGrid(uv, lineWidth);
    glFragColor = vec4(col, 1.0);
}
