#version 420

// original https://www.shadertoy.com/view/MtVyWK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Created by mrange/2018
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
// 
// Messing around with reflections and fractals. I am quite new to shader programming
//  and raymarching so while I think the code might not be very good I also think that
//  what makes ShaderToy.com so good is that programmers are sharing what they do, 
//  big and small. I too want to share in the hope it might help someone on my level.
// 
// Inpiration and code from shaders:
//  https://www.shadertoy.com/view/4ds3zn (iq, fractal)
//  https://www.shadertoy.com/view/XljGDz (otaviogood, "skybox")
//  https://www.shadertoy.com/view/Xl2GDW (purton, inspiration for reflection)
// Blogs:
//  Raymarching explained: http://9bitscience.blogspot.com/2013/07/raymarching-distance-fields_14.html
//  Distance Estimators: www.iquilezles.org/www/articles/distfunctions/distfunctions.htm
//  Cool primitives: http://mercury.sexy/hg_sdf/

#define TOLERANCE       0.0005
#define MAX_RAY_LENGTH  64.0
#define MAX_BOUNCES     4
#define MAX_RAY_MARCHES 160
#define APOLLO          7

#define AA              1 // Set to 0 if the framerate is low

#define FADEINTIME      3.0
#define FADEOUTTIME     42.0

vec3 saturate(in vec3 a)   { return clamp(a, 0.0, 1.0); }
vec2 saturate(in vec2 a)   { return clamp(a, 0.0, 1.0); }
float saturate(in float a) { return clamp(a, 0.0, 1.0); }

void pR(inout vec2 p, float a) { p = cos(a)*p + sin(a)*vec2(p.y, -p.x); }

float maxComp(in vec3 p) { return max(p.x,max(p.y,p.z)); }

float sdSphere(in vec3 p, in float r) { return length(p) - r; }

float sdBox(vec3 p, vec3 b)
{
  vec3  di = abs(p) - b;
  float mc = maxComp(di);
  return min(mc,length(max(di,0.0)));
}

float sdCross(in vec3 p, float r)
{
  float xz = length(p.xz) - r;
  float xy = length(p.xy) - r;
  float yz = length(p.yz) - r;
    
  return min(min(xz, xy), yz);
}

float hollowBox(in vec3 p)
{
  float s = 10.0;
  p /= s;
  float t = time;
  pR(p.xz, -t);
  pR(p.xy, t/3.0);
  pR(p.yz, t/5.0);
  
  float d = max(sdBox(p, vec3(1.0)), -sdCross(p, 0.9));

  return s*d;
}

float apollian(vec3 p, float s)
{
  float scale = 1.0;

  for(int i=0; i<APOLLO;i++)
  {
    p        = -1.0 + 2.0*fract(0.5*p+0.5);

    float r2 = dot(p,p);
        
    float k  = s/r2;
    p       *= k;
    scale   *= k;
  }
    
  return 0.25*abs(p.y)/scale;
}

float obj(in vec3 p, out vec3 col, out float ref)
{
  p = vec3(p.z, p.y, p.x);
  col = vec3(0.75);  
  ref = 0.4;
    
  float b = sdBox(p, vec3(0.45, 0.5, 1.0));
  if(b >= TOLERANCE*100.0)
  {
    return b;
  }
  else
  {
    float a = apollian(p - vec3(0.0, -0.5, 0.0), 1.17);
    
    float rr = 0.24;
    float s0 = sdSphere(p - vec3(0.45, -0.2, 0.0), rr);
    float s1 = sdSphere(p - vec3(-0.45, -0.2, 0.0), rr);
    float s  = min(s0, s1);
  
    return max(b, max(a, -s));
  }
}

float distanceField(in vec3 p, out vec3 col, out float ref)
{
  float i   = obj(p, col, ref);

  float c   = sdBox(p - vec3(0.0, -0.7 + 0.01, 0.0), vec3(2.0, 0.2, 2.0));

  float s   = min(i, c);
    
  float hb  = hollowBox(p);

  s = min(s, hb);

  if (s == c)
  {
    col = vec3(0.75);  
    ref = 0.4;
  }
  else if (s == hb)
  {
    col = vec3(0.2);  
    ref = 0.0;
  }

  return s;

}

const vec3 lightPos1 = 20.0*vec3(-0.3, 0.15, 1.0);
const vec3 lightPos2 = 20.0*vec3(-0.33,  -0.2, -1.0);
const vec3 lightCol1 = vec3(8.0/8.0,7.0/8.0,6.0/8.0);
const vec3 lightCol2 = vec3(8.0/8.0,6.0/8.0,7.0/8.0);

