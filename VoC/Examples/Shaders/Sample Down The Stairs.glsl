#version 420

// original https://www.shadertoy.com/view/4dlBW2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    vec2 R = resolution.xy;
    vec2 u = (gl_FragCoord.xy*2.-R)/R.x;
    float t = fract(time);
    glFragColor += min(length(u+vec2(0,pow(t*2.-max(t*4.-2.,0.), 2.)*.27))-.04, u.y+floor(u.x*2.+t)*.2-t*.2+.4)*length(R*.2)-glFragColor;
}
