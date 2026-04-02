#version 420

// original https://www.shadertoy.com/view/tlXcz7

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
    
    float period = -8.0 * log(r1);
    float d = mod(time * 0.2, period) - period * 0.5;
    z *= exp(-d);
    
    bool fl = false;
    float yellow = 0.0;
    int t = 1;
    int s1 = 0;
    int s2 = 0;
    int s3 = 0;
    bool fl1 = false; bool fl2 = false; bool fl3 = false;
    for (int i=0; i<7; i++) {
        fl1 = fl1 ^^ flip(z, c[0], r[0], s1, 1);
        fl1 = fl1 ^^ flip(z, c[1], r[1], s1, 1);
        fl3 = fl3 ^^ flip(z, c[2], r[2], s3, 1);
        fl2 = fl2 ^^ flip(z, c[3], r[3], s2, 1);
        fl2 = fl2 ^^ flip(z, c[4], r[4], s2, 1);
        fl3 = fl3 ^^ flip(z, c[5], r[5], s3, -1);
        fl1 = fl1 ^^ flip(z, c[6], r[6], s1, -1);
        fl3 = fl3 ^^ flip(z, c[7], r[7], s3, -1);
        fl2 = fl2 ^^ flip(z, c[8], r[8], s2, -1);
        fl2 = fl2 ^^ flip(z, c[9], r[9], s2, -1);
        fl3 = fl3 ^^ flip(z, c[10], r[10], s3, 1);
        fl1 = fl1 ^^ flip(z, c[11], r[11], s1, -1);
        
    }
    if (fl1) {s1=-s1;}
    if (fl2) {s2=-s2;}
    if (fl3) {s3=-s3;}
    vec3 s = vec3(float(s1) + 4.0 * d / period,float(s2),float(s3));
    
    s = s / (1.3 + abs(s));
    vec3 col = 0.5 + s * 0.45;
    col = col.ggg; col.gb*=0.8;
    glFragColor = vec4(col,1.0);
    glFragColor = pow(glFragColor, vec4(1.0/2.2));
}
