#version 420

// original https://www.shadertoy.com/view/wlcXWn

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

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

mat2 Rot(float a) {
 float s = sin(a);
 float c = cos(a);
 return mat2(c, -s, s, c);
}

float sdOctahedron( vec3 p, float s)
{
 p = abs(p);
 return (p.x+p.y+p.z-s)*0.57735027;
}

float dMengerSponge(vec3 p) 
{
 float d = sdBox(p, vec3(0.6));
 float itt = 5.;
 float one_third = 2. / itt;
 for (float i = 0.0; i < itt; i++) {
  float k = pow(one_third, i);
  float kh = k * 1.;
  d = max(d, -dCrossBar(mod(p + kh, k * 2.) - kh, k * one_third));
 }
 return d;
}
float dMengerSponge2(vec3 p) 
{
 float d = sdBox(p, vec3(0.4));
 float itt = 4.;
 float one_third = 1. / itt;
 for (float i = 0.0; i < itt; i++) {
  float k = pow(one_third, i);
  float kh = k * 1.;
  d = max(d, -dCrossBar(mod(p + kh, k * 2.) - kh, k * one_third));
 }
 return d;
}

vec2 condmin(in vec2 d1, in vec2 d2) {
return vec2(min(d1.x, d2.x), mix(d1.y, d2.y, step(d2.x, d1.x)));
}

float g1;
vec2 GetDist(vec3 p) {    
    
 float gap = 1.;
 p.xyz = mod(p.xyz + gap,2.0 * gap) - gap;
 vec2 d;
 d=vec2(1.0);  
 vec3 p5 = p;
 p5.xz *= Rot(sin(0.09*.4*6.28));
 vec2 dm1= vec2(dMengerSponge(p5),2);
 p = abs(p-.4);   
 vec3 p1 = p-vec3(-.0,1.,1.0);
 vec3 p2 = p-vec3(1.,0.0,1.0);
 vec3 p4 = p-vec3(1.,1.0,.0);   
 vec2  dm2=vec2(dMengerSponge2(p1),1);
 vec2  dm3=vec2(dMengerSponge2(p2),1);
 vec2  dm4=vec2(dMengerSponge2(p4),1);
 dm2.x *=0.6;
 dm3.x *=0.6;  
 dm4.x *=0.6;
 d = condmin( d,dm1);
 d = condmin( d,dm2);
 d = condmin( d,dm3);
 d = condmin( d,dm4);
 g1 +=1./(.02+pow(abs(dm1.x),10.));
 return d;
}

vec2 RayMarch (vec3 ro, vec3 rd) 
 {
 vec2 h, t=vec2( 0.);
 for (int i=0; i<64; i++) 
  {
 h = GetDist(ro + t.x * rd);
 if(h.x<0.001||t.x>100. ) break;
  t.x+=h.x;t.y=h.y;
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

vec3 cameraPath(float t) {
 t *= PI *.5 ;
 float t2 =  cos(t)+0.;
 float c = cos(t*2.);
 float x = 0.;
 float y = 0.;
 float z = 0.;
 if (t2<0.){
  x = 1. /1. + 2. +c;
 };       
 if (t2>0.){
  y = 1. /1. + 2. +c;
 };
 vec3 xyz =vec3(x,y,z);
 return xyz;
}

float GetLightPos(vec3 p, vec3 lpos) {
 float s = mod(time * 0.25, 1.0);
 float t = 2. * (2.0 * s - s * s);
 vec3 cameraPos = cameraPath(t);
 vec3 lightPos1 = vec3(-cameraPos-vec3(4,4.,2.0));
 vec3 l1 = normalize(lightPos1-p);
 vec3 n1 = GetNormal(p);    
 float dif1 = clamp(dot(n1, l1), 0., 1.);
 vec2 d1 = RayMarch(p+n1*0.001*1., l1);
 if(d1.x<length(lightPos1-p)) dif1 *= 1.;    
 return (dif1)/1.0;
}

void main(void)
{
 vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
 vec2 m = mouse*resolution.xy.xy/resolution.xy;
 vec3 col = vec3(0);
 float s = mod(time * 0.25, 1.0);
 float t = 2. * (2.0 * s - s * s);  
 vec3 cameraPos = cameraPath(t);
 vec3 ro = vec3(-cameraPos);
 vec3 rd = normalize(vec3(uv.x, uv.y, 0.4));
 float the = time *0.3;
 rd.xz *= mat2(cos(the), -sin(the), sin(the), cos(the));
 rd.yz *= mat2(cos(the), -sin(the), sin(the), cos(the));
 rd.xy *= mat2(cos(the), -sin(the), sin(the), cos(the));
 vec2 d = RayMarch(ro, rd);
 float t2;
 t2=d.x;   
 if(t2>0.)
 {
  vec3 p = ro + rd * t2;
  vec3 baseColor = vec3(0.,0.6,0.);
  if(d.y==1.) baseColor=vec3((sin(time*1.5)*0.5+0.5),0.,0);
  if(d.y==2.) baseColor=vec3((cos(time*1.5)*0.5+0.5),0.,0);
;
  float dif = GetLightPos(p, ro);
  col = vec3(dif);
  col+=baseColor;
 }  
 col*=g1*vec3(.0007);  
 float fog = 1. / (2. + d.x * d.x * 1.);
 col *= vec3(fog);  
 vec3 sky = vec3(1., 1., 1.);
 col = mix(sky, col, 1.1/(d.x*d.x/1./1.*.1+.8)); 
 glFragColor = vec4(col,1.0);
}

