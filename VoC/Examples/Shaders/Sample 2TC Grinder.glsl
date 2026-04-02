#version 420

// original https://www.shadertoy.com/view/lls3W4

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// [2TC 15] Grinder
// 139 chars (without white space and comments)
// by Andrew Baldwin.
// This work is licensed under a Creative Commons Attribution 4.0 International License.

void main()
{ 
    vec4 c = mod(gl_FragCoord/8.,8.)-4.;
    float a=atan(c.x,c.y)+time;
    glFragColor.x = step(3.,cos(floor(.9+a/.9)*.9-a)*length(c.xy));
}
