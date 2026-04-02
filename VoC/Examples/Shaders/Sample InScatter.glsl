#version 420

// original https://www.shadertoy.com/view/NdGXDy

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

precision highp float;
const float PI=3.141592;

mat2 rot(float t){
  return mat2(cos(t),-sin(t),sin(t),cos(t));
}

float sphere(vec3 p){
  p.xz=mod(p.xz, 4.)-2.;
  return length(p-vec3(0.,1.,0))-1.;
}

float plane(vec3 p){
  return p.y;
}

float map(vec3 p){
  return min(sphere(p),plane(p));
}

vec3 normal(vec3 p){
  vec2 e=vec2(1,0)*0.01;
  return normalize(vec3(
    map(p+e.xyy)-map(p-e.xyy),
    map(p+e.yxy)-map(p-e.yxy),
    map(p+e.yyx)-map(p-e.yyx)
    ));
}

// https://blog.mmacklin.com/2010/06/10/faster-fog/
float InScatter(vec3 start, vec3 dir, vec3 lightPos, float d)
{
   vec3 q = start - lightPos;
   float b = dot(dir, q);
   float c = dot(q, q);
   float s = 1.0 / max(0.001,sqrt(c - b*b));
   float x = d*s;
   float y = b*s;
   float l = s * atan(x/max(0.001,1.+(x+y)*y));
   return l;
}

void main(void)
{
  vec2 st = (gl_FragCoord.xy - resolution.xy * 0.5)/min(resolution.x,resolution.y);
  vec3 col;
  vec3 cam=vec3(0,4,0);
  cam.z += time;
  vec3 ray=cam;
  vec3 dir=normalize(vec3(st,.5));
  dir.yz *= rot(0.3);

  vec3 lightpos = vec3(0,8,-4);
  lightpos.xz *= rot(time);
  lightpos.z += cam.z+16.;

  float totald=0.;
  for(int i=0;i<128;i++)
  {
    float d = map(ray);
    if (d<0.001)
    {
      vec3 n=normal(ray);
      vec3 l=normalize(lightpos-ray);
      float lightDist = length(lightpos-ray);
      vec3 lightColor = vec3(1,1,1)/(lightDist*lightDist)*10.;
      col=lightColor*max(0.,dot(n,l));
      float ocr=.6;
      float oc=max(0.,1.-map(ray+l*ocr)/ocr);
      oc=exp(-2.*pow(oc,2.));
      col*=oc;
      break;
    }
    totald+=d;
    ray += dir*d;
  }

  float s = InScatter(cam, dir, lightpos,totald);
  float fog=0.01;
  col*=exp(-totald*fog);
  col+= s;
  glFragColor = vec4(col,1);
}
