#version 420

// original https://www.shadertoy.com/view/wsBcRm

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Copyright 2020 Google LLC
// SPDX-License-Identifier: Apache-2.0
// NOT an official Google project; see Google Open Source guidelines for more info on copyright transfer
// written by William Cadegan-Schlieper 

vec3 color(vec2 z) {
    for (int i=0;i<100;i++) {
        z.x = mod(z.x,4.0);
        if (z.x > 3.0) {
            z.x -= 4.0;
        }
        if (z.x > 1.0) {
            z.x = 2.0-z.x;
        }
        
        if (z.y > 1.0) {
            return vec3(1.0,0.2,0.2);
        }
        if (z.y < -1.0) {
            return vec3(0.5,1.0,0.0);
        }

        
        z /= 0.5 * dot(z,z);
        z.y = mod(z.y,4.0);
        if (z.y > 3.0) {
            z.y -= 4.0;
        }
        if (z.y > 1.0) {
            z.y = 2.0 - z.y;
        }
        
        if (z.x > 1.0) {
            return vec3(1.0,0.7,0.0);
        }
        if (z.x < -1.0) {
            return vec3(0.5,0.0,1.0);
        }
        z /= 0.5 * dot(z,z);
        
    }
    return vec3(0.0,0.0,0.0);
}

void main(void)
{
    vec2 uv = 2.0 * (gl_FragCoord.xy - resolution.xy * 0.5)/resolution.y;   
    
    float t = time * 1.5;
    
    float period = 2.0 * 2.1225501238;
    
    while (t > period * 0.5) {
        t -= period;
        float c = -0.888543820;
        float s = 0.458791760;
        uv = vec2(uv.x * c - uv.y * s,
                  uv.x * s + uv.y * c);
    }
    
    
    
    uv *= exp(-t);
    
    uv.x += 0.28443224050;
    uv.y -= 0.17578879212;
    
    uv /= dot(uv,uv);

    uv.x -= 0.27201964951;
    uv.y += 0.78615137877;
    
    glFragColor = vec4(color(uv),1.0);
}
