#version 420

// original https://neort.io/art/bq3lk843p9fefb927e9g

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;

out vec4 glFragColor;

#define MIN_SURF 0.0001
#define MAX_DIST 300.
#define MAX_LOOP 1000
#define iTime time

mat2 rot(float a) {
  return mat2(cos(a), sin(a), -sin(a), cos(a));
}

vec3 makeRay(in vec3 ro, in vec3 lookat, in vec2 uv) {
  float z = .5;
  vec3 f = normalize(lookat-ro);
  vec3 r = cross(vec3(0,1,0), f);
  vec3 u = cross(f, r);
  vec3 c = ro+f*z;
  vec3 i = c+r*uv.x+u*uv.y;
  vec3 rd = normalize(i-ro);
  return rd;
}

vec3 fold(vec3 p) {
  vec3 n = normalize(vec3(1.,0.,13.));
    p -= 2.0 * min(0.0, dot(p, n)) * n;
    return p;
}

float sdBox( vec3 p, vec3 b ) {
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

float smin( float a, float b, float k ){
  float h = clamp( 0.5+0.5*(b-a)/k, 0.0, 1.0 );
  return mix( b, a, h ) - k*h*(1.0-h);
}

float map(vec3 p) {
  p.xz *= rot(p.y*.1+iTime);
  p.yz *= rot(p.x*.1+iTime);
  p.xz *= rot(iTime);
  vec3 s = vec3(8.);
  float r = sdBox(p, s);
  for (int i=0; i<=8; i++) {
    s *= .9;
    p.x += 1.;
    p.xz *= rot(5.);
    p = fold(p);
    p.y += 2.;
    p.xz *= rot(5.+iTime*.1);
    p = fold(p);
    p.xz *= rot(5.+iTime*.1);
    p = fold(p);
    p.y -= 1.5;
    p.yz *= -rot(5.+iTime*.3+109.121);
    p.yz *= -rot(5.+iTime*.3+109.121);
    p = fold(p);
    r = smin(r, sdBox(p, s), 1.5);
  }
    return r/4.;
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
  vec3 ro = vec3(0,0,-20.);
  vec3 lookat = vec3(0);

  // initialize
  vec3 rd = makeRay(ro, lookat, uv);
  vec3 col = vec3(1.);
  float t = 0., stp=0.;
  vec3 p, n;

  // ray march
  for(int i = 0; i <= MAX_LOOP; i++) {
    p = ro+rd*t;
    float d = map(p);
    if(d>MAX_DIST) {
      break;
    }
    if(d<MIN_SURF) {
      n = getNormal(p);
      n*=.5;
      n+=.5;
      // col = n;
      col = vec3(1.-n.y*.1);
      break;
    }
    t += d;
    stp+=1.;
  }

  float m = stp/150.;
  col -= vec3(pow(m,1.5))*.01;
  glFragColor = vec4(col, 1.);
}
