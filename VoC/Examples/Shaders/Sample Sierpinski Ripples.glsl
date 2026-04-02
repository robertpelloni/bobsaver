#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/NdKGWh

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//This little shader is the result of messing around with 
//https://www.shadertoy.com/view/NsKGRh and its shortened version by FabriceNeyret2. 
//It's some twist and rippling applied to a pattern generated from simple integer logic. 
//In its binary version the pattern shows a Sierpinski fractal (see https://www.shadertoy.com/view/wdf3z7).
//Let me know If you have any ideas on how to extend/improve - it's my first shader atempt.

void main(void) { //WARNING - variables void  (out vec4 O, vec2 U){ need changing to glFragColor and gl_FragCoord.xy
  vec2 U = gl_FragCoord.xy;
  float r= length(U-= .5*resolution.xy);
  vec2 m= mouse*resolution.xy.xy/resolution.xy;
  if(m==vec2(0.)){m= vec2(.5,.07);}  // default parameters - better way?  
  U= U*sin(r/exp(5.*m.x) - 6.*time) + 4.*m.y*r;
  glFragColor= sqrt(vec4(int(U.x) & int(U.y))/r);
}

