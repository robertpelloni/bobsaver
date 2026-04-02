#version 420

// original https://www.shadertoy.com/view/4tBfRh

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Created by Stephane Cuillerdier - Aiekick/2017 (twitter:@aiekick)
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

// new base code for the quad template of SoShade :)
void main(void)
{
    // central coord
    vec2 uv = (gl_FragCoord.xy * 2. - resolution.xy) / resolution.y;
    
    // fracted length
    float d = abs(fract(dot(uv, uv) - time * 0.5) - 0.5) + 0.3;
    
    // fracted angle
    float a = abs(fract(atan(uv.x,uv.y) / 6.283 * 5.) - 0.5) + 0.2;
    
    //only waves
    //glFragColor = vec4(d * vec3(0.2, 1.0, 0.6), 1.0);
    
    //only rays
    //glFragColor = vec4(a * vec3(0.2, 0.8, 0.5), 1.0);
    
    // mixed
    if (a < d) // inverted shape => (a > d)
        glFragColor = vec4(d * vec3(0.2, 1.0, 0.6), 1.0);
    else
        glFragColor = vec4(a * vec3(0.2, 0.8, 0.5), 1.0);
    
    // another interested things
    //glFragColor = vec4(mix(a * vec3(0.2, 0.8, 0.5),d * vec3(0.2, 1.0, 0.6),d/a), 1.0);
}