vec3 getSkyColor(in vec3 rayDir)
{
  vec3 lightDir1 = normalize(lightPos1);
  vec3 lightDir2 = normalize(lightPos2);
  float ld1      = max(dot(lightDir1, rayDir), 0.0);
  float ld2      = max(dot(lightDir2, rayDir), 0.0);
  vec3 final     = vec3(0.125);

  if ((rayDir.y > abs(rayDir.x)*1.0) && (rayDir.y > abs(rayDir.z*0.25))) final = vec3(2.0)*rayDir.y;
  float roundBox = length(max(abs(rayDir.xz/max(0.0,rayDir.y))-vec2(0.9, 4.0),0.0))-0.1;
  final += vec3(0.8)* pow(saturate(1.0 - roundBox*0.5), 6.0);
  
  final += pow(lightCol1, vec3(2.0, 1.5, 1.5)) * pow(ld1, 8.0);
  final += lightCol1 * pow(ld1, 200.0);
  final += pow(lightCol2, vec3(2.0, 1.5, 1.5)) * pow(ld2, 8.0);
  final += lightCol2 * pow(ld2, 200.0);
  return final;
}

vec3 normal(in vec3 pos)
{
  vec3 col;
  float ref;
  vec3  eps = vec3(.0001,0.0,0.0);
  vec3 nor;
  nor.x = distanceField(pos+eps.xyy, col, ref) - distanceField(pos-eps.xyy, col, ref);
  nor.y = distanceField(pos+eps.yxy, col, ref) - distanceField(pos-eps.yxy, col, ref);
  nor.z = distanceField(pos+eps.yyx, col, ref) - distanceField(pos-eps.yyx, col, ref);
  return normalize(nor);
}

float rayMarch(in vec3 ro, inout vec3 rd, in float mint, in float maxt, out int rep, out vec3 col, out float ref)
{
  float t = mint;
  for (int i = 0; i < MAX_RAY_MARCHES; i++)
  {
    float distance = distanceField(ro + rd*t, col, ref);
    float tolerance = TOLERANCE * t;
    if (distance < TOLERANCE || t > maxt) break;
    t += max(distance, 0.001);
    rep = i;
  }
  return t;
}

vec3 render(in vec3 ro, in vec3 rd)
{
  vec3 col    = vec3(0.0);
  float ragg2 = 1.0;
    
  for (int i = 0; i < MAX_BOUNCES; ++i)
  {
    if (ragg2 < 0.01) break;
    vec3 mat    = vec3(0.0);
    float rscale= 0.0;
    int rep     = 0;
    float t     = rayMarch(ro, rd, 0.01, MAX_RAY_LENGTH, rep, mat, rscale);
  
    vec3 pos    = ro + t*rd;
    vec3 nor    = vec3(0.0, 1.0, 0.0);
    
    if (t < MAX_RAY_LENGTH)
    {
      // Ray intersected object
      nor = normal(pos);
    }
    else
    {
      // Ray intersected sky
      col += ragg2*getSkyColor(rd);
      break;
    }

    float occ = pow(1.0 - float(rep)/float(MAX_RAY_MARCHES), 1.5);

    vec3 ref  = reflect(rd, nor);
      
    vec3 ld1  = normalize(lightPos1 - pos);
    float dif1= max(dot(nor,ld1),0.0);

    vec3 ld2  = normalize(lightPos2 - pos);
    float dif2= max(dot(nor,ld2),0.0);
      
    vec3 acol = vec3(0.0);
    acol      += pow(dif1*lightCol1, vec3(0.5));
    acol      += pow(dif2*lightCol2, vec3(0.5));
    acol      *= occ;
    acol      = saturate(acol);
    acol      = pow(acol, vec3(2.0));
    acol      *= mat;
    
    col        += ragg2*acol*(1.0 - rscale);
    ragg2      *= rscale;

    ro        = pos;      
    rd        = ref;
  }
    
 
  return col;
}

vec3 getSample(in vec2 p)
{
  float z = 4.0*(1.0 - smoothstep(0.0, 20.0, time)) + 0.55;
  vec3 ro = vec3(0.0, -0.25 + 0.5*(z - 0.55), z);
  vec3 la = vec3(0.0, -0.25, 0.25);
  pR(ro.xz, time/4.0);
    
  vec3 ww = normalize(la - ro);
  vec3 uu = normalize(cross( vec3(0.0,1.0,0.0), ww ));
  vec3 vv = normalize(cross(ww,uu));
  vec3 rd = normalize( p.x*uu + p.y*vv + 2.5*ww );

  return render(ro, rd);
}

void main(void)
{
  vec2 q=gl_FragCoord.xy/resolution.xy; 
  vec2 p = -1.0 + 2.0*q;
  p.x *= resolution.x/resolution.y;

#if AA == 0
  vec3 col = getSample(p);
#elif AA == 1
  vec3 col  = vec3(0.0);
  vec2 unit = 1.0/resolution.xy;
  for(int y = 0; y < 2; ++y)
  {
    for(int x = 0; x < 2; ++x)
    {
      col += getSample(p - 0.5*unit + unit*vec2(x, y));
    }
  }

  col /= 4.0;
#endif

  float fadeIn = smoothstep(0.0, FADEINTIME, time);
  //float fadeOut = 1.0 - smoothstep(FADEOUTTIME, FADEOUTTIME + FADEINTIME, time);
  float fadeOut = 1.0;

  glFragColor = vec4(col*fadeIn*fadeOut, 1.0);
}

