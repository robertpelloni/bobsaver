#version 420

// original https://www.shadertoy.com/view/3tBczh

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Copyright 2020 Google LLC
// SPDX-License-Identifier: Apache-2.0
// NOT an official Google project; see Google Open Source guidelines for more info on copyright transfer
// written by William Cadegan-Schlieper 

float tau = 6.283185307179586;

bool flip(inout vec3 z, inout float ds, in vec2 c, in float r, inout float t) {
    z -= vec3(c,0.0);
    bool res = (dot(z,z) < r*r) ^^ (r < 0.0);
    if (res) {
        ds *= r * r / dot(z,z);
        z *= r * r / dot(z,z);
    }
    t = min(t, (dot(z,z)-r*r)/(2.0 * r * ds));
    z += vec3(c,0.0);
    return res;
}

void main(void)
{
    vec3[3] colorizers = vec3[](
        vec3(0.25,0.0,0.0),
        vec3(0.0,0.3,0.0),
        vec3(-0.13)
    );
    int[14] m = int[](3,0,1,2,0,1,2,0,2,1,0,2,1,3);
    
    vec2 z = 2.0 * (gl_FragCoord.xy - resolution.xy * 0.5)/resolution.y;
    float ds = 1.0 / resolution.y;
    z *= 10.0; ds *= 10.0;
    vec3 zh = vec3(z, 1.0);
    
    vec2[14] c; float[14] r;
    float r1 = sqrt(sqrt(3.0) - sqrt(2.0));
    r[0] = r1; c[0] = vec2(0.0);
    float r2 = r1;
    float x2 = sqrt(r1*r1+r2*r2);
    float r3 = r2 / ( x2 * x2 - r2 * r2);
    float x3 = -x2 / ( x2 * x2 - r2 * r2);
    for (int i=0; i<6; i++) {
        float theta = tau * float(i) / 6.0;
        vec2 eit = vec2(cos(theta), sin(theta));
        r[i+1] = r2;
        c[i+1] = x2 * eit;
        r[i+7] = r3;
        c[i+7] = x3 * eit.yx;
    }
    float r4 = -1.0 / r1;
    r[13] = r4; c[13] = vec2(0.0);
    
    
    float period = -8.0 * log(r1);
    float d = mod(time * 0.2, period) - period * 0.5;
    zh *= exp(-d); ds *= exp(-d);
    
    bool[4] flips=bool[](false,false,false,false);
    float[4] ts=float[](1.0,1.0,1.0,1.0);
    for (int i=0; i<6; i++) {
        for (int j=0; j<14; j++) {
            flips[m[j]] = flips[m[j]] ^^ flip(zh, ds, c[j], r[j], ts[m[j]]);
        }
    }
    vec3 col = vec3(0.5);
    if (flips[3]) {
        ts[3] = -ts[3];
    }
    for (int i=0; i<3; i++) {
        if (flips[i]) {
            ts[i] = -ts[i];
        }
        col += colorizers[i] * ts[i] * ts[3];
    }
    glFragColor = vec4(col,1.0);
    glFragColor = pow(glFragColor, vec4(1.0/2.2));
}
