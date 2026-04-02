#version 420

// original https://www.shadertoy.com/view/tslfRj

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

mat2 rot (float r){
  return mat2(cos(r),sin(r),-sin(r),cos(r));
}

float cube(vec3 p,vec3 s){
  vec3 q = abs(p);
  vec3 m = max(s-q,0.);
  return length(max(q-s,0.))-min(min(m.x,m.y),m.z);
}

vec2 pmod(vec2 p,float n){
  float np = 3.141592*2./n;
  float r = atan(p.x,p.y)-0.5*np;
  r  =mod(r,np)-0.5*np;
  return length(p)*vec2(cos(r),sin(r));
}

float dist2(vec3 p){
    float k = 0.5;
    p.y += 0.1*sin(p.z*5.+time);
    p.xy *= rot(p.z*0.1);
    p.z += -time;
    
    
    p = mod(p,k)-0.5*k;
    float d;
    vec2 c = vec2(max(0.,length(p.xy)-0.0),max(abs(p.z)-0.04,0.));
    d = length(c);
    return d;
}

float dist(vec3 p){
    p.z += time;
    for(int i = 0;i<6;i++){
    float si = step(mod(time,6.),float(i));
    p.xy = mix(p.xy,p.xy*rot(0.3+step(0.6,fract(time))),si);
    p.yz = mix(p.yz,p.yz*rot(0.2+step(0.3,fract(time))),si);
    p = abs(p)-0.2;
  }

  p.xy = pmod(p.xy,6.);
  
  p.x -= 0.6;
  float k = 0.8;
  p = mod(p,k)-0.5*k;
 
  float s = 0.2-0.03;
  float d2 = cube(p,vec3(10.,0.05,0.05));
  float d3 = cube(p,vec3(0.05,0.05,10.));
  float d4 = cube(p,vec3(0.05,10.,0.05));
  return min(cube(p,vec3(0.2,0.2,s)),min(min(d2,d3),d4));
}

void main(void) {
  vec2 uv = gl_FragCoord.xy/resolution.xy;
  float s = 0.1;
  vec2 r=resolution.xy,p=(gl_FragCoord.xy*2.-r)/min(r.y,r.x);
  p *= rot(time);
  float radius = 0.1;
  float rkt = time*0.2;
  vec3 ro = vec3(cos(rkt)*radius,0.,sin(rkt)*radius);
  vec3 ta = vec3(0.,0.,0.);
  vec3 cdir = normalize(ta-ro);
  vec3 side = cross(cdir,vec3(0.,1.,0.));
  vec3 up = cross(side,cdir);
  float fov = 0.4;
  vec3 rd = normalize(p.x*side+p.y*up+cdir*fov);
  float d,t=0.5;
  float ac = 0.;
  float ac2 = 0.;
  for(int i = 0;i<76;i++){
    d = dist(ro+rd*t);
    float d2 = dist2(ro+rd*t);
    ac += exp(abs(d)*-.2)*step(d,d2);
    ac2 += 0.03/abs(d2)*step(d2,d);
      d = min(d,d2);
      if(d<0.001) break;
    t+=d;
  }
  vec3 col = vec3(0.);;
   col +=0.05*ac*vec3(1.0,0.5,0.1);
      col +=.1*ac2*vec3(1.,1.,1.);
  float near = 0.;
  float far = 7.;
  vec3 fcol = vec3(0.3,0.3,0.3);
  col = mix(fcol,col,clamp((far-t)/(far-near),0.0,1.0));
  float suv = 0.96;
  uv = (uv-0.5)*suv+0.5;
  vec2 sd = vec2(0.002,0.);
 
  col = clamp(col,0.,1.);
 
 
    col *= 1.5;
    glFragColor=vec4(col,1);
  
}
