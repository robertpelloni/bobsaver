#version 420

// original https://www.shadertoy.com/view/7sycWD

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define MAX_STEPS 100
#define MAX_DIST 100.
#define SURF_DIST .0001

#define PI 3.14159265

#define S smoothstep
#define T time

mat2 Rot(float a) {
  float s=sin(a), c=cos(a);
  return mat2(c, -s, s, c);
}

float sdBox(vec3 p, vec3 s) {
  p = abs(p)-s;
    return length(max(p, 0.))+min(max(p.x, max(p.y, p.z)), 0.);
}

float sdTorus(vec3 p, vec2 t) {
  float a = atan(p.x/p.z);
  float r = (cos(a*40.0+T*10.) + 1.0) / 2.0 * t.y * 0.12;
  vec2 q = vec2(length(p.xz)-t.x,p.y);
  return length(q)-t.y+r;
}

float Hash31(vec3 p) {
  return fract(sin(dot(p,vec3(21.221,49.122,80.121))*29.2491));
}

float GetDist(vec3 p) {
  // repetition
  float c = 2.;
  vec3 fp = mod(p+0.5*c,c)-0.5*c;
  vec3 ip = floor((p+0.5*c)/c);
  float rand = Hash31(ip);
  float flip = fract(rand*219.21)<.5 ? 1. : -1.;

  fp.xz *= Rot(PI*0.5*floor(rand*4.));
  fp.x *= flip;
  // fp.xz *= Rot(PI*0.5);
  
  float d1 = sdTorus(fp-vec3(c*0.5,0,c*0.5), vec2(c*0.5, c*0.1));

  fp.xz *= Rot(PI);
  fp.xy *= Rot(PI*0.5);
  float d2 = sdTorus(fp-vec3(c*0.5,0,c*0.5), vec2(c*0.5, c*0.1));

  fp.xz *= Rot(PI);
  fp.zy *= Rot(PI*0.5);
  float d3 = sdTorus(fp-vec3(c*0.5,0,-c*0.5), vec2(c*0.5, c*0.1));
  
  float d = min(d1,d2);
  d = min(d,d3);

  return d;
}

float RayMarch(vec3 ro, vec3 rd) {
    float dO=0.;
    
  for(int i=0; i<MAX_STEPS; i++) {
    vec3 p = ro + rd*dO;
    float dS = GetDist(p);
    dO += dS;
    if(dO>MAX_DIST || abs(dS)<SURF_DIST) break;
  }
  
  return dO;
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

vec3 GetRayDir(vec2 uv, vec3 p, vec3 l, float z) {
  vec3 f = normalize(l-p),
    r = normalize(cross(vec3(0,1,0), f)),
    u = cross(f,r),
    c = f*z,
    i = c + uv.x*r + uv.y*u,
    d = normalize(i);
  return d;
}

void main(void)
{
  vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
  
  vec3 ro = vec3(0, 0, -3);
  ro.yz *= Rot(sin(T*0.5)*1.0);
  ro.zx *= Rot(T*0.4);\
  vec3 lookAt = vec3(-10.*sin(T*.2), 0, -10.*cos(T*.1));
  
  vec3 rd = GetRayDir(uv, ro, lookAt, 1.);
  vec3 col = vec3(0);
  
  float d = RayMarch(ro, rd);

  if(d<MAX_DIST) {
    vec3 p = ro + rd * d;
    vec3 n = GetNormal(p);
    vec3 r = reflect(rd, n);
        
    float spec = pow(max(0., r.y), 100.);
    float dif1 = max(0.,dot(n, normalize(vec3(1,2,3))));
    float dif2 = max(0.,dot(n, normalize(vec3(-1,5,-1))));
    vec3 difCol1 = dif1 * vec3(.1, 0., .8);
    vec3 difCol2 = dif2 * vec3(0., 2., 0.);
    vec3 lightCol = vec3(0.0, 0.03, 0.07) + (difCol1 + difCol2) * exp(-d*d/100.);
    col = lightCol * vec3(1.) + spec * exp(-d*d/100.);
  }
  
  col = pow(col, vec3(.4545));    // gamma correction
  // col *= exp(-d*d/300.);
  
  glFragColor = vec4(col,1.0);
}
