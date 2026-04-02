#version 420

// original https://www.shadertoy.com/view/dtcSzn

uniform float time;
uniform vec4 date;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Copyright © 2023 IWBTShyGuy
// Attribution 4.0 International (CC BY 4.0)

const float PI = 3.1415926583;

const vec4 COLOR0 = vec4(0.1, 1.0, 0.2, 1.0);
const vec4 COLOR1 = vec4(1.0, 0.5, 0.0, 1.0);

// Hash without Sine https://www.shadertoy.com/view/4djSRW
vec2 hash22(vec2 p)
{
	vec3 p3 = fract(vec3(p.xyx) * vec3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yzx+33.33);
    return fract((p3.xx+p3.yz)*p3.zy);

}

float d2 (vec2 x, vec2 y) { x -= y; return dot(x, x); }
void honeycomb(inout vec2 u, out vec2 id) {
    const mat2 M = mat2(2, 0, 1, sqrt(3.0)) / 2.0;
    const vec2 A = M[0], B = M[1], O = A.yy;

    id = floor(inverse(M) * u);
    vec2 v = u - M * id;
    float a = d2(v, O), b = d2(v, A), c = d2(v, B),
    d = d2(v, A + B), e = min(min(min(a, b), c), d);
    id += e == a ? O : e == b ? A : e == c ? A.yx : A.xx;
    u = u - M * id;
}

float sdLine(vec2 p, vec2 a, vec2 b) {
    vec2 x = p - a, y = b - a;
    return length(x - clamp(dot(x, y) / dot(y, y), 0., 1.) * y);
}

vec2 vertex(int i) {
    float t = float(i) * PI / 3.0;
    return vec2(-sin(t), cos(t)) / sqrt(3.0);
}

float tile0(in vec2 U) {
    float dist = abs(length(U - vertex(0)) - sqrt(3.0) / 6.0);
    dist = min(dist, sdLine(U, (vertex(1) + vertex(2)) / 2.0, (vertex(4) + vertex(5)) / 2.0));
    dist = min(dist, abs(length(U - vertex(3)) - sqrt(3.0) / 6.0));
    return dist - sqrt(3.0) / 18.0;
}

float tile1(in vec2 U) {
    float dist = 100.0;
    for (int i = 0; i < 6; i++)
        dist = min(dist, length(U - vertex(i)));
    return sqrt(3.0) / 9.0 - dist;
}

float tile2(in vec2 U) {
    float dist = length(U - (vertex(1) + vertex(2)) / 2.0);
    dist = min(dist, length(U - (vertex(4) + vertex(5)) / 2.0));
    dist = min(dist, abs(length(U - vertex(1) - vertex(2)) - sqrt(3.0) / 2.0));
    dist = min(dist, abs(length(U - vertex(4) - vertex(5)) - sqrt(3.0) / 2.0));
    return dist - sqrt(3.0) / 18.0;
}

void main(void) { //WARNING - variables void (out vec4 O, in vec2 U) { need changing to glFragColor and gl_FragCoord.xy
    vec2 U = gl_FragCoord.xy;
    vec4 O = vec4(0.0);
    
    U = U * 7.0 / resolution.y + date.w * 0.5;
    vec2 id;
    honeycomb(U, id);

    vec2 rand = hash22(id);
    mat2 rot = mat2(-1, sqrt(3.0), -sqrt(3.0), -1) / 2.0;
    if (rand.x < 1.0 / 3.0) U = rot * U;
    if (rand.x < 2.0 / 3.0) U = rot * U;

    float dist;
    switch (int(rand.y * 3.0)) {
        case 0: dist = tile0(U); break;
        case 1: dist = tile1(U); break;
        case 2: dist = tile2(U); break;
    }
    float d = 6.0 / resolution.y;
    float x = smoothstep(-d, d, dist);
    O = mix(COLOR0, COLOR1, x);
    
    glFragColor=O;
}