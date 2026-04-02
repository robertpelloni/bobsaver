#version 420

// original https://www.shadertoy.com/view/7syGzD

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define MAX_STEPS 25
#define MAX_DIST 50.
#define SURF_DIST .15
#define PI 3.14159265359
float smin( float a, float b, float k ) {
float h = clamp( 0.5+0.5*(b-a)/k, 0., 1. );
return mix( b, a, h ) - k*h*(1.0-h);
}

float sphereSDF(vec3 point, vec3 sphereCenter, float radius)
{
     float dist = distance(point, sphereCenter);
    return dist - radius;
}

float extrudeSDF(float sdf, float radius)
{
     return sdf - radius;   
}

float ringSDF(vec3 point, float radius, float width, float height)
{
    float ring2D = abs(length(point.xy) - radius) - width;
    vec2 w = vec2( ring2D, abs(point.z) - height );
    return min(max(w.x,w.y),0.0) + length(max(w,0.0));
}

float torusSDF(vec3 point, float ringPosition, float ringRadius, float lineRadius)
{
    point.z -= ringPosition;
     vec2 flattedUV = vec2(length(point.xy) - ringRadius, point.z);
    return length(flattedUV) - lineRadius;
}

float torusSDFRescaled(vec3 point, float ringPosition, float ringRadius, float lineRadius, vec3 scale)
{
    point.z -= ringPosition;
    point *= scale;
     vec2 flattedUV = vec2(length(point.xy) - ringRadius, point.z);
    return length(flattedUV) - lineRadius;
}

float planeSDF(vec3 point, float planeZPos)
{
     return point.z - planeZPos;   
}

float cylinderSDF(vec3 point, float radius)
{
     return length(point.xy) - radius;   
}

float coneSDF( vec3 point, vec3 coneCenter, float angle)
{
    vec2 c = vec2(sin(angle), cos(angle));
    vec3 pos = point - coneCenter;
    
    return dot(c, vec2(length(pos.xy), pos.z));
}

float sdBox(vec3 p, vec3 s) {
 p = abs(p)-s;
 return length(max(p, 0.))+min(max(p.x, max(p.y, p.z)), 0.);
}

vec2 condmin(in vec2 d1, in vec2 d2) {
return vec2(min(d1.x, d2.x), mix(d1.y, d2.y, step(d2.x, d1.x)));
}

void pR(inout vec2 p, float a) {
    p = cos(a)*p + sin(a)*vec2(p.y, -p.x);
}
float length6( vec3 p )
{
    p = p*p*p; p = p*p;
    return pow( p.x + p.y + p.z, 1.0/6.0 );
}
float fractal(vec3 p)
{
 const int iterations = 15;
 float d = 0.;
 float scale = 2.;
 float l = 0.;    
  for (int i=0; i<iterations; i++) {
   p.xy = abs(p.xy-0.)-sin(time*.5)*.5-1.5;
   p.xz = abs(p.xz-.0)-3.5;
   p = p*scale + vec3(-12.,-5.0,-8);        
   pR(p.xy,sin(time*.7)*.3+0.5-12.2-d);
//pR(p.yz,+92.5*.25+d);        
//pR(p.yz,+228.*.25+d);        
   pR(p.yz,+38.5*.25+d);        

l =length6(p);
  }
 return l*pow(scale, -float(iterations))-0.08;
}

