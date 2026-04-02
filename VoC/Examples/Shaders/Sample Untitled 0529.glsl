#version 420

// original https://www.shadertoy.com/view/tlyXDc

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float rand(vec2 co){
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy / 20.0;
    uv -= time * 0.3;
    vec2 s = uv;
    vec2 g  = fract(s) - 0.5;
    float off = rand(ceil(s));
    float z = rand(ceil(s))*0.5;
    float dir = off - 0.5;
    float speed = 1.0 + rand(s)*0.5;
    float t = time * dir;
    float angle = 1.1 + t*7.0 + off ;
    g += vec2(sin(angle),cos(angle)) * 0.3;
    float d = length(g)*2.5;
    float w = (sin(z+t)+1.0)*0.24;
    float e = 1.0-smoothstep(d,d+0.1,w);
    glFragColor = vec4(e);
}
