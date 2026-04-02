#version 420

// original https://www.shadertoy.com/view/WdjGDt

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// based on this tutorial: https://www.youtube.com/watch?v=8--hS-PhRz8

#define PI 3.14159265359

float def(vec2 uv, float f) {

    float n = 10.; 
    float e = 0.0;
    
    for(float i=0.; i<n; i++) {
        // center
        vec2 p = vec2(.5, i/n+.5) - uv;
        // radius
        float rad = length(p)*1.;
        // angle
        float ang = atan(p.x, p.y);
    
        e += sin(rad*10.+f+time);
        e += sin(e*PI+sin(ang+e+time*.5))*.7;
    }
    
    e /= n/4.;
    
    return abs(e);
}

void main(void) {
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;

    // center
    vec2 p = vec2(.5) - uv;
    // radius
    float rad = length(p)*1.;
    // angle
    float ang = atan(p.x, p.y);
    
    //shape
    float e = def(uv, 0.);
    float e2 = def(uv, PI/6.);
    
    // colors
    vec4 c1 = vec4(1., .3, .01, 1.);
    vec4 c2 = vec4(.01, .7, 1., 1.);
    
    // final color
    vec4 color = vec4(e)*c1*c1.a+vec4(e2)*c2*c2.a;

    // Output to screen
    glFragColor = color;
}

