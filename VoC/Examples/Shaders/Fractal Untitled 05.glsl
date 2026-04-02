#version 420

// Fractals: MRS
// by Nikos Papadopoulos, 4rknova / 2015
// Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
//
// Adapted from https://www.shadertoy.com/view/4lSSRy by J.

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main( void ) {

    vec2 uv = .987 * gl_FragCoord.xy / resolution.y;
    float t = time*.01125, k = cos(t), l = sin(t);        
    
    float s = .456;
    for(int i=0; i<96; ++i) {
        uv  = abs(uv) - s;    // Mirror
        uv *= mat2(k,-l,l,k); // Rotate
        s  *= 0.963;         // Scale
    }
    
    float x = .5 + .5*cos(6.28318*(337.*length(uv)));
    glFragColor = vec4(vec3(length(uv)*37.0,0.755*x, 0.955/x),0.65);
}
