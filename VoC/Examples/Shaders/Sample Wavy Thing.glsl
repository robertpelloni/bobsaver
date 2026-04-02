#version 420

// original https://www.shadertoy.com/view/Wl2yDW

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float PI = 3.141592653;
mat2 r2d(float a){float cosa = cos(a);float sina = sin(a);return mat2(cosa,sina,-sina,cosa);}

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
float sdloz(vec2 p, float r)
{
  return lenny(p)-r;
}

float sdf_sin(vec2 p, float freq, float amp, float th)
{
  return sub(p.y - sin(p.x*freq)*amp, p.y - sin(p.x*freq)*amp+th);
}

float cir(vec2 p, float r)
{
  float a =p.x;// atan(p.y,p.x)+r*sin(2.*r+time*.1);
  return p.y-sin(a*7.-time)*.15
  +sin(a*3.-time)*.2
  +sin(a*5.+sin(a))*.02;
}

float border(vec2 p, float th, float r)
{
  return sub(cir(p,r),cir(p+vec2(0.,th),r));
}
vec3 rdr(vec2 uv)
{
  vec2 ouv = uv;
  uv-= vec2(0.,.7);
  vec3 col;
  int i = 0;
  while (i<32)
  {
    float fi = float(i);
    col += vec3(sat(pow(abs(uv.y),4.))*2.,.8,sat(abs(uv.x)+.5))*(1.-sat(border(uv+vec2(0.,fi*.2),0.02*fi, .8+fi)*100.));
    ++i;
  }

  return col;
}

void main(void) {
  vec2 uv = gl_FragCoord.xy / resolution.xx;
uv -= vec2(.5)*resolution.xy/resolution.xx;
uv*=6.;

vec3 col = rdr(uv)+(rdr(uv*vec2(.5,1.)))*.2;

if (abs(uv.x)<1.5)
col = 1.-col;
  glFragColor = vec4(col, 1.0);
}
