#version 420

// original https://www.shadertoy.com/view/3scXzn

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    vec2 uv = (gl_FragCoord.xy*2.-resolution.xy)/min(resolution.x, resolution.y);
    uv *= 5.;
    float f = smoothstep(-.4,.4,sin(atan(uv.y, uv.x)*4.-length(uv)*5. +time) + sin(length(uv)+time));
    f = 1.- abs(f-1.)*10.0;
    glFragColor = vec4(f,f,f,1);
}
