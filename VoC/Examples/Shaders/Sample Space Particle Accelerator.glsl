#version 420

// original https://www.shadertoy.com/view/tssyRX

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define MAX_STEPS 40
#define MAX_DIST 30.
#define SURF_DIST .001

//---------
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

float sdOctahedron( vec3 p, float s)
{
 p = abs(p);
 return (p.x+p.y+p.z-s)*0.57735027;
}

mat2 Rot(float a) {
 float s = sin(a);
 float c = cos(a);
 return mat2(c, -s, s, c);
}

float sdSphere(vec3 p, float s)
{
 return length(p) - s;
}

float sdBox(vec3 p, vec3 s) {
 p = abs(p)-s;
 return length(max(p, 0.))+min(max(p.x, max(p.y, p.z)), 0.);
}

float g1;
float g2;
float g3;
float g4;
float g5;

vec2 GetDist(vec3 p) {  
 vec2 d;
 vec3 p2 = p;
 float gap = 1.;
 p2 = mod(p + gap,2.0 * gap) - gap;
 vec3 p4 = p;
 float gap2 = 1.;
 p4.z = mod(p.z + gap2,2.0 * gap) - gap;   
 vec2 box = vec2(sdBox(p2-vec3(0,0.,.0), vec3(.1,1.,.95)),3);
 vec2 box2 = vec2(sdBox(p2-vec3(0.,0.,.0), vec3(.8,.2,.95)),3);
 vec2 box3 = vec2(sdBox(p2-vec3(0,0.,0), vec3(.4,sin(p.x*1.+2.8)+0.4,.95)),3);   
 vec2 box4 = vec2(sdBox(p2-vec3(0.,-.0,-.0), vec3(0.1,.1,.1)),1);
 box = condmin(box4,box);
 p2 = vec3( p- vec3(1.,1.,.0)); 
 float the = time *-1.;
 the = time *.5;
 p2.xy *= mat2(cos(the), -sin(the), sin(the), cos(the));
 float size = .3;
 p2 = abs(p2)-.8;
 vec2 dbox2 = vec2(sdBox( p2,vec3(size)),3);
 vec2 dbox20 = vec2(sdOctahedron( p2,(size)),3);
 dbox2.x = mix (dbox2.x,dbox20.x,cos(time));
 p2 = vec3( p- vec3(1.,1.,0.5)); 
 the = time *-0.2;
 p2.xz *= mat2(cos(the), -sin(the), sin(the), cos(the));
 the = time *.4;
 p2.xy *= -mat2(cos(the), -sin(the), sin(the), cos(the));
 p2.zy *= -mat2(cos(the), -sin(the), sin(the), cos(the));
 p2 = abs(p2)-.2;
 vec2 dbox4 = vec2(sdSphere( p2-vec3(0.,-0.,-.0),(.02)),1);
 vec3 p3 = vec3( p- vec3(1.,1.,1.-2.)); 
 the = time *-.5;
 p3.xz *= -mat2(cos(the), -sin(the), sin(the), cos(the));
 the = time *.5;
 p3.xy *= mat2(cos(the), -sin(the), sin(the), cos(the));
 vec2 dbox5 = vec2(sdBox( p3,vec3(.2)),1);
 g3 +=1./(0.1+pow(abs(dbox4.x),5.));
 g4 +=1./(1.+pow(abs(dbox5.x),1.));
 box = condmin(box3,box);
 box = condmin(box2,box);
 box.x =  smin(dbox2.x,box.x,.5);
 vec2 box7 = vec2(sdBox(p4-vec3(1,1.,0.), vec3(4.,.5,.7)),1);
 vec2 o = path(p.z) / 4.0;
 p = vec3(p)-vec3(1,1.,1.);
 p.xy *= rz2(p.z*sin(1.+time*2.)+2.);    
 float cyl2wave = 0.1+0.5*(sin(p.z+t*2.)*.1);
 float cylfade = 1.+smoothstep(.0,5.,abs(p.z*1.+time*1.));
 float cyl2r = 0.15*cyl2wave*cylfade;
 float cylT = 1.;
 float cylC = 1.;
 vec2 cyl2p = modA(p.xy, (abs(sin(t*1.)+4.)))-vec2(cyl2wave, 0)*cylfade;   
 vec2 cyl2 = vec2(cyl(cyl2p, cyl2r),1);
 vec3 cubP = p;
 float cubC = .1;
 cubP.z = mod(cubP.z, cubC)-cubC*.5;
// cubP.xy *= rz2(t*.3);
 vec2 cub =vec2(cube(cubP,vec3(.2*cyl2wave*cylfade)),1.);    
 box.x =(max(box.x,-box7.x));   
 vec2 ebox = condmin(cyl2,box);
 ebox = condmin(ebox,dbox2);
// ebox = condmin(ebox,cub);

    g1 +=1./(.01+pow(abs(cub.x),2.));
 g2 +=1./(.01+pow(abs(cyl2.x),cos(abs(p.z)*1.+time*1.)*2.));
 g4 +=1./(.01+pow(abs(box4.x),sin((p.z)*.5+time*4.)*3.));
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
 vec3 eye = 1.0*vec3(1.5,1.,.5);
  float   the = (time*.25);
 eye.xz *= mat2(cos(the), -sin(the), sin(the), cos(the))*1.;
 vec3 hoek = vec3(1,1.,1);  
    the = (time*.2)-2.5;
// hoek.yz *= Rot(-m.y*6.2831);
//   hoek.xz *= Rot(-m.x*6.2831);
mat3 camera = setCamera( eye, hoek,time);
 float fov = .6;
 vec3 dir = camera * normalize(vec3(uv, fov));
 float lensResolution = 2.;
 float focalLenght =1.;
 float lensAperture = .03;
 float inc = 1./lensResolution;
 float start = inc/2.-1.;
    vec3 shiftedRayOrigin;
 vec3 focalPoint = eye + (dir * focalLenght);
 for (float stepX = start; stepX < 0.5; stepX+=inc){
 for (float stepY = start; stepY < .5; stepY+=inc){
 vec2 shiftedOrigin = vec2(stepX, stepY) * lensAperture;
  if (length(shiftedOrigin)<(lensAperture/2.5)){
  vec3 shiftedRayOrigin = eye;
  shiftedRayOrigin.x += shiftedOrigin.x;
  shiftedRayOrigin.y += shiftedOrigin.y;
  vec3 shiftedRay = (focalPoint - shiftedRayOrigin);
  vec2 d = RayMarch(shiftedRayOrigin, shiftedRay);
  float t =d.x *1.;   
   if(t>.001){
    vec3 baseColor = vec3(0.,0.,0.);
    shiftedRayOrigin += shiftedRay * t;
    vec3 sn = GetNormal(shiftedRayOrigin);
    shiftedRay = reflect(shiftedRay, sn);
    if(d.y==3.) traceRef(shiftedRayOrigin +  shiftedRay*.1, shiftedRay);
    }
   }
  }
 }
 vec3 d;
 d *= marchCount * vec3(1., 1.,1.) * 1.;
d +=g1*vec3(0.0025)*abs(vec3(sin(time-1.)+0.5+0.5,sin(time-2.5)+0.5+0.5,sin(time-2.)+0.5+0.5)*.1);    
d +=g2*vec3(0.001)*vec3(1.,.5,.5);    
d +=g3*vec3(0.004)*vec3(abs(sin(time-2.)),.5,1.)*abs(cos(time*0.5));    
 d +=g4*vec3(0.001)*vec3(sin(time),0,0.);    
 vec3 sky = vec3(1., 1., 1.);
 d = mix(sky, d, 1.0/(d.x*d.x/1./1.*.1+1.)); 
 //d*= 1.;
 glFragColor = vec4(d,1.0);
}
