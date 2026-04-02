#version 420

// original https://www.shadertoy.com/view/WtKXzD

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

float dMengerSponge(vec3 p,vec3 size) 
{
 float d = sdBox(p, vec3(size));
 float itt =1.;
 float one_third = .094 / itt;
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
mat3 rotate( in vec3 v, in float angle)
{
    float c = cos(radians(angle));
    float s = sin(radians(angle));
    
    return mat3(c + (1.0 - c) * v.x * v.x, (1.0 - c) * v.x * v.y - s * v.z, (1.0 - c) * v.x * v.z + s * v.y,
        (1.0 - c) * v.x * v.y + s * v.z, c + (1.0 - c) * v.y * v.y, (1.0 - c) * v.y * v.z - s * v.x,
        (1.0 - c) * v.x * v.z - s * v.y, (1.0 - c) * v.y * v.z + s * v.x, c + (1.0 - c) * v.z * v.z
        );
}

#define pi acos(-1.)
#define tau (2.*pi)
#define T (time*0.5)

float GetDist(vec3 p) {    
 float gap = 1.;
 p.xyz = mod(p.xyz + gap,2.0 * gap) - gap;
 float d;
 d=float(1.0);  
 p = rotate( ( vec3(sin(p.z*2.+time*.5) , 0.,0. ) ), 2.)*p;
 vec3 q = p;
 float dp = dot(p,(p*1.))*.2;
 p /= dp;
 p = abs(p*5.);   
 p=fract(p-vec3(T*tau*.1,T*tau*.1,T*tau*.1))*.1;
 float dm1= (dMengerSponge(p,vec3(1.)))+(dMengerSponge(q,vec3(.85)));
 d *=1.;
 d = min( d,dm1); 
 d = (((d*dp)/1.));
 g1 +=1./(.001+pow(abs(dm1),1.));
 return d;
}

float RayMarch (vec3 ro, vec3 rd) 
{
 float    dO = 0.;        
 for (int i=0; i<100; i++) 
  {
   vec3 p = ro + dO * rd;
   float dS = GetDist (p);
   if (dS<0.001 || abs(dO)>100.) break;  
   dO += dS*1.;
  }
 return dO;
}
 
vec3 GetNormal(vec3 p)
{
 float d = GetDist(p);
 vec2 e = vec2(0.001,0.);
 vec3 n = d - vec3(
  GetDist(p-e.xyy),
  GetDist(p-e.yxy),
  GetDist(p-e.yyx));
 return normalize(n);
}

vec3 getObjectColor(vec3 p){
    
    vec3 col = vec3(1);
    
    if(fract(dot(floor(p), vec3(.1))) > .1) col = vec3((sin(time*2.5)*0.5+0.5),0.2,0.);
    if(fract(dot(floor(p), vec3(.5))) < .5) col = vec3((cos(time*1.5)*0.5+0.5),0.,0);
    
    return col;
    
}

float GetLightPos(vec3 p, vec3 lpos) {
 float s = mod(time * 0.25, 1.0);
 float t = 2. * (2.0 * s - s * s);
 vec3 cameraPos = vec3(1.,3.,1);
 vec3 lightPos1 = vec3(-cameraPos-vec3(1,1.,0.0));
 vec3 l1 = normalize(lightPos1-p);
 vec3 n1 = GetNormal(p);    
 float dif1 = clamp(dot(n1, l1), 0., 1.);
 float d1 = RayMarch(p+n1*0.001*1., l1);
 if(d1<length(lightPos1-p)) dif1 *= .6;    
 return (dif1)/=.3;
}

void main(void)
{
 vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
 vec2 m = mouse*resolution.xy.xy/resolution.xy;
 vec3 col = vec3(0);
 float s = mod(time * 0.25, 1.0);
 float t = 1. * (2.0 * s - s * s);  
 vec3 cameraPos = vec3(1.,1.,1);
 vec3 ro = vec3(-cameraPos);
 vec3 rd = normalize(vec3(uv.x, uv.y, 2.5));
 float the = time *1.;
 the = 3.85;
 rd.xz *= mat2(cos(the), -sin(the), sin(the), cos(the));
 rd.yz *= mat2(cos(the), -sin(the), sin(the), cos(the));
 float d = RayMarch(ro, rd);
 float t2;
 t2=d;   
 if(t2>0.)
 {
  vec3 p = ro + rd * t2;
  float dif = GetLightPos(p, ro);
  col = vec3(dif);
  vec3 objCol = getObjectColor(p);

  col+=objCol;
 }  
 col*=g1*vec3(.00001);  

         col/=g1*vec3(.0001);  
float fog = 3. / (1. + d * d * 10.);
 col *= vec3(fog);  
 vec3 sky = vec3(0., 1., 1.);
 col = mix(sky, col, 1.15/(d*d/1./1.*.5+1.)); 
 glFragColor = vec4(col,1.0);
}

