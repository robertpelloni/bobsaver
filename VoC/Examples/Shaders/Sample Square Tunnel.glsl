#version 420

// original https://www.shadertoy.com/view/4lBfRD

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    vec2 U = gl_FragCoord.xy;
    vec2 R = resolution.xy;
    U = (U+U-R)/R.y;
    float t = .1*(time-9.9), r = 1., c,s;

    vec4 O = glFragColor;    
    O -= O;
    for( int i=0; i< 99; i++)
        U *= mat2(c=cos(t),s=sin(t),-s,c),
        r /= abs(c) + abs(s),
        O = smoothstep(3./R.y, 0., max(abs(U.x),abs(U.y)) - r) - O;
    glFragColor = O;
}
