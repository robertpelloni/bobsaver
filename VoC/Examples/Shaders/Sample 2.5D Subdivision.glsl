#version 420

// original https://www.shadertoy.com/view/dlBBzm

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    vec2 u = gl_FragCoord.xy;
    vec4 O = vec4(0.0);
    
    u /= resolution.xy;         
    O *= 0.;
    O.r++;
    for (float t = .05*time, i; i++ < 6.; u = fract(u+u+.25)) 
        u.x < .5 ? u+=t, O-- : O=-O,
        u.y < .5 ? u-=t, O++ : O--;
        
    glFragColor = O;
}