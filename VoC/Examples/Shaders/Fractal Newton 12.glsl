#version 420

// original https://www.shadertoy.com/view/wd2SRc

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const int MAX_ITERS = 500;

const vec3 COLOR_1 = 1.5 * vec3(139, 38, 53) / 255.;
const vec3 COLOR_2 = 1.5 * vec3( 13, 92, 99) / 255.;
const vec3 COLOR_3 = 1.5 * vec3( 11, 57, 84) / 255.;
const vec3 COLOR_4 = 5. * vec3(  4, 15, 15) / 255.;
const vec3 COLOR_5 = 1.5 * vec3( 46, 53, 50) / 255.;

vec2 cmult(vec2 z1, vec2 z2) {
    return vec2(
        z1.x * z2.x - z1.y * z2.y,
        z1.x * z2.y + z1.y * z2.x
    );
}

vec2 cdiv(vec2 z1, vec2 z2) {
    vec2 conj = vec2(z2.x, -z2.y);
    return cmult(z1, conj) / (length(z2) * length(z2));
}

vec3 colorFromEndpoint(vec2 pole) {
    if (pole.x > 0.1 && pole.y > 0.1) return COLOR_1;
    if (pole.x > 0.1 && pole.y < -0.1) return COLOR_2;
    if (pole.x < -0.1 && pole.y > 0.1) return COLOR_3;
    if (pole.x < -0.1 && pole.y < -0.1) return COLOR_4;
    return COLOR_5;
}

vec2 newton(vec2 z) {
    vec2 diff = cmult(cmult(z, z), cmult(z, z)) * 5.;
    vec2 func = cmult(cmult(z, z), cmult(z, cmult(z, z))) - vec2(1, 0);
    return z - cdiv(func, diff);
}

vec3 getColor(vec2 z) {
    for (int i = 0; i < MAX_ITERS; i++) {
        vec2 n = newton(z);
        if (length(z - n) < 0.001) {
            break;
        }
        z = n;
    }
    return colorFromEndpoint(z);
}

void main(void)
{
    vec2 z = 3.0 * (gl_FragCoord.xy - resolution.xy / 2.0) / resolution.y;
    vec3 color = getColor(z);
    glFragColor = vec4(color, 1.0);
}
