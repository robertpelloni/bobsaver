#version 420

// original https://www.shadertoy.com/view/wsV3Ww

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//based partly on the techniques used in: https://www.shadertoy.com/view/WtfXzB, by bigwings

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
  float ogGyroid= gyroid(p-vec3(-2.,4.,4.),0.55);
  float d;
  float one = ogGyroid;
  float s = .2;
  p.xz +=sin(time)*cos(time*0.2);
  p.y += time*2.;
  float two = ((dot(cos(p.zxy), cos(p.zxy*s))));
  s = 5.;
  float three = (abs(dot(sin(p), cos(p.zxy*s)))*0.3);
  two = mix(two, three, sin(.2)*.5+.5);  
  one = smin(one, two,-2.);
  d = one;
  return  one ;
}

float marchCount;

float RayMarch (vec3 ro, vec3 rd) 
{
 float dO = 0.;        
 marchCount = 0.0; 
 for (int i=0; i<64; i++) 
    {
     vec3 p = ro + dO * rd;
     float dS = GetDist (p);
     dO += dS*.35;
     marchCount+= 15.*dS*.005;
     if (dS<.001 || dO>80.) break;
    }
 return dO;
}
 
vec3 GetNormal(vec3 p){
 float d = GetDist(p);
 vec2 e = vec2(-2.1,1);
 vec3 n = d - vec3(
  GetDist(p-e.xyy),
  GetDist(p-e.yxy),
  GetDist(p-e.yyx));
 return normalize(n);
}

vec3 n;

float GetLight(vec3 p)
{
    vec3 LightPos = vec3(1, 2, time*5.+10.);
    LightPos.xz += vec2(sin(time),cos (time)*3.);
    vec3 L = normalize(LightPos -p);
    n = GetNormal (p);
    float dif = clamp(dot(n, L), 0. , 1.);
    float d = RayMarch(p+n*.001*10.,L);
    if (d<length(LightPos-p)) dif *= 5.;
    return dif;     
}

void main(void)
{
   vec2 uv = (gl_FragCoord.xy -.5*resolution.xy) / resolution.y;
   vec3 col = vec3(0);
   vec3 ro; 
   ro =vec3(1,5,time*5.);
   vec3 rd = normalize(vec3(uv.x,uv.y,.4));
   float the = time *0.15;
   rd.yx *= mat2(cos(the), -sin(the), sin(the), cos(the));
   rd.xz *= mat2(cos(the), -sin(the), sin(the), cos(the));
   rd.yz *= mat2(cos(the), -sin(the), sin(the), cos(the));       
   float d = RayMarch (ro,rd);
   vec3 p = ro + rd *d;
   float dif = GetLight (p); 
   col = vec3(dif);     
   col *= 0.25;
   col += marchCount * vec3(0.,.2,0.01) * 2.;
   col +=vec3(0.7,abs(sin(time*p.y*0.00002)),0.4); 
   col +=vec3((smoothstep(-0.,1.,sin(-time*0.1+p.zzz*.2)))-.9);
   float fog = 1. / (1. + d * d * 0.025);
   col *= vec3(fog);
   vec3 sky = vec3(0., .2, .2);
   col = mix(sky, col, .8/(d*d/80./80.*3. + 1.));
   col *= 1.5;
   glFragColor = vec4(col,1.0);
   }
