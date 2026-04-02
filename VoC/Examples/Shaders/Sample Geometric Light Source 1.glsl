#version 420

// original https://www.shadertoy.com/view/tsfyRM

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define MAX_STEPS 25
#define MAX_DIST 3.5
#define SURF_DIST .001

vec2 condmin(in vec2 d1, in vec2 d2) {
return vec2(min(d1.x, d2.x), mix(d1.y, d2.y, step(d2.x, d1.x)));
}

const float PI = 3.14159265;

mat3 rotate( in vec3 v, in float angle)
{
 float c = cos(radians(angle));
 float s = sin(radians(angle));    
 return mat3(c + (1.0 - c) * v.x * v.x, (1.0 - c) * v.x * v.y - s * v.z, (1.0 - c) * v.x * v.z + s * v.y,
 (1.0 - c) * v.x * v.y + s * v.z, c + (1.0 - c) * v.y * v.y, (1.0 - c) * v.y * v.z - s * v.x,
 (1.0 - c) * v.x * v.z - s * v.y, (1.0 - c) * v.y * v.z + s * v.x, c + (1.0 - c) * v.z * v.z
 );
}

float box( in vec3 p, in vec3 data )
{
 return max(max(abs(p.x)-data.x,abs(p.y)-data.y),abs(p.z)-data.z);
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

float smin( float a, float b, float k ) {
 float h = clamp( 0.5+0.5*(b-a)/k, 0., 1. );
 return mix( b, a, h ) - k*h*(1.0-h);
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

float GetDist(vec3 p) {
 float d;
 vec3 p2 = p;
 float gap = 1.;
 p2 = mod(p + gap,2.0 * gap) - gap;
 float box = sdBox(p2-vec3(0,0.,.0), vec3(0.2,.7,.3));
 float box2 = sdBox(p2-vec3(0,0.,.0), vec3(.8,.1,1.));
 float box3 = sdBox(p2-vec3(0,0.,0), vec3(1.,.2,.3));
 float prev = 1.;
 vec3 p1 = vec3( p- vec3(1.,1.,sin(time-3.)+time)); 
 float the = time *1.3;
 p1.x = abs(p1.x)-1.;
 p1.yz *= mat2(cos(the), -sin(the), sin(the), cos(the));
 the = time *0.1;
 p1.zx *= mat2(cos(the), -sin(the), sin(the), cos(the));
 p2 = vec3( p- vec3(1.,1.,sin(time-.5)+time)); 
 the = time *-.5;
 p2.xz *= mat2(cos(the), -sin(the), sin(the), cos(the));
 the = time *.5;
 p2.xy *= mat2(cos(the), -sin(the), sin(the), cos(the));
 float dbox = sdOctahedron( p1,.2);
 float dbox2 = sdBox( p2,vec3(.2));
 g1 +=1./(.1+pow(abs(dbox2),5.));
 g2 +=1./(0.1+pow(abs(dbox),5.));
 prev = dbox;
 dbox = min(dbox,dbox2);
 box = min(box3,box);
 box = min(box2,box);
 dbox = min(dbox,box);
 d = dbox;
 return d ;
}

float RayMarch(vec3 ro, vec3 rd) {
 float dO=0.;  
 for(int i=0; i<MAX_STEPS; i++) {
  vec3 p = ro + rd*dO;
  float dS = GetDist(p);      
  if(dO>MAX_DIST || abs(dS)<SURF_DIST) break;
   dO += dS;
  }  
 return dO;
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

void main(void)
{
 vec2 uv =( 2. * gl_FragCoord.xy - resolution.xy ) / resolution.y;
 vec2 m = mouse*resolution.xy.xy/resolution.xy;
 vec3 col = vec3(0);

 vec3 eye = 1.0*vec3(1.,1.,time+1.5); 
 vec3 hoek = vec3(0., 0, 0.0);  
 mat3 camera = setCamera( eye, hoek,sin(time*0.2));
 float fov = .8;
 vec3 dir = camera * normalize(vec3(uv, fov));

 float lensResolution = 3.5;
 float focalLenght =1.;
 float lensAperture = .1;
 float inc = 1./lensResolution;
 float start = inc/2.-1.;
 vec3 focalPoint = eye + (dir * focalLenght);
 for (float stepX = start; stepX < 0.5; stepX+=inc){
 for (float stepY = start; stepY < .5; stepY+=inc){
 vec2 shiftedOrigin = vec2(stepX, stepY) * lensAperture;
  if (length(shiftedOrigin)<(lensAperture/2.)){
  vec3 shiftedRayOrigin = eye;
  shiftedRayOrigin.x += shiftedOrigin.x;
  shiftedRayOrigin.y += shiftedOrigin.y;
  vec3 shiftedRay = (focalPoint - shiftedRayOrigin);
  float d = RayMarch(shiftedRayOrigin, shiftedRay);

  }
 }
 }
 vec3 d = col;
 d +=g1*vec3(0.0005)*vec3(sin(time-2.),0,sin(time-2.)-.5);    
 d +=g2*vec3(0.0005)*vec3(cos(time),1,1);    
 vec3 sky = vec3(1., 1., 1.);
     d = mix(sky, d, 1.01/(d.x*d.x/1./1.*.1+1.13)); 
 //d*= 1.2;
 glFragColor = vec4(d,1.0);
}
