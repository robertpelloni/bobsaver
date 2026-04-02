#version 420

// original https://neort.io/art/bqvpvjc3p9f48fkiu4mg

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;

out vec4 glFragColor;

#define MIN_SURF 0.001
#define MAX_DIST 100.
#define MAX_LOOP 100
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
  float z = 1.;
  vec3 f = normalize(lookat-ro);
  vec3 r = cross(vec3(0,1,0), f);
  vec3 u = cross(f, r);
  vec3 c = ro+f*z;
  vec3 i = c+r*uv.x+u*uv.y;
  vec3 rd = normalize(i-ro);
  return rd;
}

vec2 pmod(vec2 p, float r) {
    float a =  atan(p.x, p.y) + PI/r;
    float n = PI*2. / r;
    a = floor(a/n)*n;
    return p*rot(-a);
}

float map(vec3 p) {
  float tn = noise(vec3(time));
  p.z -= time*3.;

  // twist
  p.xy *= rot(p.z);

  // repat
  float z =15.;
  p.z = mod(p.z-z*.5, z)-z*.5;

  // pmod fold
  p.yz = pmod(p.yz, 12.);
  p.z -= 1.+(sin(time*1.)*1.+1.);
  p.xz = pmod(p.xz, 12.*tn);
  p.z -= tn;
  p.xz = pmod(p.xz, 12.);
  p.z -= 1.;
  p.xy = pmod(p.xy, 12.);
  p.y -= 1.;
  p.xy = pmod(p.xy, 12.);
  p.y -= .4;

  // shape
  p.zy = pmod(p.zy, 23.);
  p.xz = pmod(p.xz, 23.);
  p.xz *= rot(4.71);
  p.xy = pmod(p.xy, 8.+sin(time)*4.);
  p.xy *= rot(4.71);
  p.x += .5;
  float result = length(p.xz)-.003*tn;

  return (length(p)-.1)-(result/2.5)*1.34;
}

void main(void) {
  vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
  float rt = time *.3;
  float tn = noise(vec3(rt));
  vec3 ro = vec3(sin(rt)*6., cos(rt)*6., 20.)*(1.+tn*.1);
  vec3 lookat = vec3(0, tn*.1, 0.);

  // initialize
  vec3 rd = makeRay(ro, lookat, uv);
  vec3 col = vec3(0.);
  float t = 0.;
  vec3 p;

  // ray march
  float step=0.;
  for(int i = 0; i <= MAX_LOOP; i++) {
    p = ro+rd*t;
    float d = map(p);
    if(d>MAX_DIST || d<MIN_SURF) {
      break;
    }
    step += 1.;
    t += d;
  }

  col = vec3(step/100.);
  col = pow(col, vec3(2.));

  glFragColor = vec4(col, 1.);
}
