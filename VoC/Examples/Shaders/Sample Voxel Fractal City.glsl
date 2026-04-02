#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/ftsGDl

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
vec4 c=glFragColor;
ivec3 b;float d=9.;
for(;(b.x&=b.z-99&b.y^b.x&b.y)%99>b.z-99;)
b=ivec3(gl_FragCoord.xy/resolution.y*2.*d-d+time*vec2(9,81),d++);
c=sin(c=vec4(b%3,b)).w*.5+ c*3e3/d/d;
glFragColor=c;
}
