#version 420

// original https://www.shadertoy.com/view/wljGRd

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*
Shader coded live on twitch (https://www.twitch.tv/nusan_fx)
Original Bonzomatic shader can be found here: http://lezanu.fr/LiveCode/LostTree.glsl
*/

#define time time

mat2 rot(float a) {
  float ca=cos(a);
  float sa=sin(a);
  return mat2(ca,sa,-sa,ca);
}

float noise(vec3 p) {
  vec3 ip=floor(p);
  p=fract(p);
  p=smoothstep(0.0,1.0,p);
  vec3 st=vec3(7,137,235);
  vec4 val=dot(ip,st) + vec4(0,st.y,st.z,st.y+st.z);
  vec4 v = mix(fract(sin(val)*5672.655), fract(sin(val+st.x)*5672.655), p.x);
  vec2 v2 = mix(v.xz,v.yw, p.y);
  return mix(v2.x,v2.y,p.z);
}

float tri(float t) {
  return abs(fract(t)-0.5);
}

float smin(float a, float b, float h) {
  float k=clamp((a-b)/h*.5+.5,0.0,1.0);
  return mix(a,b,k) - k*(1.0-k)*h;
}

vec3 light=vec3(6,0,0);

float at=0.0;
float at2=0.0;
float map(vec3 p) {
  
  vec3 bp=p;
  
  p.xz *= sign(p.y);
  
  float trunk = step(bp.y,0.0);
  
  p.y=-abs(p.y);
  
  float t=time*2.0;
  float rotamount = trunk*0.5+0.5;
  float rot2 = 0.3 + (1.0-trunk)*0.2;
  float noi = 1.0 + (1.0-trunk)*2.0;
  p.xy *= rot(sin(t*0.5) * 0.2 * p.y * rotamount);
  p.zy *= rot(sin(t*0.6) * 0.25 * p.y * rotamount);
  
  p.y += 0.53;
  
  
  p+=(noise(p*6.0)-.5)*0.05 * noi;
  p+=(noise(p*2.0)-.5)*0.2 * noi;  
  vec3 bp2=p;
    
  float d = 10000.0;
  for(int i=0; i<7; ++i) {
    p.xz = abs(p.xz);
    float sizey = 0.2 - 0.005*float(i) - (1.0-trunk)*0.03;
    float sizex = 0.53 - 0.07*float(i);
    d = min(d, max(length(p.xz)-0.1*sizex, abs(p.y-sizey)-sizey));
    p.xy *= rot(rot2);
    p.zy *= rot(rot2);
    p.y += sizey*1.9;    
  }
  
  d = min(d, max(length(p.xz)-0.01, abs(p.y-0.3)-0.3));
  
  d += (1.0-trunk)*0.007;
    
  float leaf = length(p-vec3(0,0,0.1))-0.2;
  leaf = max(leaf, 0.3-length(p-vec3(0,0.31,0)));
  
  leaf += -0.1+noise(bp2*3.0)/7.0 + (1.0-trunk);
    
  d = min(d, leaf);
  d *= 0.5;
  
  float planet = length(bp-vec3(0,3,0))-3.2;
  float tris = tri(bp.x)*0.2 + tri(bp.z*0.7+.2)*0.3 + tri(bp.z*1.8+.2)*0.1;
  float pdist = 5.6 + tris;
  planet = max(planet, pdist-length(bp-vec3(0,6.0,0)));
  d=min(d, planet);
  
  float ast = (length(bp-light) - 1.0);
  at += 0.2/(0.2+ast);
  
  float ast2 = (length(bp+light) - 1.2);
  at2 += 0.2/(0.2+ast2);
  
  d=min(d, ast*0.6);
  d=min(d, ast2*0.6);
    
  return d;
}

void cam(inout vec3 p) {
  
  p.yz *= rot(sin(time*.5)*0.4-0.2);
  p.xz *= rot(time*0.2);
  
}

vec3 sky(vec3 r) {
  return mix(vec3(0), vec3(0.5,0.6,1.0), pow(clamp(-r.y*0.5+0.7,0.0,1.0),5.0));
}

float getao(vec3 p, vec3 n, float d) {
  return clamp(map(p+n*d)/d,0.0,1.0)*0.5+0.5;
}

void main(void)
{    
    
  vec2 uv = vec2(gl_FragCoord.x / resolution.x, gl_FragCoord.y / resolution.y);
  uv -= 0.5;
  uv /= vec2(resolution.y / resolution.x, 1);

  vec3 s=vec3(0,0,-8);
  vec3 r=normalize(vec3(-uv, 0.8));
  
  cam(s);
  cam(r);
  
  s.y -= 1.0;
  
  
  
  light.xy *= rot(time);
  light.yz *= rot(time*.7);
  
  vec3 p=s;
  float i=0.0;
  bool outside = false;
  for(i=0.0; i<100.0; ++i) {
    float d=map(p);
    if(d<0.001) {
      i += d/0.001;
      break;
    }
    if(d>100.0) {
      outside = true;
      break;
    }
    p+=r*d;
  }
  
  
  vec3 col = vec3(0);
  
  vec3 lcol = vec3(1.0,0.7,0.2);
  vec3 lcol2 = vec3(0.3,1.0,0.5);
  
  col += pow(at * 0.1,0.6) * 0.8*lcol;
  col += pow(at2 * 0.1,0.6) * 0.4*lcol2;
  
  float fog=1.0-clamp(length(p-s)/100.0,0.0,1.0);
  
  vec2 off=vec2(0.01,0);
  vec3 n=normalize(map(p)-vec3(map(p-off.xyy), map(p-off.yxy), map(p-off.yyx)));
  
  vec3 l = normalize(light-p);
  
  float fre = pow(1.0-abs(dot(n,r)), 4.0);
  
  float ao = pow(getao(p, n, 1.0) * getao(p, n, 0.5) * pow(getao(p, n, 0.05),3.0), 0.4);
  
  // hack: if close to one of the lights, we direct the normal toward the light to get full illumination
  if(length(light-p)<2.0) n = l;
  if(length(-light-p)<2.0) n = -l;
  
  col += max(0.0, dot(n,l)) * fog * lcol * 40.0 * ao / pow(length(light-p),2.0);
  col += max(0.0, dot(n,-l)) * fog * lcol2 * 30.0 * ao / pow(length(-light-p),2.0);
   
  
  if(outside) {
    col += sky(r);
    vec3 stars = vec3(smoothstep(0.0,1.0,noise(r*53.0)), smoothstep(0.0,1.0,noise(r*33.0)), smoothstep(0.0,1.0,noise(r*127.0)));
    stars = mix(vec3(1.0), pow(stars, vec3(10.0)), 0.7);
    col += vec3(6) * smoothstep(0.9,1.0,noise(r*120.0)) * stars;
  } else {
    col += sky(reflect(r,n)) * fre * ao;
    col += sky(n) * fre * ao;
  }
    
  glFragColor = vec4(col, 1);
}
