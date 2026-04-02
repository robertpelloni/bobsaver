#version 420

// original https://www.shadertoy.com/view/MlXBzf

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Created by Stephane Cuillerdier - Aiekick/2017 (twitter:@aiekick)
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
// link : https://www.shadertoy.com/view/MlXBzf

void main(void)
{
    vec2 p = (gl_FragCoord.xy * 2. - resolution.xy) / resolution.y * 0.75;
    
    float r = 0.5;
    
    float d = dot(p,p) - r * r;
    
    r *= 0.99;
    
    float ratio = sin(time) * 0.5 + 0.5; //uSlider
    
    // offset / radius
    float slid = ratio * r;
    float islid = (1. - ratio) * r;
    
    // for using dot instead of length
    float slid2 = slid * slid;
    float islid2 = islid * islid;
    
    float x = p.x;  
    //float y = p.y + slid - islid; // limit y

    // black
    vec2 p0 = p + vec2(0, slid);
    float d0 = dot(p0,p0) - islid2;
    float c0 = step(d0, 0.);
    
    // white
    vec2 p1 = p - vec2(0, islid);
    float d1 = dot(p1,p1) - slid2;
    float c1 = step(d1, 0.);
    
    // black button
    float d2 = d0 + islid2 * 0.9;
    float c2 = step(d2, 0.);
    
    // white button
    float d3 = d1 + slid2 * 0.9;
    float c3 = step(d3, 0.);

    // x inv without buttons
    d *= sign(x - c2 + c3);
    float c = smoothstep(0.,.01,d);
    
    // compos
    glFragColor = vec4(c + c1 - c0 + c2 - c3);
}
