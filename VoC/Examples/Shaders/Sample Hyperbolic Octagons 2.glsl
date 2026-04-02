#version 420

// original https://www.shadertoy.com/view/tsBcDG

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Copyright 2020 Google LLC
// SPDX-License-Identifier: Apache-2.0
// NOT an official Google project; see Google Open Source guidelines for more info on copyright transfer
// written by William Cadegan-Schlieper 
#define swap(x,y) {t=x;x=y;y=t;}

vec3 color(vec2 z, float ds) {
    float pi = 3.14159265359;
    float theta = pi/8.0;
    // someday I'll explain the cross-ratio magic that got me these numbers
    float r = 2.0 / (1.0 - sqrt(1.0 - 4.0 * sin(theta) * sin(theta)));
    float p = - r * cos(theta);
    bool fl = false;
    vec3[3] colors;
    colors[0] = vec3(1.0,0.5,0.0);
    colors[1] = vec3(0.0,1.0,0.5);
    colors[2] = vec3(0.5,0.0,1.0);
    vec3 t; // for temp space
    for(int i=0;i<100;i++) {
        if (z.x < 0.0) {
            z.x = -z.x;
            colors[2] = 1.0 - colors[2];
            fl = !fl;
            continue;
        }
        if (dot(z,z) < 1.0) {
            z /= dot(z,z);
            ds *= dot(z,z);
            fl = !fl;
            swap(colors[0],colors[1]);
            continue;
        }
        z.x -= p;
        if (dot(z,z) > r*r) {
            ds *= r * r / dot(z,z);
            z *= r * r / dot(z,z);
            fl = !fl;
            z.x += p;
            swap(colors[1],colors[2]);
            continue;
        }
        z.x += p;
        
        break;
        

    }
    vec3 col = colors[0];
    float f = 1.0;
    f = min(f, z.x / ds);
    z.x -= p;
    f = min(f, (r * r - dot(z,z)) / (ds * 2.0 * r));
    z.x += p;
    f = 0.75 + 0.25 * f;
    if (fl) {
        f = 1.5 - f;
    }
    col *= f;
    if (dot(z,z) - 1.0 < ds * 2.0) {
        float t = (dot(z,z) - 1.0) / (ds * 2.0);
        vec3 col2 = colors[1] * (1.5 - f);
        col = (1.0 + t) * col + (1.0 - t) * col2;
        col *= 0.5;
    }
    return col * min(1.0,1.0 / ds);
}

void main(void)
{
    vec2 uv = 2.0 * (gl_FragCoord.xy - resolution.xy * 0.5)/resolution.y;
    float ds = 2.0 / resolution.y;

    float r2 = dot(uv,uv);
    if (r2 < 1.0) {
        uv.y -= 1.0;
        uv /= dot(uv,uv); ds *= dot(uv,uv);
        uv.y = -0.5 - uv.y;
        
        float t = 0.1 * time;
        float period = 6.0 * 0.6329743192009469;
        t = mod(t,period) - period * 0.5;
        uv *= exp(t); ds *= exp(t);
        
        uv.x -= 0.43973261203230474;
        uv /= dot(uv,uv); ds *= dot(uv,uv);
        uv.x += 1.6782507245215834;
        
        glFragColor = vec4(color(uv,ds),1.0);
    } else {
        glFragColor = vec4(0.0,0.0,0.0,1.0);
    }
    glFragColor = pow(glFragColor, vec4(1./2.2));

}
