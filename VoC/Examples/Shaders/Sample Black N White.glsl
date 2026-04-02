#version 420

// original https://www.shadertoy.com/view/3tt3WM

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define MAX_STEPS 
#define MAX_DIST 100.

float smin(float a, float b, float k)
{
float h = clamp (0.5+0.5*(b-a)/k,0.,1.);
return mix(b, a, h) - k*h*(1.0-h);      
}

mat2 Rot (float a)
{
float s = sin(a);
float c = cos(a);
return mat2(c,-s,s,c);
}

vec2 path(float z){
float x = sin(z) + 3.0 * cos(z * 0.5) - 1.5 * sin(z * 0.12345);
float y = cos(z) + 1.5 * sin(z * 0.3) + .2 * cos(z * 2.12345);
return vec2(x,y);
}

mat2 R;
float T;

float map (vec3 p)
{
vec2 o = path(p.z) / 5.0;
p = vec3(p.x,p.y,p.z)-vec3(o.x,o.y,0.);   
float r = 3.14159*sin(p.z*0.15)+T*0.25*2.;
R = mat2(cos(r), sin(r), -sin(r), cos(r));
p.xy *= R;    
p.xy *= (Rot (sin(time)*.9));
vec3 q = fract(p) * 2. - 1.;
float clampY = clamp(abs(sin((time*0.2)+1.)),.5,.70);
vec3 s = vec3(clampY,clampY,1.);
q.xy *= Rot(time);
float bd3= length (max (abs(q)-s,0.)); 
return bd3*.6;
}

float marchCount;

float trace(vec3 o, vec3 r)
{
float t = 0.0;
for(int i=0; i<64; i++){
vec3 p = o + r * t;
float d = map(p);       
if(d<.001 || abs(t)>100.) break;
t += d * 1.;
}
return t;
}

float traceRef(vec3 o, vec3 r){
float t = 0.0;
marchCount = 0.0;
for (int i = 0; i < 32; i++){
vec3 p = o + r * t;      
float d = map (p);      
if(d<.005 || abs(t)>100.) break;        
t += d * .1;
marchCount += 2.*d+.7;
}
return t;
}

vec3 GetNormal(vec3 p){
vec2 e = vec2(.00025, -.00025); 
return normalize(
e.xyy * map(p + e.xyy) + 
e.yyx * map(p + e.yyx) + 
e.yxy * map(p + e.yxy) + 
e.xxx * map(p + e.xxx));
}

void main(void)
{
vec2 uv = gl_FragCoord.xy/resolution.xy;
uv = uv * 2.0 - 1.0;    
uv.x *= resolution.x / resolution.y; 
vec3 r = normalize(vec3(uv,2.));   
float the = time *0.25;
vec2 a = path(time * 1.0)*1.0;
vec3 o = vec3(a / 5.0,time);   
float t = trace(o,r);  
o = r *t;       
vec3 sn = GetNormal(o);   
vec3 sceneColor = sn;   
vec3 r2 = reflect(r, sn*0.1);   
t += traceRef(o +  r2*.01, r2);
o = r2*t;   
sn += GetNormal(o);   
sceneColor += sn;   
vec3 fc = sceneColor;
float fog = 1. / (1. + t * t * 0.1);
fc = vec3(fog);
fc *= 0.0115;
fc += marchCount * vec3(0.1, 0.1,0.1) * 1.;
fc *= vec3(fog);
fc *= 0.5;
glFragColor = vec4(fc,1.0);   
}
