#version 420

// original https://www.shadertoy.com/view/tlsyD8

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Copyright 2020 Google LLC
// SPDX-License-Identifier: Apache-2.0
// NOT an official Google project; see Google Open Source guidelines for more info on copyright transfer
// written by William Cadegan-Schlieper 

float tau = 6.283185307179586;

bool flip(inout vec3 z, in vec2 c, in float r, inout int t, in int k) {
    z.xy -= c;
    bool res = (dot(z,z) < r*r) ^^ (r < 0.0);
    if (res) {
        z *= r * r / dot(z,z);
        t = k - t;
    }
    z.xy += c;
    return res;
}

bool inside(in vec3 z, in vec2 c, in float r, inout float t) {
    vec3 p = z - vec3(c,0.0);
    float res = (dot(p,p)-r*r) / (2.0 * abs(r) * p.z);
    t = min(t, abs(res));
    return res < 0.0;
}

void main(void)
{
    vec2 z0 = 2.0 * (gl_FragCoord.xy - resolution.xy * 0.5)/resolution.y;
    float ds = 1.0 / resolution.y;
    vec3 z = vec3(z0,ds);
    
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
    z *= exp(-d);
    
    bool fl = false;
    float yellow = 0.0;
    int t = 1;
    int s = 0;
    bool fl1 = false; bool fl2 = false; bool fl3 = false;
    for (int i=0; i<7; i++) {
        fl = fl ^^ flip(z, c[0], r[0], t, 0);
        fl = fl ^^ flip(z, c[2], r[2], t, 0);
        fl = fl ^^ flip(z, c[5], r[5], t, 0);
        fl = fl ^^ flip(z, c[7], r[7], t, 0);
        fl = fl ^^ flip(z, c[10], r[10], t, 0);
        fl = fl ^^ flip(z, c[11], r[11], t, 0);
        
        fl1 = fl1 ^^ flip(z, c[1], r[1], s, -1);
        fl2 = fl2 ^^ flip(z, c[3], r[3], s, 1);
        fl3 = fl3 ^^ flip(z, c[4], r[4], s, 1);
        fl1 = fl1 ^^ flip(z, c[6], r[6], s, 1);
        fl2 = fl2 ^^ flip(z, c[8], r[8], s, -1);
        fl3 = fl3 ^^ flip(z, c[9], r[9], s, -1);
    }
    if (fl1) {s=-s;}
    if (fl2) {s=-s;}
    if (fl3) {s=-s;}
    float st = float(s);
    
    st = st / (1.0 + abs(st));
    vec3 col = vec3(0.5 + st * 0.45); col.g *= 0.8; col.b *= 0.6;
    glFragColor = vec4(col,1.0);
    glFragColor = pow(glFragColor, vec4(1.0/2.2));
}
