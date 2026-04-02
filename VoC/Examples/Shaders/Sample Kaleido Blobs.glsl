#version 420

// original https://www.shadertoy.com/view/MsGfzD

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define KALEIDO 1
#define MAXSTEPS 200

#define v2Resolution resolution
#define out_color glFragColor
#define time time

float sph(vec3 p, float r) {
  return length(p)-r;
}

float cyl(vec3 p, vec2 s) {
  return max(length(p.xz)-s.x,abs(p.y)-s.y);
}

vec3 rep(vec3 p, vec3 s) {
  return (fract(p/s+0.5)-0.5)*s;
}

vec3 repid(vec3 p, vec3 s) {
  return floor(p/s+0.5);
}

mat2 rot(float a) {
  float co=cos(a);
  float so=sin(a);
  return mat2(co,so,-so,co);
}

float smin(float a, float b, float h) {
  float k=clamp(0.5+0.5*(a-b)/h,0.0,1.0);
  return mix(a,b,k)-k*(1.0-k)*h;
}

float smax(float a, float b, float h) {
  float k=clamp(0.5+0.5*(b-a)/h,0.0,1.0);
  return mix(a,b,k)+k*(1.0-k)*h;
}

float map(vec3 p) {

  vec3 m0 = p;
  //m0.xy=abs(m0.xy);

  float tt = time * 0.2;
  float tt2 = time * 0.5;

  vec3 r0 = m0;
  r0.xz *= rot(tt);
  r0.yz *= rot(tt*2.3975);
  vec3 r1 = rep(r0, vec3(2.0));
  vec3 def = repid(r0, vec3(2.0));
  
  float d = sph(r1, 0.1);

  for(int i=0;i<7;++i) {
    vec3 r2 = r1;
    r2.xy *= rot(tt2*0.221 + float(i)*1.986 + dot(def,def));
    r2.yz *= rot(tt2*1.674 + float(i)*5.34);
    d=smin(d,cyl(r2+vec3(0.0), vec2(0.02,0.8)), 0.2);
  }

  for(int i=0;i<7;++i) {
    vec3 r2 = r1;
    r2.xy *= rot(tt2*0.8742 + float(i)*2.1243);
    r2.yz *= rot(tt2*1.9865 + float(i)*6.974 + dot(def,def));
    d=smax(d,-cyl(r2+vec3(0.0), vec2(0.02,0.8)),0.1);
  }

  float ex=smax(sph(r1,0.3),-sph(r1,1.1),0.2);

  d=smin(d,ex,0.8);
  d=smax(d, sph(r1,0.8),0.2);

  return d;

}

vec3 norm(vec3 p) {

  float base = map(p);
  vec2 off = vec2(0.0,0.001);
  return normalize(vec3(base-map(p+off.yxx),base-map(p+off.xyx),base-map(p+off.xxy)));

}

vec2 mirror(vec2 uv, float a) {
  mat2 rr = rot(a);
  vec2 m=uv*rr;
  m.x=abs(m.x);
  return m*rr;
}

void main(void)
{
  vec2 uv = vec2(2.0*gl_FragCoord.x / v2Resolution.x-1.0, 1.0-2.0*gl_FragCoord.y / v2Resolution.y);
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);

  vec2 off = vec2(cos(time),sin(time)) * 0.3;
  //uv=abs(uv)-abs(off);

  float tt=time*0.5;
#if KALEIDO
  uv = mirror(uv, tt*0.1);
  uv = mirror(uv, -tt*0.3 + 0.124);
  uv = mirror(uv, tt*2.3);

  uv -= abs(off);
#endif

  vec3 col = vec3(0.0);
  
  vec3 ro = vec3(0,0,-1);
  vec3 rd = normalize(vec3(uv, 1.0));
  
  vec3 p = ro;

  float e = 0.0;

  for(int i=0;i<MAXSTEPS;++i) {

    float d = map(p);
    if(d<0.0001) {

      break;
    }
    e += (1.0-clamp(length(p-ro)/10.0,0.0,1.0))*0.00001/(d);
    p += d*rd;
  }

  vec3 n = norm(p);
  float lum = clamp(dot(n,normalize(vec3(0.7))),0.0,1.0);

  float depth = length(p-ro);

  col = vec3(1.0/depth);
  col *= lum;
  col += 0.3*vec3(0.0,1.0,1.0)*max(0.0,n.y);
  col += (pow(depth,0.3))*vec3(0.2,0.0,0.5)*0.2;

  col += e * vec3(1.0,0.6,0.0);

  out_color = vec4(col,0);

  //out_color = vec4(fract(uv*5.0),0,0);
}
