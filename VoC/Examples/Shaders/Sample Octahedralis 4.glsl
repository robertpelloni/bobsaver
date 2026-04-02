#version 420

// original https://www.shadertoy.com/view/wljyWh

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Copyright 2020 Google LLC
// SPDX-License-Identifier: Apache-2.0
// NOT an official Google project; see Google Open Source guidelines for more info on copyright transfer
// written by William Cadegan-Schlieper 
float s = 0.4142135623730951; // silver ratio

void octant1(inout vec3 z, inout float coh, inout bool fl) {
    if (z.x < 0.0) {
        z.x = -z.x;
        coh=-coh;
        fl=!fl;
    }
    if (z.y < 0.0) {
        z.y = -z.y;
        coh=-coh;
        fl=!fl;
    }
    float r2 = dot(z,z);
    if (r2 > 1.0) {
        z /= r2;
        coh=-coh;
        fl=!fl;
    }
}

vec3 color(vec3 z, float t) {
    float coh = 0.0;
    bool fl = false;
    
    float r2;
    for(int i=0;i<40;i++) {
        
        octant1(z, coh, fl);
        z -= vec3(s,s,0);
        r2 = dot(z,z);
        if (r2 < s * s) {
            z *= s * s / r2;
            fl = !fl;
            coh = 1.0-coh;
        }
        z += vec3(s,s,0);
        
        
        octant1(z, coh, fl);
        
        r2 = dot(z,z);
        if (r2 < s*s) {
            z *= s * s / r2;
        }
        z.y -= s + 1.0;
        if (dot(z,z) < 1.0) {
            z /= dot(z,z);
        }
        z.y += s + 1.0;
        
        z.x -= s + 1.0;
        if (dot(z,z) < 1.0) {
            z /= dot(z,z);
        }
        z.x += s + 1.0;
        
    }
    octant1(z, coh, fl);
    if (fl) {coh = -coh;}
    coh -= t * 3.0;
    coh = coh / (1.5 + abs(coh));
    return vec3(0.5 + coh * 0.45);
}

void main(void) {
    vec2 uv = 2.0 * (gl_FragCoord.xy - resolution.xy * 0.5)/resolution.y;
    float ds = 2.0 / resolution.y;
    
    float period = 4.2549485065150545;
    float t = time * 0.5;
    bool r = false;
    
    while (t > period * 0.5) {
        t -= period;
        float c = 0.766311365; float s = -0.64246936;
        uv = vec2(uv.x * c - uv.y * s, uv.x * s + uv.y * c);
        //r = !r;
    }
    
    vec3 z = vec3(uv,ds); z*=3.5;
    z *= exp(-t); ds *= exp(-t);
    
    z += vec3(0.25262046414724887,-1.0187347727326157,0);
    z /= dot(z,z);
    z += vec3(0.22732631827540598,0.4228686518338363,0);

    glFragColor = vec4(color(z, t/period),1.0);
    glFragColor = pow(glFragColor, vec4(1./2.2));
}
