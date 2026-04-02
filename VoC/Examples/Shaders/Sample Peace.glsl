#version 420

// original https://www.shadertoy.com/view/ls2cWh

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Original shader is taken from here https://www.shadertoy.com/view/XdXyDr
void main(void)
{
    vec2 U = gl_FragCoord.xy / resolution.y-0.5;
    vec4 O=vec4(0.0,0.0,0.0,1.0);
    O += 1. - O
       - .03/abs(length(U) -.47)
       - .03/abs(U.x)
       - (length(U) < .5 ? .03/abs(abs(U.x)+U.y): 0.)
        ;
    glFragColor=O;
}
