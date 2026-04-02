#version 420

// original https://www.shadertoy.com/view/sdXSW8

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Based on a quick doodle I did on desmos:
// https://www.desmos.com/calculator/mbtrtwqbwb
#define dot2(v) dot(v, v)
vec4 solveCubic(in float a, in float b, in float c, in float d) {
    float aa = a * a, bb = b * b;

    float dcnom = 3.0 * aa;
    float inflect = b / (3.0 * a);

    float p = c / a - bb / dcnom;
    float q = bb * b / (13.5 * aa * a) - b * c / dcnom + d / a;
    float ppp = p * p * p, qq = q * q;

    float p2 = abs(p);
    float v1 = 1.5 / p * q;

    vec4 roots = vec4(0.0, 0.0, 0.0, 1.0);
    if (qq * 0.25 + ppp / 27.0 > 0.0) {
        float v2 = v1 * sqrt(3.0 / p2);
        if (p < 0.0) roots[0] = sign(q) * cosh(acosh(v2 * -sign(q)) / 3.0);
        else roots[0] = sinh(asinh(v2) / 3.0);
        roots[0] = -2.0 * sqrt(p2 / 3.0) * roots[0] - inflect;
    }

    else {
        float ac = acos(v1 * sqrt(-3.0 / p)) / 3.0; // 0π/3,       2π/3,               4π/3
        roots = vec4(2.0 * sqrt(-p / 3.0) * cos(vec3(ac, ac - 2.09439510239, ac - 4.18879020479)) - inflect, 3.0);
    }

    return roots;
}

vec2 parametricBezier(in vec2 a, in vec2 b, in vec2 c, in float t) {
    t = clamp(t, 0.0, 1.0);
    float tInv = 1.0 - t;
    return a * tInv * tInv + b * 2.0 * t * tInv + c * t * t;
}

float sdBezier(in vec2 p, in vec2 a, in vec2 b, in vec2 c) {
    vec2 c1 = p - a;
    vec2 c2 = 2.0 * b - c - a;
    vec2 c3 = 2.0 * (a - b);

    float coeff1 = 4.0 * dot2(c2);
    float coeff2 = 6.0 * dot(c3, c2);
    float coeff3 = 4.0 * dot(c1, c2) + 2.0 * dot2(c3);
    float coeff4 = 2.0 * dot(c1, c3);

    vec4 roots = solveCubic(coeff1, coeff2, coeff3, coeff4);
    float dist = dot2(p - parametricBezier(a, b, c, roots[0]));
    if (roots[3] > 1.0) {
        dist = min(dist, dot2(p - parametricBezier(a, b, c, roots[1])));
        dist = min(dist, dot2(p - parametricBezier(a, b, c, roots[2])));
    }

    return sqrt(dist);
}

float sdLine(in vec2 p, in vec2 a, in vec2 b) {
    vec2 pa = p - a, ba = b - a;
    return length(pa - ba * clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0));
}

// Modified hash from "Hash without Sine" by Dave_Hoskins (https://www.shadcrtoy.com/view/4djSRW)
vec2 Hash12(in float x) {
    vec3 p3 = fract(x * vec3(0.1031, 0.1030, 0.0973));
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.xx + p3.yz) * p3.zy) * 2.0 - 1.0;
}

void main(void) {
    vec2 center = 0.5 * resolution.xy;
    vec2 uv = (gl_FragCoord.xy - center) / resolution.y * 2.0;
    vec2 mouse = (mouse*resolution.xy.xy - center) / resolution.y;

    float dc = 1000000000000.0, dp = dc, de = dc;
    float par = fract(time), sec = floor(time);
    for (float v=sec; v < sec + 10.0; v++) {
        vec2 v1 = Hash12(v), v2 = Hash12(v + 1.0), v3 = Hash12(v + 2.0);
        vec2 a = mix(v1, v2, par), b = mix(v2, v3, par), c = mix(v3, Hash12(v + 3.0), par);
        dc = min(dc, sdBezier(uv, 0.5 * (a + b), b, 0.5 * (b + c)));

        de = min(de, sdLine(uv, a, b));
        de = min(de, sdLine(uv, b, c));

        dp = min(dp, dot2(uv - a));
        dp = min(dp, dot2(uv - b));
        dp = min(dp, dot2(uv - c));
    }

    vec3 color = vec3(0.0);

    color = mix(color, vec3(1.0, 0.8, 0.0), 1.0 - smoothstep(0.0, 0.015, de - 0.0025));
    color = mix(color, vec3(1.0, 0.0, 0.0), 1.0 - smoothstep(0.0, 0.015, sqrt(dp) - 0.02));
    color = mix(color, vec3(1.0), 1.0 - smoothstep(0.0, 0.015, dc - 0.01));

    glFragColor = vec4(color, 1.0);
}
