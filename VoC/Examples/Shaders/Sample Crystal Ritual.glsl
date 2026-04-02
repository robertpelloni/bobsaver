#version 420

// original https://www.shadertoy.com/view/fstGRX

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define rot(a) mat2(cos(a),-sin(a),sin(a),cos(a))

float t;
vec3 glw = vec3(0);

float bx(vec3 p, vec3 s)
{
  vec3 q=abs(p)-s;
  return min(max(q.x,max(q.y,q.z)), 0.) + length(max(q,0.));
}

float cy(vec3 p, float r)
{
  return length(p.xz)-r;
}

vec2 mp(vec3 p)
{
  vec3 pp = p;
  float fb = sin(t)*0.5+0.5;//texture(texFFTSmoothed,0.1).x * 300. + texture(texFFTSmoothed,0.99).x * 300.;
  float tt = t + fb*0.6;
  float g = length(pp) - fb*2.;
  glw +=0.01/(0.01+g*g)*vec3(0.4,0.1,0.9);
  
  for(float i=0.;i<4.;i++)
  {
     pp.xy=abs(pp.xy)-1.2 - fb*0.5;
     pp.xy *= rot(tt + i);
     pp.yz *= rot(i);
     pp.z += fb;

  }
  vec2 b = vec2(bx(pp, vec3(1.)) - 0.1, 1.);
  pp=p;
  
  pp.xz *= rot(t/10.);
  pp.xz=abs(pp.xz)-9.;
 
  vec2 c = vec2(cy(pp,1.),2.);
  pp.y*=sin(t/3.);
  g = length(pp.xz) * 0.85;
  glw += 0.01/(0.01+g*g)*mix(vec3(0.1,0.0,0.9), vec3(0.9,0.0,0.1), (pp.y+10.)/20.);
  c.x = min(c.x, -abs(p.y) + 15.);
  
  return b.x < c.x ? b : c;
} 

vec2 tr(vec3 ro,vec3 rd,float x)
{
  vec2 d = vec2(0);
  for(int i = 0; i < 256; i++)
  {
    vec3 p=ro+rd*d.x;
    vec2 s=mp(p);s.x*=x;
    d.x+=s.x;d.y=s.y;
    if(d.x>64.||s.x<0.001)break;
  }
  if(d.x>64.)d.y=0.;return d;
}

vec3 nm(vec3 p)
{
  vec2 e = vec2(0.001,0); return normalize(mp(p).x-vec3(mp(p-e.xyy).x,mp(p-e.yxy).x,mp(p-e.yyx).x));
}

vec4 px(vec4 h, vec3 rd, vec3 n)
{
  vec4 b=vec4(0,0,0,1);
  if(h.a==0.)return vec4(b.rgb,1.);
  vec4 a=h.a == 1. ? vec4(cos(t)*0.5+0.5,0.1,0.3, 0.2) : vec4(0.,0.,0.,0.8);
  float d=dot(n,-rd);
  float dd=max(d,0.);
  float f=pow(1.-d,4.);
  float s=pow(abs(dot(reflect(rd,n),-rd)),40.);
  return vec4(a.rgb*(dd+f)+s,a.a);
}

void main(void)
{
  t=time;
  vec2 uv = vec2(gl_FragCoord.xy.x/resolution.x, gl_FragCoord.xy.y/resolution.y);
  uv-=0.5;uv/=vec2(resolution.y/resolution.x,1);
  vec3 ro = vec3(0, 0, -30),rd=normalize(vec3(uv + vec2(0, 0),1.)),
  oro=ro,ord=rd,cn,cp,cc;float ts=1.;
  for(int i=0;i<4;i++)
  {
    vec2 f=tr(oro,ord,1.);
    cp=oro+ord*f.x;cn=nm(cp);
    vec4 c=px(vec4(cp,f.y),ord,cn);
    if(f.y==0.||c.a==1.){cc=mix(cc,c.rgb,ts);break;};
    ro=cp-cn*0.01;rd=refract(ord,cn,1./1.3);
    vec2 z=tr(ro,rd,-1.);
    cp=ro+rd*z.x;cn=nm(cp);
    oro=cp+cn*0.01;ord=refract(rd,-cn,1.3);
    if(dot(ord,ord)==0.)ord=reflect(rd,-cn);
    cc=mix(cc,c.rgb,ts);ts-=c.a;
    if(ts<=0.)break;
  }
  glFragColor=vec4(cc + glw,1);
}
