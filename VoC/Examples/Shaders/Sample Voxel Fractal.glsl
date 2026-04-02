#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/NlB3Rz

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void) //WARNING - variables void (out vec4 c, vec2 p) need changing to glFragColor and gl_FragCoord.xy
{
  vec4 c=glFragColor;
  for
  ( 
    ivec3 a; 
    (a.x^a.y&a.z)%500 > a.z - 64;
    a = ivec3( 2.*gl_FragCoord.xy/resolution.y*c.a - c.a + time*1e2, ++c.a )
  )
  c += c.a/8e4;
  glFragColor=c;
}
