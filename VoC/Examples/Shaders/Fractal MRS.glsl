#version 420

// original https://www.shadertoy.com/view/4lSSRy

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// by Nikos Papadopoulos, 4rknova / 2015
// Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

void main(void)
{
    vec2 uv = .275 * gl_FragCoord.xy / resolution.y;
    float t = time*.03, k = cos(t), l = sin(t);        
    
    float s = .2;
    for(int i=0; i<64; ++i) {
        uv  = abs(uv) - s;    // Mirror
        uv *= mat2(k,-l,l,k); // Rotate
        s  *= .95156;         // Scale
    }
    
    float x = .5 + .5*cos(6.28318*(40.*length(uv)));
    glFragColor = vec4(vec3(x),1);
}
