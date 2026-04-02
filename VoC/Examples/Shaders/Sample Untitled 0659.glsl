#version 420

// original https://www.shadertoy.com/view/7ltGRn

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Fork of "Mindf*ck" by julianlumia. https://shadertoy.com/view/tt3XWH
// 2021-10-30 20:27:34

const float EPSILON = 0.001;
const float MAX_DIST = 100.0;
#define MAX_STEPS 100
#define MAX_DIST 100.
#define SURF_DIST .001
float remap(float low1, float high1, float low2, float high2, float value){
    return low2 + (value - low1) * (high2 - low2) / (high1 - low1);
}

const float PI = 3.14159265359;

float sdBox( vec3 p, vec3 b )
{
 vec3 d = abs(p) - b;
 return length(max(d,0.0)); 
}

float dBar(vec2 p, float width) {
 vec2 d = abs(p) - width;
 return min(max(d.x, d.y), 0.0) + length(max(d, 0.)) + 0.01 * width;
}

float dCrossBar(vec3 p, float x) {
 float bar_x = dBar(p.yz, x);
 float bar_y = dBar(p.zx, x);
 float bar_z = dBar(p.xy, x);
 return min(bar_z, min(bar_x, bar_y));
}

float dMengerSponge(vec3 p) 
{
    

    float d = sdBox(p, vec3(1.0));
    float itt = 3.;
    float one_third = 2.7 / itt;
    for (float i = 0.0; i < itt; i++) {
        float k = pow(one_third, i);
        float kh = k * 1.;
        d = max(d, -dCrossBar(mod(p + kh, k * 2.) - kh, k * one_third));
    }
    return d;
}

float GetDist(vec3 p){
 float gap = 1.;
 p.xyz = mod(p.xyz + gap,2.0 * gap) - gap;
 float dm1;
 float d;  
 d=1.0;           
 dm1=dMengerSponge(p-vec3(-0.,-0.,0.0));
 d=min(d, dm1);
 return d;
}

vec3 GetNormal(vec3 p) {
 float d = GetDist(p);
 vec2 e = vec2(.001, 0);  
 vec3 n = d - vec3(
 GetDist(p-e.xyy),
 GetDist(p-e.yxy),
 GetDist(p-e.yyx));   
 return normalize(n);
}

vec3 cameraPath(float t) {
 t *= PI *.5 ;
 float t2 =  cos(t)+0.;
 float c = cos(t*2.);
 float x = 0.;
 float y = 0.;
 float z= 0.;   
 if (t2<0.){
 x = 1. /1. + 2. +c;
 };       
 if (t2>0.){
 y = 1. /1. + 2. +c;
 };
 vec3 xyz =vec3(x,y,z);
 return xyz;
}

vec3 RayDirection(float fieldOfView, vec2 size){
 vec2 xy = gl_FragCoord.xy - size / 2.0;
 float z = size.y / tan(radians(fieldOfView) / 2.);
 return normalize(vec3(xy, -z));
}

float RayMarch(vec3 ro, vec3 rd) {
 float dO=0.1;
 for(int i=0; i<64; i++) {
 vec3 p = ro + rd*dO;
 float dS = GetDist(p);
 dO += dS*1.;
 if(dO>100. || dS<0.001) break;
 } 
 return dO;
}

mat4 viewMatrixRIGHT() 
{
 return mat4(
 vec4(1, 0, 0, 0),
 vec4(0, 1, 0, 0),
 vec4(0,0, 1, 0),
 vec4(0, 0, 0, 1)
 );
}

mat4 viewMatrixDOWN() 
{
 return mat4(
 vec4(0, 0, 1, 0),
 vec4(1,0, 0, 0),
 vec4(0, 1, 0, 0),
 vec4(0, 0, 1, 0)
 );
}

mat4 viewMatrixLEFT() 
{
 return mat4(
 vec4(1, 0, 0, 0),
 vec4(0, 1, 0, 0),
 vec4(0,0, -1, 0),
 vec4(0, 0, 0, -1)
 );
}

mat4 viewMatrixUP() 
{
 return mat4(
 vec4(0,1, 0, 0),
 vec4(0, 0, 1,0),
 vec4(-1,0, 0,0),
 vec4(0, 0,0,1)
 );
}

float GetLightPos(vec3 p, vec3 lpos) {
 float s = mod(time * 0.25, 1.0);
 float t = 2. * (2.0 * s - s * s);
 vec3 cameraPos = cameraPath(t);
 vec3 lightPos1 = vec3(cameraPos-vec3(0,1.,0.3));
 vec3 l1 = normalize(lightPos1-p);
 vec3 n1 = GetNormal(p);
 float dif1 = clamp(dot(n1, l1), 0., 1.);
 float d1 = RayMarch(p+n1*SURF_DIST*1., l1);
 if(d1<length(lightPos1-p)) dif1 *= 1.;  
 return (dif1)/1.0;
}

mat2 Rot(float a) {
 float s = sin(a);
 float c = cos(a);
 return mat2(c, -s, s, c);
}