vec2 GetDist(vec3 p) {
 vec2 d = vec2(0);
 vec3 p6 = p;
 p6-=vec3(cos(time)*0.,sin(time)*1.,-14.);
 float the = 1.6; 
 p6.xy *= -mat2(cos(the), -sin(the), sin(the), cos(the));
 the = sin(time*.5)*.5; 
 p6.zy *= -mat2(cos(the), -sin(the), sin(the), cos(the));
 the = cos(time*.5)*.5; 
 p6.zx *= -mat2(cos(the), -sin(the), sin(the), cos(the));
 p6.x = abs(p6.x)-5.3;
// float s = sphereSDF(p6,vec3(-0.,0.,0.),2.1);
// float s2 = ringSDF(p6,.5,4.5,0.5);
// float waves = smoothstep(0.1, 0.45, abs(length(p6.xy) -0.8));
// s2 += max(sin(length(p6.xy * 11.0)), +0.0) * 0.9* waves;
// float s3 = torusSDF(p6+vec3(0,0,0.4),1.5,5.4,.5);
 
 float s = sphereSDF(p6,vec3(-0.,0.,0.),1.5);
 float s2 = ringSDF(p6,.5,3.26,0.5);
 float waves = smoothstep(0.1, 0.45, abs(length(p6.xy) -0.8));
 s2 += max(sin(length(p6.xy * 15.0)), +0.0) * 0.9* waves;
 float s3 = torusSDF(p6+vec3(0,0,0.4),1.5,4.4,.5);
 
 vec3 p4 = p;
 vec3 p5 = p;
 p4 -=vec3(-.0,.0,0.);
 p5 -=vec3(cos(time)*1.,sin(time)*1.,-25.);
 d = vec2((sdBox(p4, vec3(-10))),0.);
 the = 1.6; 
 p5.xy *= -mat2(cos(the), -sin(the), sin(the), cos(the));
 the = sin(time*.5)*.5; 
 p5.zy *= -mat2(cos(the), -sin(the), sin(the), cos(the));
 the = cos(time*.5)*.5; 
 p5.zx *= -mat2(cos(the), -sin(the), sin(the), cos(the));
 vec2 d3 = vec2(fractal(p5-vec3(0,-.0,0.0)),3);
 d = condmin(d,d3);
 s = min(s,s2);
 s = min(s,s3);

d.x = min(d.x,s);

return vec2(d);
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
t.x=100.;
t.x +=h.x*1.;
return t;
}

float marchCount;

float traceRef(vec3 o, vec3 r){
    
 float t = 0.0;
 marchCount = 0.0;
 float dO = 0.;  
 for (int i = 0; i < 1; i++)
 {
  vec3 p = o + r * t;   
  float d = GetDist (p).x;
  if(d<.001 || (t)>10.) break;
  marchCount+= 100./d*1.;
 }    
 return t;
}

mat3 setCamera( in vec3 ro, in vec3 ta, float cr ){
 vec3 cw = normalize(ta-ro);
 vec3 cp = vec3(sin(cr), cos(cr),0.0);
 vec3 cu = normalize( cross(cw,cp) );
 vec3 cv = cross(cu,cw);
 return mat3( cu, cv, cw );
}

vec3 Tunnel(vec2 uv){
 float f = 9. / length(uv);
 f += atan(uv.x, uv.y) / acos(0.);
 f += time*.5;
 f = 1. - clamp(sin(f * PI * 2.) * dot(uv, uv) * resolution.y / 200. + .5, 0., 1.);
 f *= sin(length(uv) - .2);    
 return vec3(f, f, f);
}

void main(void)
{
vec2 uv =( 2. * gl_FragCoord.xy - resolution.xy ) / resolution.y;
uv *= vec2(3.2);
vec3 eye = 1.0*vec3(0.,3.,6.);
vec3 col;
vec2 d;
vec3 hoek = vec3(0,2.,0.);  
float the = (time*1.);
mat3 camera = setCamera( eye, hoek,0.);
float fov = cos(time)*.3+2.0;
vec3 dir = camera * normalize(vec3(uv, fov));
vec3 p;
vec3 n;
vec3 focalPoint = eye + (dir * 1.);
vec3 shiftedRayOrigin = eye;
vec3 shiftedRay = (focalPoint - shiftedRayOrigin);
 d = RayMarch(shiftedRayOrigin, shiftedRay);
float t =d.x *1.;
vec3  shiftedRayOrigin2 = shiftedRayOrigin;
vec3  shiftedRay2= shiftedRay;
if(t<MAX_DIST) {
 shiftedRayOrigin2 += shiftedRay2 * t;
 if(d.y==3.) traceRef(shiftedRayOrigin2 +  shiftedRay2*.2, shiftedRay2);
  if(d.y==3.) col =vec3(0);

 col += marchCount;
 }
vec3 T = Tunnel(uv);
vec3 sky = vec3(0.);
col = mix( T, col, 1./(d.x*d.x/1./1.*.0005+1.0)); 
glFragColor = vec4(col,1.0);
}
