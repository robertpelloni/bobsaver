#version 420

// original https://www.shadertoy.com/view/WdV3R3

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    vec2 uv = (gl_FragCoord.xy * 2.0 - resolution.xy)/min(resolution.x, resolution.y);
    
    float a = atan(uv.y, uv.x);
    float l = log(length(uv)) * 10.0 - time * 2.0;
    
    glFragColor = vec4(sin(l + cos(a * 5.0) * 0.5 + a) * 0.5 + 0.5);
}
