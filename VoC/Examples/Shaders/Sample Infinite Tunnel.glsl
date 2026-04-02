#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/tdSyDG

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void) {
  vec3 d=vec3(gl_FragCoord.xy/resolution.xy-.5,.8),
       p=vec3(0,sin(time*12.)/2e2,time),q;
  for(int i=0;i<99;i++){
    p+=d*min(.65-length(fract(p+.5)-.5),p.y+.2);
    if(i==50) {
      q=p,p-=d*.01,d=vec3(.7);
    }
  }
  ivec3 u=ivec3(q*5e2);
  glFragColor=vec4((u.x^u.y^u.z)&255)/3e3*min(length(p-q)+1.,9.)+(p.z-time)*.1;
}
