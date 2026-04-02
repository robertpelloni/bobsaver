#version 420

// original https://www.shadertoy.com/view/ls3BW2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.1415926
#define TAU 2.*PI
#define ss(a,b,c) smoothstep(a,b,c)
#define sat(a) clamp(a,0.,1.)
#define sat3(a) clamp(a,vec3(0.),vec3(1.))
#define rnd(t) (fract(sin(t*427.)*1789.))
#define rnd4(t) vec4(fract(sin(t*427.)*651.),fract(sin(t*273.)*1741.),fract(sin(t*721.)*1393.),fract(sin(t*913.)*597.))

struct ray { vec3 o,d; };
ray makeray(vec2 uv, vec3 o, vec3 d) {
  vec3 z=normalize(d-o),x=cross(vec3(0,1,0),z),y=cross(z,x),c=o+z*1.5,i=c+uv.x*x+uv.y*y;
  ray a; a.o=o; a.d=normalize(i-o);
  return a;
}
vec3 proj(ray r, vec3 p) { return r.o+r.d*max(dot(p-r.o,r.d),0.); }
float dist(ray r, vec3 p) { return length(p-proj(r,p)); }
float sprite(ray r, vec3 p, float s, float b) { float d=dist(r,p);d=ss(s,s*(1.-b),d)+d*3.*ss(s+b,s-b,d);return d; }
vec3 bobz(ray r) {
  float t=time*0.25;
  vec3 acc=vec3(0.);
  float rd=4.;
  for(float i=0.;i<1.0;i+=.005) {
    float ti=fract(t+i);
    float ph=acos(1.-2.*i);
    float th=PI*(1.+pow(5.,.5))*i*200.;
    vec3 p=vec3(cos(th)*sin(ph),sin(th)*sin(ph),cos(ph));
    p*=vec3(rd*ti*cos(i*TAU)*sin(ti*TAU),rd*ti*sin(i*TAU)*sin(ti*TAU),rd*ti*cos(ti*TAU));
    p*=vec3(sin(ti),cos(ti),1.-ti);
    p*=vec3(sin(cos(t+sin(t))+i*TAU),cos(sin(t+sin(t))+i*TAU),4.);
    acc += vec3(1.-ti,ti,i)*sprite(r,p,.01,.1);
  }
  return acc;
}
vec3 storm(ray r) {
  float t=time*0.5;
  vec3 acc=vec3(0);
  r.d.x = pow(abs(r.d.y), 1.3);
  r.d.y = pow(abs(r.d.x), 1.9);
  r.d.x += 5.1*abs(sin(r.d.x*.5));
  for(float i=0.;i<1.0;i+=.1) {
    if(rnd(i)>.9) continue;
    vec4 rnd=rnd4(i);
    float ti=fract(t+i);
    vec3 p=vec3(2.1+2.1*sin(ti*4.*PI),cos(sin(ti*2.)*4.*PI)*0.9,50.-50.*ti);
    float c = sprite(r,p,.7*ti,.999);
    acc += vec3(1.,.7,.3)*rnd.xyz*c*c*c;
  }
  vec3 a=sat3(pow(acc, vec3(2.)));
  vec3 b=0.05*sat3(pow(acc, vec3(0.2)));
  return sat3(a+b);
}
void main(void)
{
  vec2 uv = gl_FragCoord.xy/resolution.xy;
  uv -= 0.5;
  uv /= vec2(resolution.y / resolution.x, 1);
  vec3 o=vec3(0,0,-3);
  vec3 d=vec3(0);
  ray r=makeray(uv,o,d);
  vec3 p=vec3(0,0,3);
  vec3 c=vec3(0);
  c+=bobz(r);
  c+=storm(r);
  c+=vec3(0,.4,.75)*pow(abs(uv.y),1.2);
  glFragColor = vec4(c,1);
}
