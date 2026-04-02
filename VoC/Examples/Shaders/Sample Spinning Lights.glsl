#version 420

// original https://www.shadertoy.com/view/stsyzs

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// A shader by Nicole Vella. (2022)
// @nicole.vella.art
// www.nicolevella.com
//
// Attribution 4.0 International (CC BY 4.0)
// This work is licensed under a Creative Commons Attribution 4.0 International License. 
// http://creativecommons.org/licenses/by/4.0/

#define NUM_LIGHT 11.
#define BRIGHTNESS 0.05
#define TAU 6.283185

float Light(vec2 uv, vec2 pos, float s) {
    float d = length(uv-pos);
    return s/d;
}

void main(void) {
    vec2 p = (2.0*gl_FragCoord.xy-resolution.xy)/min(resolution.x,resolution.y);
    vec3 c = vec3(0.0);
    float t = time*.5;
    
    for (float i = 0.; i < NUM_LIGHT; i++) {
    
        // id
        float j = i/NUM_LIGHT;
        
        // radius
        float r = cos(t)*.375+.5;
        
        // blink
        float b = floor(t+j);
        
        // hue
        vec3 h = sin(vec3(0.3,0.1,0.2)*b*TAU)*.25+.5;
        
        // animation
        vec2 a = vec2(cos(j*TAU+t)*r,sin(j*TAU+t)*r);
        
        c += vec3(Light(p,a,BRIGHTNESS))*h;
        
    }
       
    glFragColor = vec4(c,1.0);
    
}
