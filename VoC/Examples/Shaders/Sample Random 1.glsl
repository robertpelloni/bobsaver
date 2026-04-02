#version 420

// simple random function

uniform vec2 resolution;
uniform float time;

out vec4 glFragColor;

float rand(vec2 co){
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

void main(void)
{
    vec2 p = -1.0 + 2.0 * gl_FragCoord.xy / resolution.xy + time;
    glFragColor = vec4(rand(p),rand(p),rand(p),1.0);
}
