#version 420

// original https://www.shadertoy.com/view/tlByDw

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//CC0 1.0 Universal https://creativecommons.org/publicdomain/zero/1.0/
//To the extent possible under law, Blackle Mori has waived all copyright and related or neighboring rights to this work.

vec3 erot(vec3 p, vec3 ax, float ro) {
  return mix(dot(p,ax)*ax,p,cos(ro))+sin(ro)*cross(ax,p);
}

float malboge(vec3 p) {
  return dot(sin(p), cos(p));
}

float box(vec3 p, vec3 d) {
  p = abs(p)-d;
  return length(max(p,0.))+min(0.,max(p.x,max(p.y,p.z)));
}

float smin(float a, float b, float k) {
  float h = max(0.,k-abs(b-a))/k;
  return min(a,b) - h*h*h*k/6.;
}
vec3 smin(vec3 a, vec3 b, float k) {
  vec3 h = max(vec3(0),vec3(k)-abs(b-a))/k;
  return min(a,b) - h*h*h*k/6.;
}

float scene(vec3 p) {
  p = erot(p, vec3(0,0,1), sin(p.z*10.)/5.*sin(time)/2.);
  vec3 p2 = p;
  p2.z += malboge(vec3(p.xy*10.+time/4.,0))*.02;
  p2.z += malboge(erot(vec3(p.xy*4.+time/2.,0),vec3(0,0,1),.4))*.06;
  p2.z += malboge(erot(vec3(p.xy*20.+time/2.,0),vec3(0,0,1),.8))*.01;
  
  p += malboge(p*20.)*.005;
  p += malboge(erot(p,normalize(vec3(1,2,3)),.5)*8.)*.01;
  p += malboge(erot(p,normalize(vec3(3,2,1)),.5)*30.)*.005;
  float bx = box(p2,vec3(1,1,.3))-.05;
  p-=vec3(0,0,abs(sin(time))*.7+.5);
  p = erot(p,normalize(vec3(1,2,3)),time);
  float sph = length(-smin(.2-abs(p),vec3(.15),.1)  )-.18;
  return smin(bx,sph,.5);
}

vec3 norm(vec3 p) {
  mat3 k = mat3(p,p,p)-mat3(0.01);
  return normalize( scene(p) - vec3( scene(k[0]),scene(k[1]),scene(k[2])  ));
}

vec4 plas( vec2 v, float time )
{
  float c = 0.5 + sin( v.x * 10.0 ) + cos( sin( time + v.y ) * 20.0 );
  return vec4( sin(c * 0.2 + cos(time)), c * 0.15, cos( c * 0.1 + time / .4 ) * .25, 1.0 );
}

vec3 skycol(vec3 p) {
  
  float s1 = length(sin(p*2.)*.5+.5)/sqrt(3.);
  float s2 = length(sin(p*3.)*.5+.5)/sqrt(3.);
  return pow(vec3(.2,0.1,0.4)*s1 + vec3(.4,0.1,.2)*s2,vec3(4)) + pow(max(dot(p,normalize(vec3(1))),0.),50.);
}

void main(void)
{
  vec2 uv = (gl_FragCoord.xy-resolution.xy*.5)/resolution.y;

  vec3 cam = normalize(vec3(1.5/*+fract(time/60.*26.*6.)/10.*/,uv));
  vec3 init = vec3(-5,0,.3);
  
  float yrot = .6 + sin(time*.3)*.2;
  float zrot = time/3.;
  cam = erot(cam, vec3(0,1,0), yrot);
  init = erot(init, vec3(0,1,0), yrot);
  cam = erot(cam, vec3(0,0,1), zrot);
  init = erot(init, vec3(0,0,1), zrot);
  
  
  vec3 p =init;
  bool hit = false;
  vec3 atten = vec3(1);
  for (int i = 0; i< 150 && !hit; i++) { 
    float dist = scene(p);
    hit = dist*dist < 1e-6;
    
  float thing = fract(dot(vec3(1),p+time/10.));
    if (hit && thing < .5) {
      hit = false;
      dist = .1;
      vec3 n = norm(p);
      atten  *= (1.-abs(dot(n,cam))*.97)*vec3(0.9,0.7,0.5);
      cam = reflect(cam,n);
    }
    p += cam *dist;
  }
  vec3 n = norm(p);
  vec3 r = reflect(cam, n);
  float diff = length(sin(n*2.)*.5+.5)/sqrt(3.);
  float spec = length(sin(r*2.)*.5+.5)/sqrt(3.);
  float fres = 1. - abs(dot(n,cam))*.98;
  vec3 wax = vec3(.9)*diff + pow(spec,10.)*fres;
  mat3 dsat = mat3(.4)+mat3(vec3(.2),vec3(.2),vec3(.2));
  vec3 dope = vec3(0.6,0.25,0.1)*spec*spec*spec*2. + pow(spec,20.)*fres*2.;
  float thing = fract(dot(vec3(1.),p+time/10.));
  vec3 col = mix(dope,wax,step(.5,thing));
  glFragColor.xyz = dsat*dsat*sqrt(hit ? col*atten : skycol(cam)*atten);
}
