#version 420

// original https://www.shadertoy.com/view/MtGcWw

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define SPHERE_GRID 0
#define HIGHLIGHT_3D_SLICE 1
#define USE_MAX 0
#define SAMPLES_W 30
#define MAXSTEPS 30

#define time time
#define v2Resolution resolution
#define out_color glFragColor

float sph(vec4 p, float r) { return length(p)-r; }
float cyl2(vec2 p, float r) {return length(p)-r; }
float box(vec4 p, float s) { vec4 ap = abs(p); return min(length(max(vec4(0),ap-s)), max(max(ap.x,ap.y),max(ap.z,ap.w))-s); }
float box2(vec2 p, float s) { vec2 ap = abs(p); return min(length(max(vec2(0),ap-s)),max(ap.x, ap.y)-s); }

vec4 rep(vec4 p, vec4 s) {
  return (fract(p/s-0.5)-0.5)*s;
}

vec4 rid(vec4 p, vec4 s) {
  return floor(p/s-0.5);
}

mat2 rot(float a) {
  float ca=cos(a);float sa=sin(a);
  return mat2(ca,sa,-sa,ca);
}

float map(vec4 p, float size) {

  float spd = 0.6;
  
  p.yz *= rot(time*0.05);
  p.xw *= rot(time * spd);
  p.yw *= rot(time*0.2*spd);
  p.xw *= rot(time*0.7*spd);
  p.zw *= rot(time*0.3*spd);
  
  //p.xz *= rot(time*0.2);

#if SPHERE_GRID
  // grid inside a sphere
  float d = sph(p, 2.0);

  vec4 rp2 = rep(p, vec4(1.0));

  //float size = 0.24;
  size*=0.55;
  float c = box2(rp2.xz, size);
  c = min(c, box2(rp2.xy, size));
  c = min(c, box2(rp2.yz, size));
  c = min(c, box2(rp2.xw, size));
  c = min(c, box2(rp2.yw, size));
  c = min(c, box2(rp2.zw, size));
  d = max(d, -c);
#else
    
  // tesseract
  float d = box(p, 1.0);

  vec4 rp = p;//rep(op, vec4(0.4));
  //float size = 0.95;
  float c = box2(rp.xz, size);
  c = min(c, box2(rp.xy, size));
  c = min(c, box2(rp.yz, size));
  c = min(c, box2(rp.xw, size));
  c = min(c, box2(rp.yw, size));
  c = min(c, box2(rp.zw, size));

  d = max(d, -c);

#endif
  
  return d;
}

vec3 norm(vec4 p, float size) {
  vec2 off=vec2(0.01,0);
  return normalize(vec3(map(p+off.xyyy, size)-map(p-off.xyyy, size),map(p+off.yxyy, size)-map(p-off.yxyy, size),map(p+off.yyxy, size)-map(p-off.yyxy, size)));
}

float rnd(vec2 uv) {
  return fract(dot(sin(uv*vec2(172.412,735.124)+uv.yx*vec2(97.354,421.653)+vec2(94.321,37.365)),vec2(4.6872,7.9841))+0.71243);
}

vec3 GetCol(vec2 uv, float motion, float size) {

  
  vec4 s=vec4(0,0,-5,motion);
  vec4 r=normalize(vec4(-uv, 1,0));

  float dd = 0.0;
  vec4 p = s;
  float at=0.0;
  float show=1.0f;
  for(int i=0; i<MAXSTEPS; ++i) {
    float d = map(p, size);
    if(d<0.001) {
      break;
    }
    p+=r*d;
    dd+=d;
    if(dd>100.0) {
      show=0.0f;
      break;
    }
    at += exp(-d)*0.8;
  }

  vec3 n=norm(p, size);
  vec3 l=normalize(vec3(-1));
  float lum=max(0.0, dot(l,n));

  vec3 col = vec3(0);
  col += lum * 2.0;
  col += lum * pow(max(0.0, dot(n, normalize(-r.xyz+l))), 10.0) * vec3(1.0,5.0,10.0);
  col += (n.y*0.5+0.5) * vec3(0.1,0.5,1.0);
  col *= show*2.0/dd;

  col += vec3(0.8,0.2,0.2)*0.03/exp(-at*0.25);
  
  return col;
}

void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);

  float str = 1.7;
  float off = rnd(uv);
  vec3 col = vec3(0.0);
  float size = 0.87+sin(time*0.2)*0.1;
  
  for(int i=0; i<SAMPLES_W; ++i) {

    float motion = (float(i)+off)/float(SAMPLES_W);
    motion = motion * 2.0 - 1.0;
#if HIGHLIGHT_3D_SLICE
    motion = motion*motion*sign(motion);
#endif
    motion *= str;

    vec3 cur = GetCol(uv, motion, size);
#if USE_MAX
    col = max(col, cur);
#else
    col += cur;
#endif
  }

#if USE_MAX
    col *= size*0.4;    
#else
    col *= size*4.0/float(SAMPLES_W);
#endif
    
  out_color = vec4(col.rgb, 1);
}
