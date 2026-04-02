#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/tlfcRn

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Copyright 2020 Google LLC
// SPDX-License-Identifier: Apache-2.0
// NOT an official Google project; see Google Open Source guidelines for more info on copyright transfer
// written by William Cadegan-Schlieper 

vec3 color(vec3 z) {
    int i;
    float res = 0.0;
    for (i=0; i<160; i++) {
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
        res += float(int((z.y+1.0) / 2.0));
        z.y = mod(z.y + 1.0, 4.0) - 1.0;
        if (z.y > 1.0) {
            z.y = 2.0 - z.y;
            res += 1.0;
        }
        if (dot(z,z) < 2.0) {
            z /= -0.5 * dot(z,z);
            z.z = abs(z.z);
            res = -res;
        } else {
            break;
        }
    }
    if (i%2!=0) {
        res = -res;
    }
    float col = 1.0 - 1.0 / abs(res);
    if (res > 0.0) {
        return col * vec3(1.0,0.5,0.0);
    } else {
        return col * vec3(0.0,0.5,1.0);
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
    
    
   
    
    
    vec3 z = vec3(uv, 1.3 * ds);
    z *= exp(-t);
    
    z.x -= sqrt(0.05);
    
    z /= dot(z,z);
    
    z.x += sqrt(5.0);
    
    
    glFragColor = vec4(color(z),1.0);
    glFragColor = pow(glFragColor, vec4(1.0/2.2));
}
