#version 420

// original https://www.shadertoy.com/view/WddSWj

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14159
#define TAU PI*2.
#define t time
#define MAX_STEPS 64
#define MAX_DIST 200.
#define SURF_DIST .5
#define FAR 4.

mat2 rz2 (float a) { float c=cos(a), s=sin(a); return mat2(c,s,-s,c); }
float cyl (vec2 p, float r) { return length(p)-r; }
float cube (vec3 p, vec3 r) { return length(max(abs(p)-r,0.)); }

vec2 path(float z){
 float x = sin(z) - 4.0 * cos(z * 0.3) - .5 * sin(z * 0.12345);
 float y = cos(z) - 4. * sin(z * 0.3) - .5 * cos(z * 2.12345);
 return vec2(x,y);
}

vec2 path2(float z){
 float x = sin(z) + 4.0 * cos(z * 0.3) + .5 * sin(z * 0.12345);
 float y = cos(z) + 4. * sin(z * 0.3) + .3 * cos(z * 2.12345);
 return vec2(x,y);
}

vec2 modA (vec2 p, float count) {
 float an = TAU/count;
 float a = atan(p.y,p.x)+an*.5;
 a = mod(a, an)-an*.5;
 return vec2(cos(a),sin(a))*length(p);
}

float smin (float a, float b, float r)
{
 float h = clamp(.5+.5*(b-a)/r,0.,1.);
 return mix(b, a, h) - r*h*(1.-h);
}

float GetDist (vec3 p)
{
 vec2 o = path(p.z) / 4.0;
 p = vec3(p.x,p.y,p.z)-vec3(o.x,o.y,0.);  
 vec2   o2 = path2(p.z) / 4.0;
 vec3 q = vec3(p.x,p.y,p.z)-vec3(o2.x,o2.y,0.);
 p.xy *= rz2(p.z*sin(t*0.002+250.));    
 q.xy *= rz2(q.z*sin(-t*0.002+250.));
 float cyl2wave = .3+1.5*(sin(p.z+t*0.5)*.1);
 float cylfade = 2.-smoothstep(.0,8.,abs(p.z));
 float cyl2r = 0.02*cyl2wave*cylfade;
 float cylT = 1.;
 float cylC = 1.;
 vec2 cyl2p = modA(p.xy, (abs(sin(t*0.1)+3.)))-vec2(cyl2wave, 0)*cylfade;
 float cyl2 = cyl(cyl2p, cyl2r);
 cyl2p = modA(p.xy*rz2(-p.z*cylT), cylC)-vec2(cyl2wave, 0)*cylfade; 
 vec3 cubP = p;
 float cubC = 0.1;
 cubP.z = mod(cubP.z, cubC)-cubC*1.;
 cubP.xy *= rz2(t*3.);
 float cyl2a = smin(cyl2, cube(cubP,vec3(.1*cyl2wave*cylfade)),.5);
 cyl2wave = .3+1.5*(sin(q.z+t*0.5)*.1);
 cylfade = 2.-smoothstep(.0,8.,abs(q.z));
 cyl2r = 0.06*cyl2wave*cylfade;
 cylT = 1.;
 cylC = 1.;
 cyl2p = modA(q.xy, (abs(sin(t*0.1)+3.)))-vec2(cyl2wave, 0)*cylfade;
 cyl2 = cyl(cyl2p, cyl2r);
 cyl2p = modA(q.xy*rz2(-q.z*cylT), cylC)-vec2(cyl2wave, 0)*cylfade;
 cubP = q;
 cubC = 0.1;
 cubP.z = mod(cubP.z, cubC)-cubC*1.;
 cubP.xy *= rz2(t*3.);
 float cyl22 = smin(cyl2, cube(cubP,vec3(.1*cyl2wave*cylfade)),.5); 
 return smin(cyl2a,cyl22,0.5);
}

float marchCount;

float RayMarch (vec3 ro, vec3 rd) 
{
 float dO = 0.;       
 marchCount = 0.0;       
 for (int i=0; i<68; i++) 
  {
   vec3 p = ro + dO * rd;
   float dS = GetDist (p);
   dO += dS;
   if (dS<0.001 || dO>100.) break;
   marchCount+= 1./dS*0.02;
  }
 return dO;
}
 
vec3 GetNormal(vec3 p){
 float d = GetDist(p);
 vec2 e = vec2(0.1,0);
 vec3 n = d - vec3(
  GetDist(p-e.xyy),
  GetDist(p-e.yxy),
  GetDist(p-e.yyx));
    
 return normalize(n);
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy -.5*resolution.xy) / resolution.y;
    vec3 col = vec3(0);
    vec3 ro = vec3(0.,0.,-t);
    vec3 rd = normalize(vec3(uv.x,uv.y,1.));
    float the = time *0.01;
    rd.yx *= mat2(cos(the), -sin(the), sin(the), cos(the));
    float d = RayMarch (ro,rd);
    vec3 p = ro + rd *d;
    float fog = 1.2 / (1. + d * d *.3);
    vec3 fc = vec3(fog);
    fc += marchCount * vec3((cos(t +-p.z)*2.), 0.15,0.)*0.02;
    fc *= vec3(fog);
    glFragColor = vec4(fc,1.0);
}
