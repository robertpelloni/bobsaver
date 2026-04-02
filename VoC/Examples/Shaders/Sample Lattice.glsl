#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/st2GWD

uniform int frames;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    vec2 I=gl_FragCoord.xy;
    glFragColor = fwidth(vec4(int(++I)^int(I.y)+frames*2))/64.;
}
