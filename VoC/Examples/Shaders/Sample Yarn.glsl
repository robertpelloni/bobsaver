#version 420

// original https://neort.io/art/bq7iv2c3p9f6qoqnlui0

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;

out vec4 glFragColor;

#define MIN_SURF 0.01
#define MAX_DIST 100.
#define MAX_LOOP 300
#define PI 3.141593

mat2 rot(float a) {
  return mat2(cos(a), sin(a), -sin(a), cos(a));
}

float random(float n) {
    return fract(sin(n*318.154121)*31.134131);
}

float mod289(float x){return x - floor(x * (1.0 / 289.0)) * 289.0;}
vec4 mod289(vec4 x){return x - floor(x * (1.0 / 289.0)) * 289.0;}
vec4 perm(vec4 x){return mod289(((x * 34.0) + 1.0) * x);}
float noise(vec3 p){
    vec3 a = floor(p);
    vec3 d = p - a;
    d = d * d * (3.0 - 2.0 * d);
    vec4 b = a.xxyy + vec4(0.0, 1.0, 0.0, 1.0);
    vec4 k1 = perm(b.xyxy);
    vec4 k2 = perm(k1.xyxy + b.zzww);
    vec4 c = k2 + a.zzzz;
    vec4 k3 = perm(c);
    vec4 k4 = perm(c + 1.0);
    vec4 o1 = fract(k3 * (1.0 / 41.0));
    vec4 o2 = fract(k4 * (1.0 / 41.0));
    vec4 o3 = o2 * d.z + o1 * (1.0 - d.z);
    vec2 o4 = o3.yw * d.x + o3.xz * (1.0 - d.x);
    return o4.y * d.y + o4.x * (1.0 - d.y);
}

vec3 makeRay(in vec3 ro, in vec3 lookat, in vec2 uv) {
  float z = .6;
  vec3 f = normalize(lookat-ro);
  vec3 r = cross(vec3(0,1,0), f);
  vec3 u = cross(f, r);
  vec3 c = ro+f*z;
  vec3 i = c+r*uv.x+u*uv.y;
  vec3 rd = normalize(i-ro);
  return rd;
}

float smin( float a, float b, float k ){
  float h = clamp( 0.5+0.5*(b-a)/k, 0.0, 1.0 );
  return mix( b, a, h ) - k*h*(1.0-h);
}

vec2 pmod(vec2 p, float r) {
    float a =  atan(p.x, p.y) + PI/r;
    float n = PI*2. / r;
    a = floor(a/n)*n;
    return p*rot(-a);
}

float sdThread(in vec3 p, in float seed) {
  float no = noise(p*.5+vec3(time+seed*12.));
  p.xz += no*1.6;
  p.xz *= rot(p.y*no+time);
  float th = length(p.xz)-.2;
  return th;
}

float map(vec3 p) {
  float no = noise(vec3(p.y*.2+time,1.,1.));
  float seed=0.;
  p.xz *= rot(p.y*.2);
  p.xz *= rot(no*4.);
  p.z -= 1.+no*4.;
  p.xz *= rot(p.y);
  float r = sdThread(p, random(12.12));
  for(int i=0; i<=4; i++) {
    seed += 1.;
    p.x *= 1.4 + 1.;
    p.xz *= rot(2.);
    r = smin(r, sdThread(p, random(seed)), 1.2);
  }
  return r/10.;
}

vec3 getNormal(vec3 p){
    float d = 0.001;
    return normalize(vec3(
        map(p + vec3(  d, 0.0, 0.0)) - map(p + vec3( -d, 0.0, 0.0)),
        map(p + vec3(0.0,   d, 0.0)) - map(p + vec3(0.0,  -d, 0.0)),
        map(p + vec3(0.0, 0.0,   d)) - map(p + vec3(0.0, 0.0,  -d))
    ));
}

void main(void) {
  vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
  float s = time*3.;
  vec3 ro = vec3(10.,15.,-10.);
  ro *= vec3(sin(time*.3), 1., cos(time*.1));
  vec3 lookat = vec3(0);

  // initialize
  vec3 rd = makeRay(ro, lookat, uv);
  vec3 col = vec3(0.);
  float t = 0., stp=0.;
  vec3 p;

  // ray march
  for(int i = 0; i <= MAX_LOOP; i++) {
    p = ro+rd*t;
    float d = map(p);
    if(d>MAX_DIST) break;
    if(d<MIN_SURF) {
      vec3 n = getNormal(p);
      n*=.5;
      n+=.5;
      col = vec3(1.);
      col -= vec3(1.-n.y*.2);
      break;
    }
    t += d;
    stp+=1.;
  }

  float m = stp/250.;
  m = pow(m, 1.2);
  col = vec3(m);
  float fog = pow(t/60., 4.);
  col = mix(col, vec3(1.), min(1., max(0., fog)));

  glFragColor = vec4(col, 1.);
}
