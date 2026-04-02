#version 420

// original https://www.shadertoy.com/view/wdlfD2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Copyright 2020 Google LLC
// SPDX-License-Identifier: Apache-2.0
// NOT an official Google project; see Google Open Source guidelines for more info on copyright transfer
// written by William Cadegan-Schlieper 
#define swap(sigma) {for(int k=0;k<6;k++) {int temp = curr[k]; curr[k]=curr2[sigma[k]]; curr2[sigma[k]]=temp;}}
#define swap2(i,j) {int temp = curr[i]; curr[i]=curr[j]; curr[j]=temp;}

bool flip(inout vec3 z, inout float ds, in vec2 c, in float r, inout float t) {
    z -= vec3(c,0.0);
    bool res = (dot(z,z) < r*r) ^^ (r < 0.0);
    if (res) {
        ds *= r * r / dot(z,z);
        z *= r * r / dot(z,z);
    }
    t = min(1.0, (dot(z,z)-r*r)/(2.0 * r * ds));
    z += vec3(c,0.0);
    return res;
}

void main(void)
{
    float phi = 0.5 + sqrt(1.25);
    vec2 c3 = vec2(phi, phi*phi);
    float r3 = 2.0 * phi;
    float r4 = 2.0 / (sqrt(3.0*phi-1.0)-phi*phi);
    vec2 c4 = vec2(0.0, 0.5*r4);
    
    vec3[6] cols = vec3[](
        vec3(1.0,0.5,0.0),
        vec3(0.5,1.0,0.0),
        vec3(0.0,1.0,0.5),
        vec3(0.0,0.5,1.0),
        vec3(0.5,0.0,1.0),
        vec3(1.0,0.0,0.5));
    
    int[6] curr = int[](0,1,2,3,4,5);
    int[6] curr2 = int[](0,1,2,3,4,5);
    
    int[6] sigma1 = int[](0,1,2,3,4,5);
    int[6] sigma2 = int[](0,3,4,1,2,5);
    int[6] sigma3 = int[](0,1,2,4,5,3);
    int[6] sigma4 = int[](1,0,2,3,5,4);
    
    vec2 z = 2.0 * (gl_FragCoord.xy - resolution.xy * 0.5)/resolution.y;
    float ds = 2.0 / resolution.y;
    z *= 6.0; ds *= 6.0;
    vec3 zh = vec3(z, 1.0);
    
    float period = 0.6149689755422006;
    float d = time * 0.2;
    while (d > period * 0.1) {
        float c = -0.8861114478828093; float s = -0.4634722234730269;
        zh.xy = vec2(zh.x * c - zh.y * s, zh.x * s + zh.y * c);
        d -= period;
        swap2(0,1); swap2(3,4); swap2(1,3); swap2(2,4); 
    }
    curr2 = curr;
    
    
    zh *= exp(-d); ds *= exp(-d);
    zh += vec3(0.09504814910742845,0.19915381513146063,0.0);
    zh /= dot(zh, zh); ds *= dot(zh, zh);
    zh -= vec3(0.9759259749906782,2.0448518254217527,0.0);
    
    float t = 1.0;
    bool fl = false;
    
    for (int i=0; i<15; i++) {
        if (zh.x < 0.0) {
            zh.x = -zh.x;
            fl = !fl;
            swap(sigma1);
        }
        if (zh.y < 0.0) {
            zh.y = -zh.y;
            fl = !fl;
            swap(sigma2);
        }
        
        float throwaway;
        if (flip(zh, ds, c3, r3, throwaway)) {
            fl = !fl;
            swap(sigma3);
        }
        if (flip(zh, ds, c4, r4, t)) {
            fl = !fl;
            swap(sigma4);
        }
    }

    t = (1.0 - t) * 0.5;
    vec3 col1 = cols[fl ? curr[0] : curr2[0]];
    swap(sigma4);
    vec3 col2 = cols[fl ? curr2[0] : curr[0]];
    vec3 col = col1 * (1.0-t) + col2 * t;

    glFragColor = vec4(col,1.0);
    glFragColor = pow(glFragColor, vec4(1.0/2.2));
}
