#version 420

// original https://www.shadertoy.com/view/XllGDH

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// yeah, spring is due
//
// For-fun entry for the 2 Tweets Challenge
// (c) stefan berke
// 
// credits to Kali for the magic formula
// can not stop using it...
//
void main(void)
{
    float t = time/11.;
    vec2 uv = (.2 + .05 * sin(t*1.1)) * gl_FragCoord.xy / resolution.y + .2 * vec2(2.2+1.*sin(t), .4+.4*cos(t*.9));
    
    for (int i=0; i<11; ++i)
        uv = abs(uv) / dot(uv,uv) - vec2(.81-.1*uv.y);
    
    glFragColor = vec4(uv*uv, uv.y-uv.x, 1.);
}
