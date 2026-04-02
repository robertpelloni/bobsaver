#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/tt23Wh

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*
Shader coded live on twitch (https://www.twitch.tv/nusan_fx)
The shader was made using Bonzomatic.
You can find the original shader here: http://lezanu.fr/LiveCode/GridBox.glsl

The shader uses analytical raytracing to find intersection with 2 boxes and a plane.
By bouncing rays you can get rough global illumination and depth of field by jittering the starting ray.
*/

//float time = 0.0;
float time2;
float pi = acos(-1.0);

mat2 rot(float a) {
  float ca=cos(a);
  float sa=sin(a);
  return mat2(ca,sa,-sa,ca);
}

float rnd(float t) {
  return fract(sin(t*685.655)*427.511);
}

float curve(float t, float d) {
  float g=t/d;
  return mix(rnd(floor(g)), rnd(floor(g)+1.0), pow(smoothstep(0.0,1.0,fract(g)), 8.0));
}

float val = 0.0;
//float val2 = max(abs(fract(time*0.1-0.5)-0.5)*4 - 1.0,0.0);
float val2 = 0.0;

float plane(vec3 s, inout float d, vec3 r, inout vec3 n, inout vec3 emi, vec3 planenorm, float dist) {
  
  float dn = dot(r,planenorm);
  float dplane = (dist-dot(s,planenorm))/dn;
  if(dplane<d && dplane>0.0) {
    vec3 p = s + dplane * r;
    vec3 hole = vec3(4);
    p = abs(fract(p/hole+0.5)-.5);
    if(max(p.x,max(p.y,p.z))>0.44) {
      d = dplane;
      n = planenorm * sign(dn);
      emi = vec3(0.2,0.9,0.5) * 5.0 * val2;
    }
  }
  
  return d;
}

void backbox(vec3 s, inout float d, vec3 r, inout vec3 n, inout vec3 emi, vec3 pos, vec3 size) {
  
  vec3 invd = 1.0/r;
  
  vec3 t0 = ((pos-size) - s) * invd;
  vec3 t1 = ((pos+size) - s) * invd;
  vec3 mi = min(t0, t1);
  vec3 ma = max(t0, t1);
  
  float front = min(min(ma.x,ma.y),ma.z);
  float back = max(max(mi.x,mi.y),mi.z);
  
  if(front<d && front > 0.0 && front>back) {
    d = front;
    n = (1.0-clamp((ma-front)*1000.0,0.0,1.0)) * sign(t1-t0);
    
    vec3 p = s + d * r;
    //vec2 diff=smoothstep(0.9,1.0, sin(p.zx + 10 * time * vec2(0.7,1.0)));
    
    //emi = vec3(dot(diff,vec2(1.0))) * step(p.y, -4.9) * 4;
    
    emi = vec3(0.4,0.5,0.9) * step(p.y, -4.9) * 4.0 * val * (1.0-val2);
    emi += vec3(0.8,0.4,0.3) * step(p.z, -9.9) * 4.0 * (1.0-val) * (1.0-val2);
  }
}

void frontbox(vec3 s, inout float d, vec3 r, inout vec3 n, inout vec3 emi, vec3 pos, vec3 size) {
  
  vec3 invd = 1.0/r;
  
  vec3 t0 = ((pos-size) - s) * invd;
  vec3 t1 = ((pos+size) - s) * invd;
  vec3 mi = min(t0, t1);
  vec3 ma = max(t0, t1);
  
  float front = min(min(ma.x,ma.y),ma.z);
  float back = max(max(mi.x,mi.y),mi.z);
  
  if(back<d && back > 0.0 && back<front) {
    d = back;
    emi = vec3(0);
    n = (1.0-clamp(-(mi-back)*10000.0,0.0,1.0)) * sign(t1-t0);
  }
}

void raytrace(vec3 s, inout float d, vec3 r, inout vec3 n, inout vec3 emi) {
  
  backbox(s,d,r,n,emi, vec3(0), vec3(10,5,10));
  
  frontbox(s,d,r,n,emi, vec3(7,3,0), vec3(5,0.5,4));
  
  plane(s,d,r,n,emi, normalize(vec3(curve(time2+3.2,0.8),1.0,curve(time2+7.8,0.8))), 2.0 + (curve(time2,0.8)-.5)*10.0);
}

vec3 hemispherenormal(vec2 rng) {
  
  float radius = sqrt(rng.x);
  float angle = 2.0 * pi * rng.y;
  
  return vec3(radius * cos(angle), sqrt(1.0 - rng.x), radius * sin(angle));
}

vec3 hemi(float rn, int i) {
  return hemispherenormal(fract(rn * vec2(7,17) + vec2(float(i)/7.0,floor(float(i/7))/7.0)));
}

vec2 rnd(vec2 uv) {
  return fract(sin(uv * vec2(754.355) + uv.yx * vec2(845.312)) * vec2(387.655));  
}

float rnd1(vec2 uv) {
  return fract(dot(sin(uv * vec2(754.355) + uv.yx * vec2(845.312)),vec2(387.655)));  
}

void cam(inout vec3 p) {
  float t=time*0.3 + curve(time2 +32.0, 2.8)*4.0;
  p.yz *= rot(sin(t*.7)*.3 + 0.4);
  p.xz *= rot(t);
  
}

void main(void)
{    
  vec2 uv = vec2(gl_FragCoord.x / resolution.x, gl_FragCoord.y / resolution.y);
  uv -= 0.5;
  uv /= vec2(resolution.y / resolution.x, 1);
    
  time2 = time * 0.2;
  val = max(abs(fract(time2*0.1)-0.5)*4.0 - 1.0,0.0);
  val2 = max(curve(time2, 1.3)*3.0-2.0,0.0);

  vec3 s=vec3(0,0,-12);
  vec3 t=vec3(0,0,0);
  
  cam(s);
  
  vec3 cz = normalize(t-s);
  vec3 cx = normalize(cross(cz, vec3(0,1,0)));
  vec3 cy = normalize(cross(cz, cx));
  //vec3 r=normalize(vec3(-uv, 1));
  float fov = 1.0 + curve(time2+11.0, 0.7)*0.4;
  vec3 r = normalize(uv.x * cx + uv.y * cy + fov * cz);
  
  
  vec3 col = vec3(0);
  
  float focus = 12.0 + curve(time2, 0.7)*4.0;
  
  float ini = rnd1(uv);
    
  float dither=fract(time2);
    
  const int steps=36;
  for(int j=0; j<steps; ++j) {
    float prod = 1.0;
    vec2 randdof = vec2(j%6,j/6)+rnd(uv - vec2(3.7));
    //randdof = vec2(cos(randdof.x), sin(randdof.x))*randdof.y;
    vec3 dof = randdof.x * cx + randdof.y * cy;
    dof *= 0.1;
    vec3 vs = s + dof;
    vec3 vr = normalize(r - dof / focus);
        
    for(int i=0; i<3; ++i) {
      float d = 10000.0;
      vec3 n = vec3(0,1,0);
      vec3 emi = vec3(0);
      raytrace(vs, d, vr, n, emi);
      vs = vs + vr * d - n * 0.001;
      
      vec2 rand = rnd(uv + vec2(float(j)*2.1,float(i)*3.1) + dither);
      vr = hemispherenormal(rand);
      //vr = hemi(ini, j);
      vr *= -sign(dot(vr,n));
      
      col += emi * prod;
      prod *= 0.6;
      
    }
  }
  col /= float(steps);
    
  /*
  if(d<9000.0) {
    vec3 p = s + d * r;
    col += fract(p/1.0 + 0.1);
  }
  */
  
  //col = n*0.5+0.5;
  
  
  /*
  float d = plane(s,r, normalize(vec3(0,1,0)), 10);
  if(d>0.0) {
    vec3 p=s + d * r;
    
  }
  */
  
  glFragColor = vec4(col, 1);
}
