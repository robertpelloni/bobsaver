#version 420

// original https://www.shadertoy.com/view/WtlXD7

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*
Shader coded live on youtube:
https://www.youtube.com/watch?v=zakmqumh8Rc
The shader was made using Bonzomatic.
You can find the original shader here: http://lezanu.fr/LiveCode/ThroughTheBars.glsl
(yes I still put [twitch] as a generic tag for live streaming ...)
*/

#define time time
#define rep(p,s) (fract(p/s-0.5)-0.5)*s

float box(vec3 p, vec3 s) {
  p=abs(p)-s;
  return max(p.x, max(p.y,p.z));
}

mat2 rot(float a) {
  float ca=cos(a);
  float sa=sin(a);
  return mat2(ca,sa,-sa,ca);  
}

float donut(vec3 p, float r1, float r2) {
  
  return length(vec2(length(p.xy)-r1,p.z))-r2;
  //return max(abs(length(p.xy)-r1)-r2,abs(p.z)-r2*0.5);
  
}

float grid(vec3 p) {
  
  
  vec3 p2 = p;
  p2.y = (fract(p.y)-0.5);
  float d = box(p2, vec3(10.0,0.2,0.05));
  
  p.x = (fract(p.x)-0.5);
  
  d = min(d, box(p, vec3(0.2,5,0.05)));
  
  return d;
}

float chain(vec3 p) {
  
  vec3 p2 = p-vec3(0,1.5,0);
  p.y = rep(p.y,0.6);
  p2.y = rep(p2.y,0.6);
  float d = donut(p, 0.2,0.05);
  d = min(d, donut(p2.zyx, 0.2,0.05));
  
  return d;
}

float map(vec3 p) {
  
  float d = 10000.0;//length(p-vec3(0,-1.5,-1.5))-0.8;
  
  // floor
  d = min(d, -box(p-vec3(0,-2.5,0), vec3(10,4,10)));
  
  d = min(d, grid(p));
    
  // kifs for chains
  for(int i=0; i<4; ++i) {    
    float t=0.7 + float(i)*13.742;
    p.xy *= rot(t);    
    p.yz *= rot(0.2);
    p.xy=abs(p.xy);
    p.x-=1.7;
  }
  p.x = rep(p.x, 1.4);
  
  //p.z -= 1;
  
  d = min(d, chain(p));
  
  p.z += 1.0;
  
  
  return d;
}

float rnd(vec2 uv) {
  return fract(dot(sin(uv*754.655+uv.yx*942.742),vec2(3847.554)));
}

float rnd(float t) {
  return fract(sin(t*472.355)*655.644);
}

float curve(float t) {
  return mix(rnd(floor(t)), rnd(floor(t)+1.0), smoothstep(0.0,1.0,fract(t)));  
}

// unused in the final shader
vec3 volumetric(vec3 p) {
  
  vec2 uv = p.xz * 0.5;
  
  vec3 col = vec3(0);
  vec2 grid = smoothstep(0.31,0.3,abs(fract(uv)-0.5));
  vec2 cell = floor(uv);
  col += min(grid.x, grid.y);
  col *= vec3(rnd(cell),rnd(cell+72.23),rnd(cell+14.37));
  
  col *= curve(time*4.0 + rnd(cell)*98.62);
  
  col *= pow(clamp((p.y+1.0)*0.5,0.0,1.0),2.0);
  
  return col;
}

void cam(inout vec3 p) {
  
  p.yz *= rot(sin(time*0.4)*0.4+0.2);
  p.xz *= rot(sin(time*0.13)*1.3);
  
}

float shadow(vec3 p, vec3 l, float maxdist, int stepcount, float limit) {
  float shad=1.0;
  float dd=0.0;
  for(int i=0; i<stepcount; ++i) {
    float d=min(map(p), maxdist);
    if(d<limit) {
      shad=0.0;
      break;
    }
    if(dd>=maxdist) {
      break;
    }
    p += l*d;
    dd+= d;
  }
  return shad;
}

float getao(vec3 p, vec3 n, float d) {
  return clamp(map(p+n*d)/d,0.0,1.0);
}

void main(void)
{
    
  vec2 uv = vec2(gl_FragCoord.x / resolution.x, gl_FragCoord.y / resolution.y);
  uv -= 0.5;
  uv /= vec2(resolution.y / resolution.x, 1);
  
  float rand=rnd(uv);

  vec3 s=vec3(0,0,-5);
  vec3 r=normalize(vec3(-uv, 1));
  
  cam(s);
  cam(r);
  
  vec3 lightpos = vec3(2,-1.0,0);
  float t1 = time + curve(time*0.2)*12.7;
  lightpos.yz *= rot(sin(t1*0.7)*0.7);
  lightpos.xz *= rot(sin(t1*1.3)*0.7-1.5);  
  
  // main raymarch  
  vec3 p=s;
  float dd=0.0;
  const float maxdist = 100.0;
  for(int i=0; i<100; ++i) {
    float d=map(p);
    if(d<0.001) break;
    if(dd>maxdist) { dd=maxdist; break;}
    p+=r*d;
    dd+=d;
  }
  
  // volumetric raymarching
  const int volsteps=50;
  float voldist = 15.0;
  float stepsize = voldist/float(volsteps);
  vec3 lr=r*stepsize;
  vec3 lp=s + lr*rand;
  float stepdist=rand*stepsize;
  vec3 atcol=vec3(0);
  for(int i=0; i<volsteps; ++i) {
    if(stepdist>dd) {
      break;
    }
    vec3 lv = lightpos-lp;
    float ldistvol = length(lv);
    lv = normalize(lv);
    float shadvol = shadow(lp, lv, ldistvol, 20, 0.01);
    atcol += 0.3/(0.05+(ldistvol*ldistvol)) * shadvol;
    //atcol += volumetric(lp)*0.1;
    lp+=lr;
    stepdist+=stepsize;
  }
  
  float fog = 1.0-clamp(dd/maxdist,0.0,1.0);
  
  vec2 off=vec2(0.01,0);
  vec3 n=normalize(map(p)-vec3(map(p-off.xyy), map(p-off.yxy), map(p-off.yyx)));
  
  vec3 l=normalize(lightpos - p);
  vec3 h=normalize(l-r);
  float spec = max(dot(n,h),0.0);
  float ldist = length(lightpos - p);
  float fade = 1.0/(ldist*ldist);
  
  float shad = shadow(p + n * 0.2, l, ldist, 30, 0.01);
  
  vec3 col=vec3(0);
  col += max(dot(n,l),0.0) * (1.7 + 5.0*pow(spec,5.0) + 10.0 * pow(spec,20.0)) * fog * fade * shad;
  //col += pow(1-abs(dot(n,r)), 5) * fog * fade * shad;
  
  float ao = getao(p,n, 0.1) * getao(p,n, 0.4) * getao(p,n, 1.0) * (0.5 + 0.5 * getao(p,n, 2.0));
  col += ao * 0.05;
  
  //col += volumetric(p);
  
  col += atcol;
  //col += pow(at*0.12,4);
  
  //col *= 1.2-length(uv);
  col = pow(col, vec3(0.4545));
  col *= 1.2-length(uv);
  
  glFragColor = vec4(col, 1);
}
