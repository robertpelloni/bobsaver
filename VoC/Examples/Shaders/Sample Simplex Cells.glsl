#version 420

// original https://www.shadertoy.com/view/ldBXDG

uniform float time;
uniform vec2 resolution;

out vec4 glFragColor;

vec2 rotate_2d(vec2 c, float a) {
    float ca = cos(a);
    float sa = sin(a);
    return vec2(c.x * ca - c.y * sa, c.y * ca + c.x * sa);
}
vec3 hsv_rgb(vec3 hsv) {
    return mix(vec3(1., 1., 1.), clamp(abs(mod(hsv.x / 60. + vec3(0., 4., 2.), 6.) - 3.) - 1., 0., 1.), hsv.y) * hsv.z;
}
vec3 permute(vec3 x) {
    return mod((x * 34. + 1.) * x, 289.);
}
float snoise_2d(vec2 v) {
    vec4 C = vec4(.211324865405187, .366025403784439, -.577350269189626, .024390243902439);
    vec2 i = floor(dot(v, C.yy) + v);
    vec2 x0 = v - i + dot(i, C.xx);
    vec2 i1 = x0.x > x0.y ? vec2(1., 0.) : vec2(0., 1.);
    vec4 x12 = x0.xyxy + C.xxzz - vec4(i1, 0., 0.);
    i = mod(i, 289.);
    vec3 p = permute(permute(vec3(0., i1.y, 1.) + i.y) + i.x + vec3(0., i1.x, 1.));
    vec3 m = max(.5 - vec3(dot(x0, x0), dot(x12.xy, x12.xy), dot(x12.zw, x12.zw)), 0.);
    m = m * m * m * m;
    vec3 x = 2. * fract(p * C.www) - 1.;
    vec3 h = abs(x) - .5;
    vec3 ox = floor(x + .5);
    vec3 a0 = x - ox;
    m = (1.79284291400159 - .85373472095314 * (a0 * a0 + h * h)) * m;
    return dot(m, vec3(a0.x * x0.x + h.x * x0.y, a0.yz * x12.xz + h.yz * x12.yw)) * 130.;
}
void main() {
    vec2 p = (gl_FragCoord.xy / resolution.xy * 2. - 1.) * vec2(resolution.x / resolution.y, 1.);
    float v = snoise_2d(rotate_2d(p * (abs(pow(sin(time * .37), 2.) * 3.) + .5), sin(time / 2.) * 2.) + vec2(time * .17, time * .37) * 5.);
    glFragColor = vec4(hsv_rgb(vec3(sin(v * 100. + time * 3.7) * 180. + 180., abs(v), abs(sin(-v * 17. + time * 1.4) * v))), 1.);
}
