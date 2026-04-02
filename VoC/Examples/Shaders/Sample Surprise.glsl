#version 420

// original https://www.shadertoy.com/view/WdGfzt

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Code by Flopine

// Thanks to wsmind, leon, XT95, lsdlive, lamogui, 
// Coyhot, Alkama,YX, NuSan and slerpy for teaching me

// Thanks LJ for giving me the spark :3

// Thanks to the Cookie Collective, which build a cozy and safe environment for me 
// and other to sprout :)  https://twitter.com/CookieDemoparty

#define TAU 6.283183
#define PI acos(-1.)
#define ITER 64. 

#define dt(sp,off) fract((time+off)*sp)
#define easeout(s,of) easeOutExpo(abs(-1.+2.*dt(s,of)))
#define sw(sp,of,n) floor(dt(sp*(1./n),of)*n)
#define bouncy(s,of) sqrt(abs(sin(dt(s,of)*TAU)))

#define rot(a) mat2(cos(a),sin(a),-sin(a),cos(a))
#define crep(puv,c,l) puv=(puv-c*clamp(round(puv/c),-l,l))
#define pal(t,c,d) (vec3(0.5)+vec3(0.5)*cos(TAU*(c*t+d)))

#define od(puv,d) (dot(puv,normalize(sign(puv)))-d)
#define sphe(puv,d) (length(puv)-d) 

float easeOutExpo (float x)
{return x == 1. ? 1. : 1. - exp2(-10. * x);}

float box (vec3 p, vec3 c)
{
    vec3 q = abs(p)-c;
  return min(0.,max(q.x,max(q.y,q.z)))+length(max(q,0.));
}

float candy; vec2 cid;
float SDF (vec3 p)
{
  p.yz *= rot(-atan(1./sqrt(2.)));
  p.xz *= rot(PI/4.);
  
  int choose = int(sw(0.3,-1.5,3.));
  vec2 per = vec2(1.9);
  
  vec3 ppp = p;
  cid=round(ppp.xy/per); 
  crep(ppp.xy,per,3.);
  if (choose == 0) candy = od(ppp,0.3);
  else if (choose == 1) candy = sphe(ppp,0.3);
  else candy = mix(od(ppp,0.3),box(ppp,vec3(.4)), 0.5);
  
  vec2 id = round(p.xy/per);
  p.z = abs(p.z)-mix(0.0,4.,clamp(easeout(0.3,length(id*0.08))*2.-1.,0.001,1.));

 vec3 pp = p; 
 crep(p.xy,per,3.);
 float d = max(dot(pp,normalize(vec3(0.,0.,-1.))),abs(mix(od(p,0.5),box(p,vec3(.6)), 0.5))-0.04);

  return min(d,candy);
}

vec3 getnorm (vec3 p, vec2 eps)
{return normalize(SDF(p)-vec3(SDF(p-eps.xyy),SDF(p-eps.yxy),SDF(p-eps.yyx)));}

void main(void)
{
  vec2 uv = (2.*gl_FragCoord.xy-resolution.xy)/resolution.y;

  vec3 ro = vec3(uv*8.,-100.), 
  rd=vec3(0.,0.,1.), 
  p=ro, 
  col=vec3(0.0,0.,0.015), 
  l=vec3(1.,-1.5,-2.);

  bool hit = false; float d=0.;
  for (float i=0.; i<ITER; i++)
  {
    d = SDF(p);
    if (d<0.01)
    {
      hit = true;
      break;
    }
    p += d*rd*0.55;
  }

  if (hit)
  {
    if (d==candy) col = pal(length(cid),vec3(0.5),vec3(.0,0.63,0.37)) ;
    else col = vec3(1.);
    vec3 n = getnorm(p,vec2(0.01,0.));
    float light = max(dot(n,normalize(l)),0.);
    col *= mix(vec3(0.3,0.1,0.05),vec3(0.9,0.7,0.2),light);
  }
  glFragColor = vec4(sqrt(col),1.);
}
