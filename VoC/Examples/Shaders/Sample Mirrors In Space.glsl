#version 420

// original https://www.shadertoy.com/view/3dXczB

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define MAX_STEPS 40
#define MAX_DIST 50.
#define SURF_DIST .001

#define PI 3.14159
#define TAU PI*2.
#define t time
mat2 rz2 (float a) { float c=cos(a), s=sin(a); return mat2(c,s,-s,c); }
float cyl (vec2 p, float r) { return length(p)-r; }
float cube (vec3 p, vec3 r) { return length(max(abs(p)-r,0.)); }

vec2 path(float z){
 float x = sin(z) - 4.0 * cos(z * 0.3) - .5 * sin(z * 0.12345);
 float y = cos(z) - 4. * sin(z * 0.3) - .5 * cos(z * 2.12345);
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

vec2 condmin(in vec2 d1, in vec2 d2) {
return vec2(min(d1.x, d2.x), mix(d1.y, d2.y, step(d2.x, d1.x)));
}

mat2 Rot(float a) {
 float s = sin(a);
 float c = cos(a);
 return mat2(c, -s, s, c);
}

float sdBox(vec3 p, vec3 s) {
 p = abs(p)-s;
 return length(max(p, 0.))+min(max(p.x, max(p.y, p.z)), 0.);
}

float g1;
float g2;
float g3;
float g4;

vec2 GetDist(vec3 p) {
 vec2 d;
 vec3 p2 = p;
 vec3 p4 = p;
 p4.xz *= Rot(sin(time)); 
 p4.yz *= Rot((time*.4));
 vec2 box7 = vec2(sdBox(p4-vec3(1,1.,-1.), vec3(.5,.5,.01)),3);
 vec2 o = path(p.z) / 4.0;
 p = vec3(p)-vec3(1,1.,1.);
 p.xy *= rz2(sin(p.z*.5+time));    
 float wave = 1.+1.4*(sin(p.z*1.2+t*.2)*.001);
 float fade = 1.+smoothstep(.0,3.,abs(sin(p.z*.01+time*.1)));
 float cylr = 0.01*wave*fade;
 vec2 cyl2p = modA(p.xy, (abs(sin(t*1.)+5.)))-vec2(wave, 0)*fade;
 vec2 cyl2 = vec2(cyl(cyl2p, cylr),1);
 p.yx *= rz2(t*1.);
 vec2 cub = vec2(sdBox(p-vec3(0,0.,-2.5), vec3(.5,2.,.02)),3);
 vec2 ebox = condmin(cyl2,box7);
 ebox = condmin(ebox,cub);
 g1 +=1./(.05+pow(abs(cub.x),2.));
 g2 +=1./(.01+pow(abs(cyl2.x),2.));
 g3 +=1./(.05+pow(abs(box7.x),1.));
 d = ebox;
 return d ;
}

vec2 RayMarch(vec3 ro, vec3 rd) {
vec2 h, t=vec2( 0.);   
for (int i=0; i<MAX_STEPS; i++) 
{   
h = GetDist(ro + t.x * rd);
if(h.x<SURF_DIST||abs(t.x)>MAX_DIST) break;
t.x+=h.x *1.;
t.y=h.y;
}
if(t.x>MAX_DIST) 
t.x=0.;
t.x +=h.x*1.;
return t;
}
float marchCount;

float traceRef(vec3 o, vec3 r){
    
 float t = 0.0;
 marchCount = 0.0;
 float dO = 0.;  
 for (int i = 0; i < 20; i++)
 {
  vec3 p = o + r * t;   
  float d = GetDist (p).x;
  if(d<.001 || (t)>100.) break;
  t += d * 1.;
  marchCount+= 1./d*1.;
 }    
 return t;
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

mat3 setCamera( in vec3 ro, in vec3 ta, float cr ){
 vec3 cw = normalize(ta-ro);
 vec3 cp = vec3(sin(cr), cos(cr),0.0);
 vec3 cu = normalize( cross(cw,cp) );
 vec3 cv = cross(cu,cw);
 return mat3( cu, cv, cw );
}

vec3 GetNormal(vec3 p){
vec2 e = vec2(.00035, -.00035); 
return normalize(
 e.xyy * GetDist(p + e.xyy).x + 
 e.yyx * GetDist(p + e.yyx).x + 
 e.yxy * GetDist(p + e.yxy).x + 
 e.xxx * GetDist(p + e.xxx).x);
}

void main(void)
{
 vec2 uv =( 2. * gl_FragCoord.xy - resolution.xy ) / resolution.y;
 vec2 m = mouse*resolution.xy.xy/resolution.xy;
 vec3 eye = 1.0*vec3(1.,1.,1.3);
 vec3 hoek = vec3(1,1.,1);  
 mat3 camera = setCamera( eye, hoek,1.);
 float fov = .8;
 vec3 dir = camera * normalize(vec3(uv, fov));
 float lensResolution = 4.;
 float focalLenght =1.;
 float lensAperture = .1;
 float inc = 1./lensResolution;
 float start = inc/2.-1.;
 vec3 shiftedRayOrigin;
 vec3 no;
 vec3 focalPoint = eye + (dir * focalLenght);
 for (float stepX = start; stepX < 0.5; stepX+=inc){
 for (float stepY = start; stepY < .5; stepY+=inc){
 vec2 shiftedOrigin = vec2(stepX, stepY) * lensAperture;
 if (length(shiftedOrigin)<(lensAperture/3.)){
  vec3 shiftedRayOrigin = eye;
  shiftedRayOrigin.x += shiftedOrigin.x;
  shiftedRayOrigin.y += shiftedOrigin.y;
  vec3 shiftedRay = (focalPoint - shiftedRayOrigin);
  vec2 d = RayMarch(shiftedRayOrigin, shiftedRay);
  float t =d.x *1.;  
   if(t>.001){
    vec3 baseColor = vec3(0.,0.,0.);
    shiftedRayOrigin += shiftedRay * t;
    no = shiftedRayOrigin;
    vec3 sn = GetNormal(shiftedRayOrigin);
    shiftedRay = reflect(shiftedRay, sn);
    if(d.y==3.) traceRef(shiftedRayOrigin +  shiftedRay*.1, shiftedRay);
    }
   }
  }
 }
 vec3 d;
 d *= marchCount * vec3(1., 1.,1.) * 1.;
d +=g1*vec3(0.002)*abs(vec3(sin(time-1.)+0.5+0.5,sin(time-2.5)+0.5+0.5,sin(time-2.)+0.5+0.5)*.05);    
d +=g2*vec3(0.0003)*vec3(abs(cos(no.z*.01+time))*1.,.5,.5);    
d +=g3*vec3(0.0001)*vec3(abs(cos(time))*1.);    
vec3 sky = vec3(.5, 0., 1.);
d = mix(sky, d, 1.1/(d.x*d.x/1./1.*.1+1.0)); 
glFragColor = vec4(d,1.0);
}
