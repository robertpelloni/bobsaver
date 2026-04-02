#version 420

// original https://www.shadertoy.com/view/ttjfRt

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define MAX_STEPS 100
#define MAX_DIST 100.
#define SURF_DIST .001
#define pi acos(-1.)
#define tau (2.*pi)
#define T (time*0.125)
#define pal(a,b,c,d,e) (a + b*sin(c*d + e))
#define pmod(p, x) mod(p, x) - 0.5*x
#define lmod(d, x) (mod(d,x)/x - 0.5)

mat2 Rot(float a) {
 float s = sin(a);
 float c = cos(a);
 return mat2(c, -s, s, c);
}

float sdBox(vec3 p, vec3 s) {
 p = abs(p)-s;
 return length(max(p, 0.))+min(max(p.x, max(p.y, p.z)), 0.);
}

vec3 pA = vec3(0);
mat3 rotate( in vec3 v, in float angle)
{
 float c = cos(radians(angle));
 float s = sin(radians(angle));    
 return mat3(c + (1.0 - c) * v.x * v.x, (1.0 - c) * v.x * v.y - s * v.z, (1.0 - c) * v.x * v.z + s * v.y,
 (1.0 - c) * v.x * v.y + s * v.z, c + (1.0 - c) * v.y * v.y, (1.0 - c) * v.y * v.z - s * v.x,
 (1.0 - c) * v.x * v.z - s * v.y, (1.0 - c) * v.y * v.z + s * v.x, c + (1.0 - c) * v.z * v.z
 );
}

vec2 N(float angle)
{
 return vec2(sin(angle),cos(angle));
}
vec3 text(vec2 t, vec3 p){
 vec3 o = vec3(0);
 float d = 10e6;
 t = pmod(t,2./.1);
 t *=.1;
 float yid = (floor( (p.y + 0.)*0. ) );
 float W = 2.;
 float modd = .4;
 float sqD = max(abs(t.y), abs(t.y));
 sqD +=2. + yid*1.;
 float sqid = floor(sqD/modd);
 d = min(d, sqD);
 o +=  pal(.1, vec3(1.,0.7,0.6)*0.5, vec3(8.4 ,4.19,7.4 - yid*0.2), vec3(3.,7.,3.),-1. + time + sqid*0.5 + p.z + t.x*2.5 - t.y*1.5);
 o *= step(sin(sqid*40.), -0.);
 float aa = 20.;
 sqD -= 0.5;
 sqD = abs(sqD*1.);
 o -= exp(-sqD*aa)*1.;
 sqD -= 1.;
 sqD = abs(sqD*1.);
 o -= exp(-sqD*aa)*1.;
 return o;
}

float g1;
float PI = acos(-1.);

float dBox(vec3 p, vec3 s)
{
 return length (max (abs(p)-s,0.));            
}

mat2 rot2d(float a) {
 float c = cos(a), s = sin(a);
 return mat2(c, s, -s, c);
}

vec3 kifs(vec3 p, float s, float tf) {
 float f = sin(time*.25)-6.;
 for (int i = 0; i <4; i++) {
   p.xy *= -rot2d(f);
   p.zy *= rot2d(f);
   p.xz *= rot2d(f);
   p =  (max (abs(p)-vec3(0.05,0.1,0.05),0.));  
  }
  return p;
}

vec3 tex3D(  in vec3 p, in vec3 n ){
 vec2 d =vec2(0.);   
 float dp = dot(p,p*0.1)*.8;
 p = kifs(p, 1., 2.);
 p /= dp;
 p.xy*= Rot(cos(time*.05));
 p = rotate( ( vec3(cos(p.xzy*1.+time*1.) ) ), 300.)*p;
 p.z=sin(p-vec3(-T*tau*1.,-T*tau*2.,-T*tau*1.+sin(time)*1.)).z*.1;
 vec3 q = (text(p.xy, p*1.)).xyz*1.;
 return q;
}

vec2 condmin(in vec2 d1, in vec2 d2) {
return vec2(min(d1.x, d2.x), mix(d1.y, d2.y, step(d2.x, d1.x)));
}

vec2 GetDist(vec3 p) {

 vec2 d =vec2(0.);
 vec3 q = p;   
 float dp = dot(p,p*0.1)*.8;
 p = kifs(p, 1., 2.);
 p /= dp;
 p.xy*= Rot(cos(time*.05));
 p = rotate( ( vec3(cos(p.xzy*1.+time*1.) ) ), 300.)*p;
 p.z=sin(p-vec3(-T*tau*1.,-T*tau*2.,-T*tau*1.+sin(time)*1.)).z*.1;
 d = vec2(sdBox(p,vec3(3.)) + sdBox(q,vec3(0,0.,0.)),1);
 d.x *=1.;
 d.x =(((d.x*dp)/5.));
 g1 +=1./(.000008+pow(abs(d.x),10.));
 d = condmin( d,d);    
 return d;
}

vec2 RayMarch (vec3 ro, vec3 rd) 
 {
 vec2 h, t=vec2( 0.);
 for (int i=0; i<MAX_STEPS; i++) 
  {
     h = GetDist(ro + t.x * rd);
     if(h.x<SURF_DIST||t.x>MAX_DIST) break;
          t.x+=h.x*1.;
          t.y=h.y;
  }
 if(t.x>100.) t.x=0.;
 return t;
}

vec3 GetNormal(vec3 p){
vec2 e = vec2(.00035, -.00035); 
return normalize(
 e.xyy * GetDist(p + e.xyy).x + 
 e.yyx * GetDist(p + e.yyx).x + 
 e.yxy * GetDist(p + e.yxy).x + 
 e.xxx * GetDist(p + e.xxx).x);
}

float GetLight(vec3 p) {
 vec3 lightPos = vec3(sin(time)*1., cos(time)*2., 2);
 vec3 l = normalize(p-lightPos);
 vec3 n = GetNormal(p);
 float dif = clamp(dot(n, l)*.5+.5, 0., 1.);
 vec2 d = RayMarch(p+n*SURF_DIST*1., l);
 return dif;
}

vec3 R(vec2 uv, vec3 p, vec3 l, float z) {
 vec3 f = normalize(l-p),
 r = normalize(cross(vec3(0,1,0), f)),
 u = cross(f,r),
 c = p+f*z,
 i = c + uv.x*r + uv.y*u,
 d = normalize(i-p);
 return d;
}

void main(void)
{
 vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
 vec2 m = mouse*resolution.xy.xy/resolution.xy;  
 vec3 col = vec3(0);  
 vec3 ro = vec3(3.,3., 5.);
 ro.xy *= Rot(sin(time*0.2)*6.2831);
 ro.xz *= Rot(sin(time*0.2)*6.2831);
 vec3 rd = R(uv, ro, vec3(0,0,0), 1.);
 vec2 d = RayMarch(ro, rd);
 float t2;
 t2=d.x;   
 if(t2>0.)
 {
  vec3 p = ro + rd * t2;
  vec3 n = GetNormal(p);
  vec3 baseColor = vec3(1,0,cos(time*2.)+.5);
  float dif = GetLight(p);
  col = vec3(dif);
  col+=baseColor;
 if(d.y==1.) col += tex3D(p,n)*2.;
 }
 col*=g1*vec3(.000005);  
 float fog = 1. / (1. + d.x * d.x *5.);
 col *= vec3(fog); 
 col*= 1.; 
 glFragColor = vec4(col,1.0);
}
