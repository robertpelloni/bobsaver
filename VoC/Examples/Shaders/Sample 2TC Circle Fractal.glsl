#version 420

// original https://www.shadertoy.com/view/ltl3WH

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Circles Fractal 2 [2TC 15]
// By Yakoudbz
// inpired by https://www.shadertoy.com/view/XllGDH
//
// 2 tweet challenge : https://www.shadertoy.com/view/4tl3W8

// I realised after my belgian flag https://www.shadertoy.com/view/MdSSzV
// was also a able to compete in the 2TC 15 ^^

void main(void)
{
    float x = .6 + cos(.7*time*.1)*.5;

    vec2 uv = gl_FragCoord.xy / resolution.y - .5*vec2(sin(x*5.),cos(x*11.));
    
    for(int i=0; i<10; i++)
        uv = abs(uv)/dot(uv,uv) - x;
    
    glFragColor = vec4(uv,uv.y-uv.x,1.);
}
