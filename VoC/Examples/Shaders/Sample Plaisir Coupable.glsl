#version 420

// original https://www.shadertoy.com/view/WtGcDd

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Code by Flopine

// Thanks to wsmind, leon, XT95, lsdlive, lamogui, 
// Coyhot, Alkama,YX, NuSan, slerpy and wwrighter for teaching me

// Thanks LJ for giving me the spark :3

// Thanks to the Cookie Collective, which build a cozy and safe environment for me 
// and other to sprout :)  https://twitter.com/CookieDemoparty

// Heavily inspired by this tweet:
// https://twitter.com/MIRAI_MIZUE/status/1354248578063953920?s=20

#define dt(speed,off) fract((time+off)*speed)
#define IOExpoLoop(speed,off) easeInOutExpo(abs(-1.+2.*dt(speed,off)))
#define IOExpo(speed,off) easeInOutExpo(dt(speed,off))
#define bounce(speed, off) abs(sqrt(sin(dt(speed,off)*PI)))

#define PI acos(-1.)
#define TAU 6.283185
#define ITER 64.

#define rot(a) mat2(cos(a),sin(a),-sin(a),cos(a))
#define crep(p,c,l) p=p-c*clamp(round(p/c),-l,l)

struct obj
{
  float d;
  vec3 c_shadow;
  vec3 c_light;
};

obj minobj (obj a, obj b)
{
  if (a.d<b.d) return a;
  else return b;
}

float easeInOutExpo (float x)
{
return x == 0.
  ? 0.
  : x == 1.
  ? 1.
  : x < 0.5 ? exp2(20. * x - 10.) / 2.
  : (2. - exp2(-20. * x + 10.)) / 2.;
}

float box (vec3 p, vec3 c)
{
  vec3 q = abs(p)-c;
  return min(0.,max(q.x,max(q.y,q.z)))+length(max(q,0.));
}

float sc (vec3 p, float d)
{
  p = abs(p);
  p = max(p,p.yzx);
  return min(p.x,min(p.y,p.z))-d;
}

obj prim1 (vec3 p)
{ 
  float per = mix(0.,1.5,IOExpoLoop(0.5,0.));
  crep(p.xz,per,1.);
  float dscene = max(sc(p,0.2),box(p,vec3(0.5)));

  return obj(dscene,vec3(0.15,0.,0.2),vec3(.3,0.8,0.95));
}

float cases (vec3 p, float offset, float size)
{
  p.y -= bounce(1.5,offset)*1.5;
  float d = max(-box(p-vec3(0.,size*0.25,0.),vec3(size*0.85)),box(p,vec3(size)));
  return d;
}

obj prim2 (vec3 p)
{
  float off=0.,s=0.9,d=1e10;
  for (int i=0; i<3; i++)
  {
    d = min(d,cases(p,off,s));
    off -= 0.1; s -= 0.3;
  }

  return obj(d,vec3(0.3,0.02,0.01),vec3(0.95,0.8,0.4)); 
}

obj prim3 (vec3 p)
{
  float size = 1., d=1e10;
  for (int i=0;i<3;i++)
  {
    p.xz *= rot(IOExpo(0.5,0.)*PI);
    p.xy *= rot(IOExpo(0.5,0.)*PI);
    d = min(d,max(-sc(p,size*0.8),box(p,vec3(size))));
    size -= 0.3;
  }

  return obj(d,vec3(0.0,0.2,0.05),vec3(.9,.8,0.1));
}

obj prim4 (vec3 p)
{
  float size = 0.2;
  float per = (size*4.);
  vec2 id = round(p.xz/per)-.5;
  crep(p.xz,per,2.);

  float sy = sin(length(id*0.7)-dt(0.5,0.)*TAU)*0.3+0.3;

  float d = box(p,vec3(size,sy,size));

  return obj(d,vec3(0.5,0.,0.6),vec3(0.95,0.85,0.2));
}

obj SDF (vec3 p)
{  
  p.x -= 0.5;
  p.yz *= rot(-atan(1./sqrt(2.)));
  p.xz *= rot(TAU/8.);
  vec3 pp = p;

  obj scene = prim1(p+vec3(-2.,0.,2.));
  scene = minobj(scene,prim4(p+vec3(3.,0.,-3.)));
  scene = minobj(scene, prim3(p+vec3(3.,0.,2.)));
  scene = minobj(scene,prim2(p+vec3(-2.,0.,-3.)));

  return scene;
}

vec3 getnorm (vec3 p)
{
  vec2 eps = vec2(0.001,0.);
  return normalize(SDF(p).d-vec3(SDF(p-eps.xyy).d,SDF(p-eps.yxy).d,SDF(p-eps.yyx).d));
}

void main(void)
{
  vec2 uu = gl_FragCoord.xy/resolution.xy;
  vec2 uv = (2.*gl_FragCoord.xy - resolution.xy)/resolution.y;

  vec3 ro = vec3(uv*5.,-10.), rd=vec3(0.,0.,1.), p=ro, col=vec3(0.,0.,0.02), l=normalize(vec3(1.,2.,-2.));

  bool hit = false; obj O;

  for (float i=0.; i<ITER; i++)
  {
    O = SDF(p);
    if (O.d < 0.01)
    {
      hit=true; break;
    }
    p += O.d*rd;
  }

  if (hit)
  {
    vec3 n = getnorm(p);
    float lighting = max(dot(n,l),0.);
    col = mix(O.c_shadow, O.c_light, lighting);
  }

  glFragColor = vec4(sqrt(col),1.);
}
