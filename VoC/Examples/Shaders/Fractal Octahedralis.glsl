#version 420

// original https://www.shadertoy.com/view/WdSyDh

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Copyright 2020 Google LLC
// SPDX-License-Identifier: Apache-2.0
// NOT an official Google project; see Google Open Source guidelines for more info on copyright transfer
// written by William Cadegan-Schlieper 
vec3 color(vec2 z) {
    float s = 0.4142135623730951; // silver ratio
    vec3[3] colors;
    colors[0]=vec3(1.0,0.0,0.0);
    colors[1]=vec3(0.0,1.0,0.0);
    colors[2]=vec3(0.0,0.0,1.0);
    float r2;
    bool fl = false;
    for(int i=0;i<100;i++) {
        if (z.x < 0.0) {
            z.x = -z.x;
            colors[2]=1.0-colors[2];
        }
        if (z.y < 0.0) {
            z.y = -z.y;
            colors[1]=1.0-colors[1];
        }
        r2 = dot(z,z);
        if (r2 > 1.0) {
            z /= r2;
            colors[0]=1.0-colors[0];
        }
        z -= vec2(s,s);
        r2 = dot(z,z);
        if (r2 < s * s) {
            z *= s * s / r2;
            fl = !fl;
            z += vec2(s,s);
        } else {
            z += vec2(s,s);
            vec3 col;
            if (dot(z,z) < s * s) {
                col = colors[0];
            } else if (z.x < z.y) {
                col = colors[1];
            } else {
                col = colors[2];
            }
            if (fl) col *= 0.5;
            return col;
        }
    }
    if (z.x < 0.0) {
        z.x = -z.x;
        colors[2]=1.0-colors[2];
    }
    if (z.y < 0.0) {
        z.y = -z.y;
        colors[1]=1.0-colors[1];
    }
    r2 = dot(z,z);
    if (r2 > 1.0) {
        z /= r2;
        colors[0]=1.0-colors[0];
    }
    float zz = 0.5 * (1.0 - dot(z,z));
    if (zz > z.x && zz > z.y) {
        return colors[0] * 0.75;
    }
    if (z.y > z.x) {
        return colors[1] * 0.75;
    }
    return colors[2] * 0.75;
}

void main(void)
{
    vec2 uv = 2.0 * (gl_FragCoord.xy - resolution.xy * 0.5)/resolution.y;   
    uv = vec2(uv.x+uv.y,uv.x-uv.y);
    
    float period = 2.2924316695611773;
    
    float t = mod(time * 0.5+3.0,period * 2.0);
    bool r = false;
    
    if (t > period * 1.0) {
        t -= period * 2.0;
    }
    
    uv *= exp(-t);
    
    uv += vec2(0.2886751345948129,0.2886751345948129);
    uv /= dot(uv,uv);
    uv += vec2(-1.3660254037844382,-1.3660254037844382);

    glFragColor = vec4(color(uv),1.0);
}
