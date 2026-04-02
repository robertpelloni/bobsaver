#version 420

// original https://www.shadertoy.com/view/wdSyDG

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Copyright 2020 Google LLC
// SPDX-License-Identifier: Apache-2.0
// NOT an official Google project; see Google Open Source guidelines for more info on copyright transfer
// written by William Cadegan-Schlieper 
float s = 0.4142135623730951; // silver ratio

void octant1(inout vec2 z, inout float ds, inout vec3[3] colors) {
    if (z.x < 0.0) {
        z.x = -z.x;
        colors[2]=1.0-colors[2];
    }
    if (z.y < 0.0) {
        z.y = -z.y;
        colors[1]=1.0-colors[1];
    }
    float r2 = dot(z,z);
    if (r2 > 1.0) {
        z /= r2; ds /= r2;
        colors[0]=1.0-colors[0];
    }
}

vec3 color(vec2 z, float ds, bool fl) {
    vec3[3] colors;
    colors[0]=vec3(1.0,0.5,0.0);
    colors[1]=vec3(0.0,1.0,0.5);
    colors[2]=vec3(0.5,0.0,1.0);
    
    if (fl) {
        colors[0]=1.0-colors[0];
        colors[1]=1.0-colors[1];
        colors[2]=1.0-colors[2];
    }
    
    float r2;
    int n = 60;
    int i;
    for(i=0;i<n;i++) {
        octant1(z, ds, colors);
        z -= vec2(s,s);
        r2 = dot(z,z);
        if (r2 < s * s) {
            z *= s * s / r2; ds *= s * s / r2;
            fl = !fl;
            z += vec2(s,s);
        } else {
            z += vec2(s,s);
            break;
        }
    }
    octant1(z, ds, colors);
    r2 = dot(z,z);
    float v = (r2 - 2.0 * (z.x + z.y) * s + s * s) / (2.0 * ds * s * s);
    v = min(v,1.0);
    v = 0.75 + 0.25 * float(n-i) / float(n) * v;
    if (fl) v = 1.5 - v;
    float zz = 0.5 * (1.0 - r2);
    if (zz > z.x && zz > z.y) {
        return colors[0] * v * min(1.0, min((zz - z.x) / ds, (zz - z.y) / ds));
    }
    if (z.y > z.x) {
        return colors[1] * v * min(1.0, min((z.y - zz) / ds, (z.y - z.x) / ds));
    }
    return colors[2] * v * min(1.0, min((z.x - zz) / ds, (z.x-z.y) / ds));
}

void main(void) {
    vec2 uv = 2.0 * (gl_FragCoord.xy - resolution.xy * 0.5)/resolution.y;
    float ds = 4.0 / resolution.y;
    
    float period = 4.2549485065150545;
    float t = time * 0.5;
    bool r = false;
    
    while (t > period * 0.5) {
        t -= period;
        float c = 0.766311365; float s = -0.64246936;
        uv = vec2(uv.x * c - uv.y * s, uv.x * s + uv.y * c);
        r = !r;
    }
    
    uv *= exp(-t); ds *= exp(-t);
    
    uv += vec2(0.25262046414724887,-1.0187347727326157);
    uv /= dot(uv,uv); ds *= dot(uv,uv);
    uv += vec2(0.22732631827540598,0.4228686518338363);

    glFragColor = vec4(color(uv,ds,r),1.0);
    glFragColor = pow(glFragColor, vec4(1./2.2));
}
