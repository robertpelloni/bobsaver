#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/tsXBRf

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Copyright 2020 Google LLC
// SPDX-License-Identifier: Apache-2.0
// NOT an official Google project; see Google Open Source guidelines for more info on copyright transfer
// written by William Cadegan-Schlieper 

vec3 color(vec2 z, float ds) {
    int i;
    for (i=0; i<100; i++) {
        z.x = mod(z.x,4.0);
        if (z.x > 3.0) {
            z.x -= 4.0;
        }
        if (z.x > 1.0) {
            z.x = 2.0-z.x;
        }
        
        if (z.y < -1.0) {
            z.y = -2.0 - z.y;
        }
        if (z.y > 1.0) {
            break;
        }
        z /= -0.5 * dot(z,z);
        ds *= 0.5 * dot(z,z);
    }
    float col = 0.5 * min(1.0, (z.y - 1.0) / ds);
    if (i%2==0) {
        return vec3(0.5 + col);
    } else {
        return vec3(0.5 - col);
    }
}

void main(void)
{
    vec2 uv = 2.0 * (gl_FragCoord.xy - resolution.xy * 0.5)/resolution.y;
    float ds = 1.0 / resolution.y;

    
    float t = time * 0.5;
    
    float period = 4.0 * log(2.0 + sqrt(5.0));
    while (t > period * 0.5) {
        t -= period;
    }
    
    
    
    uv *= exp(-t); ds *= exp(-t);
    
    uv.x -= sqrt(0.05);
    
    uv /= dot(uv,uv);
    ds *= dot(uv,uv);

    uv.x += sqrt(5.0);
    
    glFragColor = vec4(color(uv, ds),1.0);
    glFragColor = pow(glFragColor, vec4(1.0/2.2));
}
