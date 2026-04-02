#version 420

// original https://www.shadertoy.com/view/3s2BWW

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Based on Art_of_code's youtube tutorial on Gyroids.
// https://www.youtube.com/watch?v=-adHIyjIYgk
precision mediump float;

#define MAX_STEPS 100
#define SURFACE_DIST.001
#define MAX_DIST 200.

float sdSphere(vec3 p, vec4 sphere){
  return length(p-sphere.xyz)-sphere.w;
}

float sdBox(vec3 p, vec3 box){
  p = abs(p)-box;
  return length(max(p, 0.))+min(max(p.x, max(p.y, p.z)),0.);
}

float sdGyroid(vec3 p, float scale, float thickness, float bias, float xamp, float yamp){
    p *= scale;
    return abs(dot(sin(p)*xamp, cos(p.zxy)*yamp)-bias)/scale-thickness;
}
float GetDist(vec3 p){
  //float box = sdSphere(p, vec4(vec3(0),3.4));
  // p = abs(p);
  float box = sdBox(p-vec3(0,0,0), vec3(2.5));
  //float planed=p.y;
  float t = time/12.;
  float gyroid = sdGyroid(p, 10., min(.12,.1*sin(time)+.11), -1.4,2.*sin(t), cos(t));
  // float gyroid2 = sdGyroid(p-.1, 21.);

  float d = max(box, gyroid*.7);
  // d = max(d-.05, gyroid2);
  return d;
}

vec3 GetNormal(vec3 p){
  vec2 e=vec2(.01,0);
  float d=GetDist(p);
  vec3 n=d-vec3(GetDist(p-e.xyy),GetDist(p-e.yxy),GetDist(p-e.yyx));
  return normalize(n);
}

mat4 RotationX(float angle){
  return mat4(1.,0,0,0,
    0,cos(angle),-sin(angle),0,
    0,sin(angle),cos(angle),0,
  0,0,0,1);
}

mat4 RotationY(float angle){
  return mat4(cos(angle),0,sin(angle),0,
  0,1.,0,0,
  -sin(angle),0,cos(angle),0,
0,0,0,1);
}

mat4 RotationZ(float angle){
  return mat4(cos(angle),-sin(angle),0,0,
    sin(angle),cos(angle),0,0,
    0,0,1,0,
    0,0,0,1);
}

mat2 Rot2d(float a) {
    float s = sin(a);
    float c = cos(a);
    return mat2(c, -s, s, c);
}

float RayMarch(vec3 ro,vec3 rd){
  float dO=0.;
  for(int i=0;i<MAX_STEPS;i++){
    vec3 p=ro+dO*rd;
    float ds=GetDist(p);
    dO+=ds;
    if(dO<SURFACE_DIST||dO>MAX_DIST){
      break;
    }
  }
  return dO;
}

float GetLight(vec3 p){
  mat4 r = RotationY(time);
  vec4 lpos=vec4(1,2,3,1)*r;
  
  vec3 l=normalize(lpos.xyz-p);
  vec3 n=GetNormal(p);
  float diff=dot(n,l)*.5+.5;
  float d=RayMarch(p+n*.02,l);
  if(d<length(lpos.xyz-p)){
    diff*=.4;
  }
  return diff;
}

vec3 GetRayDir(vec2 uv, vec3 p, vec3 l, float z) {
    vec3 f = normalize(l-p),
        r = normalize(cross(vec3(0,1,0), f)),
        u = cross(f,r),
        c = p+f*z,
        i = c + uv.x*r + uv.y*u,
        d = normalize(i-p);
    return d;
}

void main(void) {
  vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
  vec3 color=vec3(0);
  
  float t = time/10.;
  // camera
  vec3 ro = vec3(0, 3, -2);
  
    ro.yz *= Rot2d(t*3.14+1.);
    ro.xz *= Rot2d(t*6.2831);
  

  vec3 rd=GetRayDir(uv, ro, vec3(0),1.);

  // trace scene
  float d=RayMarch(ro,rd);

  // material
  vec3 p=ro+rd*d;
  vec3 n = GetNormal(p);
  float diffuse=GetLight(p);
  float o=0.;
  color=vec3(diffuse-o);
  color.rg += n.xy*.2-d*.05;
  glFragColor=vec4(color,1.);
}
