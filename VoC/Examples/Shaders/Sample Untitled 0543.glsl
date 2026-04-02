#version 420

// original https://neort.io/art/bpr34343p9fefb9240sg

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// original https://neort.io/art/bpr34343p9fefb9240sg

#define MIN_SURF 0.001
#define MAX_DIST 100.
#define MAX_LOOP 1000

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

float random(float n) {
  return fract(sin(n*78.39817)*12.09834);
}

mat2 rot(float a) {
  return mat2(cos(a), sin(a), -sin(a), cos(a));
}

vec3 makeRay(in vec3 ro, in vec2 uv) {
  float z = 1.;
  vec3 lookat = vec3(0,1,0)*sin(time*.3);
  vec3 f = normalize(lookat-ro);
  vec3 r = cross(vec3(0,1,0), f);
  vec3 u = cross(f, r);
  vec3 c = ro+f*z;
  vec3 i = c+r*uv.x+u*uv.y;
  vec3 rd = normalize(i-ro);
  return rd;
}

float sdGyroid(in vec3 p) {
  p.y += time;
    float g = dot(sin(p*2.115), cos(p.zyx*1.12))/30.;
    return g;
}

float sdSphere(in vec3 p) {
  p.y += sin(time*.5)*.1-3.;
  p.xz *= rot(p.y*.7+time);
    float g = sdGyroid(p);
  return max(g, length(abs(p)+.1)-4.);
}

vec3 getSphereNormal(in vec3 p) {
    float d = sdSphere(p);
  vec2 e = vec2(.001, 0);
  vec3 n = d - vec3(sdSphere(p-e.xyy), sdSphere(p-e.yxy), sdSphere(p-e.yyx));
  return normalize(n);
}

float traceSphere(in vec3 ro, in vec3 rd, out bool isHit, out float occ) {
  float t = 0.;
  occ = 0.;
  isHit = false;
  for(int i = 0; i< MAX_LOOP; i++) {
    vec3 p = ro+rd*t;
    float d = sdSphere(p);
    if(d < MIN_SURF) {
      isHit = true;
      break;
    }
    if(d > MAX_DIST) break;
    t += d;
    occ += 1.;
  }
  occ /= 100.;
  occ = min(1., pow(occ, 2.+sin(time)));
  return t;
}

vec3 makeSphereColor(in vec3 n) {
  vec3 albd = vec3(1.);
  vec3 dif = vec3(.6,.98,.78)*(1.-n.y);
  dif += vec3(.6,.8,.98)*(1.-n.z);
  return albd - dif*.1;
}

float sdSea(in vec3 p) {
  p.z += time;
  p.y += noise(p)*.1;
  return p.y+1.;
}

vec3 makeSeaColor(in vec3 n, in vec3 eye) {
  vec3 dif = vec3(.6,.98,.78)*(1.-n.y);
  return vec3(.92,.95,1.)-dif*2.;
}

vec3 getSeaNormal(in vec3 p) {
    float d = sdSea(p);
    vec2 e = vec2(.001, 0);
    vec3 n = d - vec3(
        sdSea(p-e.xyy),
        sdSea(p-e.yxy),
        sdSea(p-e.yyx));
    return normalize(n);
}

float traceSea(in vec3 ro, in vec3 rd, out bool isHit) {
  float t = 0.;
  isHit = false;
  for(int i = 0; i<MAX_LOOP; i++) {
    vec3 p = ro+rd*t;
    float d = sdSea(p);
    if(d<MIN_SURF) {
      isHit = true;
      break;
    }
    if(d>MAX_DIST) break;
    t += d;
  }
  return t;
}

vec3 sky(vec3 rd) {
  float n = max(0., rd.y);
  n += .5;
  return mix(vec3(.53, .65, .89), vec3(.89, .65, .53), n);
}

void main(void) {
  vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
  float cs = time * .1;
  vec3 ro = vec3(cos(cs), 0., sin(cs))*(15.+sin(cs*3.)*3.)+vec3(0,1,0);
  vec3 rd = makeRay(ro, uv);

  // glitch
  float glt = step(.85, random(floor(time*10.)));
 
  // initialize
  bool isHit; vec3 p, n, col; float t, occ;
  
  // render sky
  col = sky(rd);
  
  // tracing sea
  vec3 seP;
  t = traceSea(ro, rd, isHit);

  if(isHit) {
    // render sea
    seP = ro+rd*t;
    vec3 seN = getSeaNormal(seP);
    // fog
    vec3 eye = normalize(seP - ro);
    col = mix(makeSeaColor(seN, eye), sky(rd), smoothstep(0., 1., t/20.));
    vec3 scl = col;
    vec3 ld = vec3(0,1,0);
    p = ro+rd*t+ld*MIN_SURF;
    bool isHit_;
    eye = normalize(p-ro);
    n = getSeaNormal(p);

    // reflection of sphere
    vec3 r = reflect(eye, n);
    float t = traceSphere(p, r, isHit_, occ);
    if(isHit_) { 
      p = p+r*t;
      n = getSphereNormal(p);
  
      vec3 c = makeSphereColor(n)*.96;
      col = mix(c, scl, smoothstep(0., 1., t/70.));

    } else {
      col += occ;
    }
  }

  // render sphere
  t = traceSphere(ro, rd, isHit, occ);
  if(isHit) {
    p = ro+rd*t;
    n = getSphereNormal(p);
    col = makeSphereColor(n);
  } else {
    col += vec3(occ);
  }

  float pw = 1.8;
  col = vec3(
    pow(col.r, pw),
    pow(col.g, pw),
    pow(col.b, pw)
  );

  glFragColor = vec4(col, 1.);
}
