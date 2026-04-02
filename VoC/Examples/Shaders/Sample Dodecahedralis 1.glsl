#version 420

// original https://www.shadertoy.com/view/tssfzl

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Copyright 2020 Google LLC
// SPDX-License-Identifier: Apache-2.0
// NOT an official Google project; see Google Open Source guidelines for more info on copyright transfer
// written by William Cadegan-Schlieper 

float tau = 6.283185307179586;

bool flip(inout vec2 z, inout float ds, in vec2 c, in float r, inout float t) {
    z -= c;
    bool res = (dot(z,z) < r*r) ^^ (r < 0.0);
    if (res) {
        ds *= r * r / dot(z,z);
        z *= r * r / dot(z,z);
    }
    t = min(t, (dot(z,z)-r*r)/(2.0 * r * ds));
    z += c;
    return res;
}

bool inside(in vec2 z, in float ds, in vec2 c, in float r, inout float t) {
    vec2 p = z - c;
    float res = (dot(p,p)-r*r) / (2.0 * abs(r) * ds);
    t = min(t, abs(res));
    return res < 0.0;
}

void main(void)
{
    vec2 z = 2.0 * (gl_FragCoord.xy - resolution.xy * 0.5)/resolution.y;
    float ds = 1.0 / resolution.y;
    
    vec2[12] c; float[12] r;
    float r1 = pow(1.5 + 0.5 * sqrt(5.0) - sqrt(1.5 * sqrt(5.0) + 2.5), 0.5);
    r[0] = r1; c[0] = vec2(0.0);
    float r2 = r1 * sqrt(sqrt(5.0));
    float x2 = sqrt(r1*r1+r2*r2);
    float r3 = r2 / ( x2 * x2 - r2 * r2);
    float x3 = -x2 / ( x2 * x2 - r2 * r2);
    for (int i=0; i<5; i++) {
        float theta = tau * 0.2 * float(i);
        vec2 eit = vec2(cos(theta), sin(theta));
        r[i+1] = r2;
        c[i+1] = x2 * eit;
        r[i+6] = r3;
        c[i+6] = x3 * eit;
    }
    float r4 = -1.0 / r1;
    r[11] = r4; c[11] = vec2(0.0);
    
    float period = -4.0 * log(r1);
    float d = mod(time * 0.2, period) - period * 0.5;
    z *= exp(-d); ds *= exp(-d);
    
    bool fl = false;
    float yellow = 0.0;
    float t = 1.0;
    for (int i=0; i<7; i++) {
        fl = fl ^^ flip(z, ds, c[0], r[0], t);
        fl = fl ^^ flip(z, ds, c[2], r[2], t);
        fl = fl ^^ flip(z, ds, c[5], r[5], t);
        fl = fl ^^ flip(z, ds, c[7], r[7], t);
        fl = fl ^^ flip(z, ds, c[10], r[10], t);
        fl = fl ^^ flip(z, ds, c[11], r[11], t);
        yellow = max(yellow, 3.0 * ds / (-r4 - r1));
        if (yellow > 1.0) {
            glFragColor = vec4(1.0,1.0,0.0,0.0);
            return;
        }
    }
    
    fl = fl ^^ inside(z, ds, c[1], r[1], t);
    fl = fl ^^ inside(z, ds, c[3], r[3], t);
    fl = fl ^^ inside(z, ds, c[4], r[4], t);
    fl = fl ^^ inside(z, ds, c[6], r[6], t);
    fl = fl ^^ inside(z, ds, c[8], r[8], t);
    fl = fl ^^ inside(z, ds, c[9], r[9], t);
    t = (1.0 - t) * 0.5;
    if (fl) {
        t = 1.0 - t;
    }
    vec3 col = vec3(t);
    yellow = yellow * yellow;
    col = (1.0 - yellow) * col + yellow * vec3(1.0, 1.0, 0.0);
    glFragColor = vec4(col,1.0);
    glFragColor = pow(glFragColor, vec4(1.0/2.2));
}
