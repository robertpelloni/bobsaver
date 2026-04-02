#version 420

// original https://www.shadertoy.com/view/wsyGzV

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec3 n;
vec3 lightPos;

float smin(float a, float b, float k)
{
 float h = clamp (0.5+0.5*(b-a)/k,0.,1.);
 return mix(b, a, h) - k*h*(1.0-h);       
}

float gyroid ( vec3 p, float s )
{
 return sin(p.x*s)*cos(p.y*s) + sin(p.y*s)*cos(p.z*s) + sin(p.z*s)*cos(p.x*s);
}

float GetDist (vec3 p) 
{
 float ogGyroid= gyroid(p-vec3(-2.,4.,4.),0.65);
 float d;
 float one = ogGyroid;
 float s = .5;
 p.xz +=sin(time)*cos(time*0.2);
 p.y += time*2.;
 float two = ((dot(cos(p.zxy), cos(p.zzy*s))));
 s =4.;
 float three = (abs(dot(sin(p), cos(p.zzz*s)))*.2);
 two = mix(two, three, sin(.0)*.5+.5);
 one = smin(one, two,-1.5);
 d = one;
 return  one ;
}

float marchCount;

float RayMarch (vec3 ro, vec3 rd) 
{
 float dO = 0.;
 marchCount = 0.0;
 for (int i=0; i<94; i++) 
 {
  vec3 p = ro + dO * rd;
  float dS = GetDist (p);
  dO += dS*1.;
  marchCount+= 5.*dS*.001;
  if (dS<.01 || dO>80.) break;
  }
 return dO;
}

float traceRef(vec3 o, vec3 r)
{
 float t = 0.0;
 for (int i = 0; i < 48; i++)
  {
   vec3 p = o + r * t;
   float d = GetDist (p);
   if(d<.002 || t>80.) break;
   t += d * 1.;            
  }
 return t;
}

vec3 GetNormal(vec3 p){
 vec2 e = vec2(.0035, -.0035); 
 return normalize(
  e.xyy * GetDist(p + e.xyy) + 
  e.yyx * GetDist(p + e.yyx) + 
  e.yxy * GetDist(p + e.yxy) + 
  e.xxx * GetDist(p + e.xxx));
}

float GetLight(vec3 p)
{
 vec3 LightPos = vec3(1, 2, time*1.+10.);
 LightPos.xz += vec2(sin(time),cos (time)*3.);
 vec3 L = normalize(LightPos -p);
 n = GetNormal (p);   
 float dif = clamp(dot(n, L), 0. , 1.);
 float d = RayMarch(p+n*.01*10.,L);
 if (d<length(LightPos-p)) dif *= 1.;
 return dif;       
}

void main(void)
{
 vec2 uv = (gl_FragCoord.xy -.5*resolution.xy) / resolution.y;
 vec3 ro; 
 ro =vec3(1,5,time*1.);
 vec3 rd = normalize(vec3(uv.x,uv.y,.4));
 float the = time *0.25;
 //camera movement  
 // rd.yz *= mat2(cos(the), -sin(the), sin(the), cos(the));
 // rd.xz *= mat2(cos(the), -sin(the), sin(the), cos(the));      
 float d = RayMarch (ro,rd);
 vec3 p = ro + rd *d;
 vec3 sn = GetNormal(p);
 vec3 x = sn;
 rd = reflect(rd, sn);
 d = traceRef(ro +  rd*1.5, rd);
 ro += rd*d;
 sn = GetNormal(ro);
 x += sn;
 vec3 col =x;
 float dif = GetLight (p); 
 col = vec3(dif);
 col *= 0.25;
 col += marchCount * vec3(0.2,.2,0.01) * 10.;
 col +=vec3(0.7,abs(sin(time*p.y*0.0002)),0.4);
 col +=vec3((smoothstep(-.5,1.,sin(-time*0.1+p.xzz*.2)))-1.);
 float fog = 1. / (1. + d * d * 2.);
 col += vec3(fog);
 col *= 1.15;
 fog = 1. / (2. + d * d * 0.01);
 glFragColor = vec4(col,1.0);
}
