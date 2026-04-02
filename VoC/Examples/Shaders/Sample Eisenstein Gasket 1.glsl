#version 420

// original https://www.shadertoy.com/view/Ws2fDV

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Copyright 2020 Google LLC
// SPDX-License-Identifier: Apache-2.0
// NOT an official Google project; see Google Open Source guidelines for more info on copyright transfer
// written by William Cadegan-Schlieper 
#define swap(u,v) {int t=sigma[u]; sigma[u]=sigma[v]; sigma[v]=t;}

void main(void)
{
    vec2 z = 2.0 * (gl_FragCoord.xy - resolution.xy * 0.5)/resolution.y;
    float res = 1.0 / resolution.y;
    vec3 zh = vec3(z, res);
    
    vec2[3] lines = vec2[](
        vec2(1.0,0.0),
        vec2(-0.5,sqrt(0.75)),
        vec2(-0.5,-sqrt(0.75)));
    zh *= 3.0;
    float t = 0.2 * time;
    t = mod(t, sqrt(3.0) * 2.0);
    zh += t * vec3(sqrt(0.75), 0.5, 0.0);
    
    vec3[3] colors = vec3[](
        vec3(1.0,0.2,0.2),
        vec3(0.2,1.0,0.2),
        vec3(0.0,0.0,0.0));
    
    int[5] sigma = int[](0,1,2,3,4);
    
    int i;
    int br = 2;
    float err = 2.0;
    for(i=0; i<50; i++) {
        if (dot(zh,zh) < 1.0) {
            zh /= dot(zh,zh);
            swap(0,4);
            if (sigma[0]+sigma[4]==4) {
                br = sigma[0];
                err = (dot(zh,zh)-1.0)/(2.0 * zh.z);
                break;
            }
        }
        for(int j=0; j<3; j++) {
            if (dot(zh.xy, lines[j])>0.5) {
                zh.xy = zh.xy - 2.0 * lines[j] * (dot(zh.xy, lines[j]) - 0.5);
                swap(0,j+1);
                if (sigma[0]+sigma[j+1]==4) {
                    br = sigma[0];
                    err = (0.5 - dot(zh.xy, lines[j]))/zh.z;
                    break;
                }
            }
        }
        if (br != 2) {
            break;
        }
    }

    if (br > 2) {br = 4 - br;}
    vec3 col = colors[br] * min(err, 2.0) * 0.5;
    
    glFragColor = vec4(col,1.0);
    glFragColor = pow(glFragColor, vec4(1.0/2.2));
}
