#version 420

// original https://www.shadertoy.com/view/ttBcWh

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float PI = 3.141592653;

float lenny(vec2 v)
{
  return abs(v.x)+abs(v.y);
}
float sat(float a)
{
  return clamp(a,0.,1.);
}

float sub(float a, float b)
{
  return max(a,-b);
}

float sdf_sin(vec2 p, float freq, float amp, float th)
{
  return sub(p.y - sin(p.x*freq)*amp, p.y - sin(p.x*freq)*amp+th);
}

float cir(vec2 p, float r)
{
  float a = atan(p.y,p.x)+r*sin(2.*r+time*.1);
  return (length(p)-r)-sin(a*7.-time)*.15
  +sin(a*3.-time)*.2
  +sin(a*5.+sin(a))*.02;
}

float border(vec2 p, float th, float r)
{
  return sub(cir(p,r),cir(p,r-th));
}
vec3 rdr(vec2 uv)
{
  vec3 col;
  int i = 0;
  while (i<32)
  {
    float fi = float(i);
      col += vec3(sat(pow(abs(uv.y),4.))*2.,.8,sat(abs(uv.x)+.5))*(1.-sat(border(uv,0.0005, .8+.02*fi)*80.));
    col += .005*vec3(sat(pow(abs(uv.y),4.))*2.,.8,sat(abs(uv.x)+.5)).yxx*(1.-sat(border(uv*.5*vec2(-1.,1.)*(sin(time*.2)*.5+1.),0.0005, .8+.02*fi)*40.));
    
      ++i;
  }

  return col;
}

vec3 tone(vec3 col, vec2 uv)
{
  vec3 col2 = .7*mix(vec3(.76,.37,.18).zyx,vec3(.54,.85,.23).yzx,sat(.2*length(uv)));
  col *= col2;
  col += col2*.0008;
  col = pow(col,vec3(1./1.8*(sin(time)*.1+.5)));
  return col;
}

void main(void) {
  vec2 uv = gl_FragCoord.xy / resolution.xx;
  uv -= vec2(.5)*resolution.xy/resolution.xx;
  uv*=8.;

  vec3 col = rdr(uv);
  col = tone(col,uv);
  vec3 colMult = mix(vec3(.37,.25,.56).zxy, vec3(.37,.25,.56), sin(time*.5)*.5+.5);
  glFragColor = vec4(col*colMult*3., 1.0);
}
