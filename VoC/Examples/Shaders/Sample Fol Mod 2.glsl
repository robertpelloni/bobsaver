#version 420

// original https://www.shadertoy.com/view/mdBXDz

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// (c) 2016 xoihazard

#define TWO_PI 6.2831853072
#define PI 3.14159265359

const float timeScale = 0.2;
const float displace = 0.04;
const float gridSize = 18.0;
const float wave = 5.0;
const float brightness = 1.5;

vec2 rotate(in vec2 v, in float angle) {
    float c = cos(angle);
    float s = sin(angle);
    return v * mat2(c, -s, s, c);
}

vec3 coordToHex(in vec2 coord, in float scale, in float angle) {
    vec2 c = rotate(coord, angle);
    float q = (1.0 / 3.0 * sqrt(3.0) * c.x - 1.0 / 3.0 * c.y) * scale;
    float r = 2.0 / 3.0 * c.y * scale;
    return vec3(q, r, -q - r);
}

vec3 hexToCell(in vec3 hex, in float m) {
    return fract(hex / m) * 2.0 - 1.0;
}

float absMax(in vec3 v) {
    return max(max(abs(v.x), abs(v.y)), abs(v.z));
}

float nsin(in float value) {
    return sin(value * TWO_PI) * 0.5 + 0.5;
}

float hexToFloat(in vec3 hex, in float amt) {
    return mix(absMax(hex), 1.0 - length(hex) / sqrt(3.0), amt);
}

float calc(in vec2 tx, in float time) {
    float angle = PI * nsin(time * 0.1) + PI / 6.0;
    float len = 1.0 - length(tx) * nsin(time);

    vec3 hex = coordToHex(tx, gridSize * nsin(time * 0.1), angle);
    vec3 cell = hexToCell(hex, 1.0);
    float value = nsin(hexToFloat(cell, nsin(time)) * wave * nsin(time * 0.5) + len + time);

    float moire = sin(tx.x * 20.0 + time * 5.0) * 0.5 + 0.5;

    return value * moire;
}

void main(void) {
    vec2 tx = (gl_FragCoord.xy / resolution.xy) - 0.5;
    tx.x *= resolution.x / resolution.y;
    float time = time * timeScale;
    vec3 rgb = vec3(0.0, 0.0, 0.0);
    for (int i = 0; i < 3; i++) {
        float time2 = time + float(i) * displace;
        rgb[i] += pow(calc(tx, time2), 2.0);
    }
    glFragColor = vec4(rgb * brightness, 1.0);
}
