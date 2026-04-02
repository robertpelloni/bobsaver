#version 420

// original https://www.shadertoy.com/view/7lX3Ds

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// =========================================================================================================
// This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0
// Unported License. To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/3.0/ 
// or send a letter to Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.
// =========================================================================================================

#define sat(a) clamp(a,0.,1.)
mat2 r2d(float a){float ca = cos(a),sa=sin(a);return mat2(ca,-sa,sa,ca);}
#define PI 3.14159265

float _bbox(vec3 p, vec3 s)
{
  vec3 l = abs(p)-s;
  return max(l.x,max(l.y,l.z));
}

vec2 map(vec3 p)
{
  float t = time*.01;
  float shp = -p.y;//-texture2D(noise, p.xz*.01+vec2(sin(t),cos(t))).x*.05;
  p+=vec3(0.,-.75,0.);
  p.yz*= r2d(PI*.2);
  p.xy*= r2d(PI*.25);

  shp = min(shp,_bbox(p,vec3(1.)));
  return vec2(shp,0.);
}

vec3 trace(vec3 ro, vec3 rd, int steps)
{
  vec3 p = ro;
  for (int i = 0; i<steps;++i)
  {
    vec2 res = map(p);
    if (res.x<0.01)
      return vec3(res.x,distance(p,ro),res.y);
    p+= rd*res.x;
  }
  return vec3(-1.);
}

vec3 getCam(vec3 rd, vec2 uv)
{
  float fov = 1.;
  vec3 r = normalize(cross(rd, vec3(0.,1.,0.)));
  vec3 u = normalize(cross(rd,r));
  return normalize(rd+fov*(r*uv.x+u*uv.y));
}

vec3 getNorm(vec3 p, float d)
{
  vec2 e = vec2(0.01,0.);
  return normalize(vec3(d)-vec3(map(p-e.xyy).x,map(p-e.yxy).x,map(p-e.yyx).x));
}

vec3 rdr(vec2 uv)
{
  vec3 col;

  vec3 ro = vec3(0.,-5.,-1.);
  vec3 ta = vec3(0.,0.,0.);
  vec3 rd = normalize(ta-ro);

  rd = getCam(rd,uv);

  vec3 res = trace(ro,rd,32);
  if (res.y>0.)
  {
    vec3 p = ro+rd*res.y;
    vec3 n = getNorm(p,res.x);
    col = n*.5+.5;
    vec3 lpos = vec3(sin(time),-1./3.,cos(time))*10.;
    vec3 ldir = lpos-p;
    vec3 nldir = normalize(ldir);
    vec3 h = normalize(rd-ldir);
    col = vec3(1.)*pow(sat(-dot(n,h)),.75);
    vec3 ressh = trace(p+n*0.02,nldir,64);
    if (ressh.y >0.)
    {

       col*= .75;
    }
    col += vec3(.4,.5,.7)*.5;
    float dao = 0.6;
    col *= sat(pow(sat(map(p+n*dao).x/dao),.5)+.1);
    col+= pow(1.-sat(-dot(rd,n)),.25)*vec3(1.,.5,.7).yzx*.25;
  }
  return col;
}

void main(void) {
  vec2 uv = (gl_FragCoord.xy-vec2(.5)*resolution.xy) / resolution.xx;
  uv *= 2.;
  vec3 col = rdr(uv);
  vec3 o = col;
  vec3 inv = 1.-sat(col.zyx);
  inv = mix(inv,1.-inv,sat((uv.x-uv.y+sin((uv.y+uv.x)*5.+time*2.)*.1)*400.));
  col = mix(col,inv,1.-sat((sin((uv.y+uv.x)*20.)+.4)*400.));
  col = pow(col,vec3(.5));
  col = mix(col,o,sat((length(uv)-.4)*400.));
  glFragColor = vec4(col, 1.0);
}
