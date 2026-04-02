#version 420

// original https://www.shadertoy.com/view/3lfGzf

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define N(h) fract(sin(vec4(6,9,1,0)*h))

void main(void)
{
  vec4 o = vec4(0.0,0.0,1.0,0.0); 
  vec2 uv = gl_FragCoord.xy/resolution.y;
    
  float e, d, i=0.2;
  vec4 p;
    
  for(float i=1.0; i<9.9; i++) {
    d = floor(e = i*9.1+time);
    p = N(d)+.13;
    e -= d;
    for(float d=0.; d<15.;d++)
      o += p*(2.9-e)/1e3/length(uv-(p-e*(N(d*i)-.5)).xy);  
  }
     
  glFragColor = vec4(o.rgb, 1);
}