void main(void)
{
 float t = time * 0.3;
 vec2 res = resolution.xy;
 vec2 frag = gl_FragCoord.xy;
 vec2 uv = frag / res;
 vec3 rayDir;
 vec3 worldDir;    
 vec3 eye;
 vec4 fout;
 vec3  ro; 
 float x9 = 1.2;
  float x10= 010.;

 if( uv.x < 0.25)
 {
  vec3 col;
  frag = gl_FragCoord.xy;
  res = vec2(res.x *  .25, res.y);       
  float s = mod(time * 0.25, 1.0);
  float t = 2. * (2.0 * s - s * s);  
  vec3 cameraPos = cameraPath(t);
  vec3 rd = RayDirection(100.0, res );
  float the = time *0.3;
//  rd.xz *= mat2(cos(the), -sin(the), sin(the), cos(the));
//  rd.yz *= mat2(cos(the), -sin(the), sin(the), cos(the));
  vec3  ro = ( viewMatrixRIGHT() * vec4(rayDir,0.) ).xyz;
  ro = vec3(cameraPos);
  float d = RayMarch(ro, rd);
  vec3 p = ro + rd * d;
  float dif = GetLightPos(p, ro);
  col = vec3(dif);
  float fog =x10 / (2. + d * d * 2.);
  col *= vec3(fog);  
  vec3 sky = vec3(1., 1, 1.);
  col = mix(sky, col, x9/(d*d/1./1.*.1+1.)); 
  fout = vec4(col,1.0);
 }
 else if(  uv.x > 0.25 && uv.x < 0.5 )
 {
  vec3 col;
  float s = mod(time * 0.25, 1.0);
  float t = 2. * (2.0 * s - s * s);  
  vec3 cameraPos = cameraPath(t);
  frag = gl_FragCoord.xy;
  res = vec2(res.x *  0.25, res.y);
  vec3 rd = RayDirection(100.0, res );
  float the = time *0.3;
 // rd.xz *= mat2(cos(the), -sin(the), sin(the), cos(the));
 // rd.yz *= mat2(cos(the), -sin(the), sin(the), cos(the));
  rd = ( viewMatrixDOWN() * vec4(rd,0.) ).xyz;
  ro = vec3(cameraPos);
  float d = RayMarch(ro, rd);
  vec3 p = ro + rd * d;
  float dif = GetLightPos(p, ro);  
  col = vec3(dif);
  float fog =x10 / (2. + d * d * 2.);
  col *= vec3(fog);  
  vec3 sky = vec3(1., 1, 1.);
  col = mix(sky, col, x9/(d*d/1./1.*.1+1.)); 
  fout = vec4(col,1.0);         
 } 
 else if(  uv.x > 0.5 && uv.x < .75 )
 {
  vec3 col;
  float s = mod(time * 0.25, 1.0);
  float t = 2. * (2.0 * s - s * s);  
  vec3 cameraPos = cameraPath(t);
  frag = gl_FragCoord.xy;
  res = vec2(res.x *  0.25, res.y);
   vec3 rd = RayDirection(100.0, res );
  float the = time *0.3;
  //rd.xz *= mat2(cos(the), -sin(the), sin(the), cos(the));
  //rd.yz *= mat2(cos(the), -sin(the), sin(the), cos(the));    
  rd = ( viewMatrixLEFT() * vec4(rd,0.) ).xyz;     
  ro = vec3(cameraPos);
  float d = RayMarch(ro, rd);
  vec3 p = ro + rd * d;  
  float dif = GetLightPos(p, ro);  
  col = vec3(dif);
  float fog =x10 / (2. + d * d * 2.);
  col *= vec3(fog);  
  vec3 sky = vec3(1., 1, 1.);
  col = mix(sky, col, x9/(d*d/1./1.*.1+1.)); 
  fout = vec4(col,1.0);
 }
 else if(  uv.x > 0.75 && uv.x < 1. )
 {
  vec3 col;
  float s = mod(time *0.25, 1.0);
  float t = 2. * (2.0 * s - s * s);  
  vec3 cameraPos = cameraPath(t);
  frag = gl_FragCoord.xy;
  res = vec2(res.x *  .25, res.y);
  vec3 rd = RayDirection(100.0, res );
  float the = time *0.3;
 // rd.xz *= mat2(cos(the), -sin(the), sin(the), cos(the));
 // rd.yz *= mat2(cos(the), -sin(the), sin(the), cos(the));       
  rd = ( viewMatrixUP() * vec4(rd,0.) ).xyz;
  ro = vec3(cameraPos);
  float d = RayMarch(ro, rd);
  vec3 p = ro + rd * d;
  float dif = GetLightPos(p, ro);
  col = vec3(dif);
  float fog =x10 / (2. + d * d * 2.);
  col *= vec3(fog);  
  vec3 sky = vec3(1., 1, 1.);
  col = mix(sky, col, x9/(d*d/01./1.*.1+1.)); 
  fout = vec4(col,1.0);
 }
 glFragColor = vec4(fout);
}
