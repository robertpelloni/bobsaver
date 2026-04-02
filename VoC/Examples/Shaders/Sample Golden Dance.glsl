#version 420

// original https://www.shadertoy.com/view/sdGXDK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Code by Flopine

// Thanks to wsmind, leon, XT95, lsdlive, lamogui, 
// Coyhot, Alkama,YX, NuSan, slerpy, wwrighter 
// BigWings, FabriceNeyret and Blackle for teaching me

// Thanks LJ for giving me the spark :3

// Thanks to the Cookie Collective, which build a cozy and safe environment for me 
// and other to sprout :)  
// https://twitter.com/CookieDemoparty

// Based on BigWings tuts ~ https://youtu.be/2dzJZx0yngg

#define PI acos(-1.)
#define rot(a) mat2(cos(a),sin(a),-sin(a),cos(a))

#define circle(uv,s) (length(uv)-s)
#define AAstep(thre, val) smoothstep(-.7,.7,(val-thre)/min(0.07,fwidth(val-thre)))

void mo(inout vec2 p, vec2 d)
{
  p=abs(p)-d;
  if(p.y>p.x)p=p.yx;
}

float box2d (vec2 p, float c)
{
  vec2 q = abs(p)-c;
  return min(0.,max(q.x,q.y))+length(max(q,0.));
}

float tore (vec3 p, vec2 r)
{
  vec2 q = vec2(length(p.xz)-r.y,p.y);
  float a = atan(p.z,p.x);

  q *= rot(a*2.);
  mo(q,vec2(.2,.4));

  return box2d(q,r.x*(sin(a+time*2.)/(2.*PI)))-0.02;
}

float SDF (vec3 p)
{
  p.yz *= rot(-atan(1./sqrt(2.)));
  p.xz *= rot(PI/4.);

  float d = tore(p,vec2(.7,1.5));
  return d;
}

vec3 gn (vec3 p)
{
  vec2 eps=vec2(0.001,0.);
  return normalize(SDF(p)-vec3(SDF(p-eps.xyy),SDF(p-eps.yxy),SDF(p-eps.yyx)));
}

float background (vec2 uv)
{
    float offset=(uv.x<0.)?-.5:.5;
    uv.x = abs(uv.x)-1.;
    float f = AAstep(0.008,abs(uv.x));
    f *= AAstep(0.005,abs(circle(uv+vec2(0.,offset),0.45))*abs(circle(uv-vec2(0.,offset),0.25)));
    return 1.-clamp(f,0.,1.);
}

void main(void)
{
  vec2 uv = (2.*gl_FragCoord.xy-resolution.xy)/resolution.y;
 
  vec3 ro=vec3(uv*2.,-40.),rd=vec3(0.,0.,1.),p=ro,c=vec3(background(uv)),l=vec3(1.,2.,-2.);

  bool hit = false;
  for(float i=0.;i<100.;i++)
  {
    float d = SDF(p);
    if (d<0.001)
    {hit=true;break;}
    p += d*rd*.6;
  }

  if (hit)
  {
    vec3 n = gn(p);
    float light = max(dot(n,normalize(l)),0.);
    c = mix(vec3(.3,0.,0.),vec3(1.,.9,0.),light);
    float spec = pow(dot(n,normalize(l-rd)),8.);
    c += spec*vec3(0.99,0.8,0.7);
  }
  
  glFragColor = vec4(sqrt(clamp(c,.0,1.)), 1.0);
}
