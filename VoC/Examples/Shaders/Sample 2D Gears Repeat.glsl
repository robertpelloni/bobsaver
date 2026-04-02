#version 420

// original https://www.shadertoy.com/view/Mdy3Wz

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Created by Stephane Cuillerdier - @Aiekick/2016
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
// Tuned via XShade (http://www.funparadigm.com/xshade/)

// inversion for each range
#define y(a) sign(mod(floor(a), 2.) *.5 - .1)

#define pi 3.14159

// gear quadrant
float k(vec2 g, float a)
{
    float t = time * y(g.y) * y(g.x) * (a==.5||a==1.5?-5.:5.) + 1.565;
    vec2 cs = vec2(cos(a*pi), sin(a*pi));
    g = abs(fract(g * mat2(cs.x,-cs.y,cs.y,cs.x))) * .123;
    a = min(max(.015*(cos(atan(g.x, g.y)*8.+t))+.06,.05),.07);
    return smoothstep(a, a+0.001, length(g)) * .25;
}

void main(void)
{
    vec2 Coord=gl_FragCoord.xy;    

    Coord /= resolution.y * .3;
    
    glFragColor = vec4(0.0);
    glFragColor = glFragColor - glFragColor + k(Coord, 0.) +  k(Coord, .5) + k(Coord, 1.) +k(Coord, 1.5);
}
