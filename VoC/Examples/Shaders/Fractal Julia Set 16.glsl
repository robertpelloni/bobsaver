#version 420

// original https://www.shadertoy.com/view/NdcSRN

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const int maxit = 30;
const float antialias = 4.0;
const float radius = 1.5;
const bool debug = false;

float pixd() {
  return 1./min(resolution.x, resolution.y);
}

float its(vec2 p, vec2 c) {
  int n = 0;
  float low = radius;
  float high = radius * radius + length(c) - low;
  for(; n < maxit; n++){
    if (length(p) > radius) {
      return float(n) + 1. - (length(p) - low) / high;
    }
    p = vec2(p.x * p.x - p.y * p.y, 2. * p.x * p.y) + c;
  }
  return float(maxit) + (length(p) / low);
}

vec2 start(float t) {
  float a = t / 3.1415;
  float r = sin(t/ 2.618) * sin(t * 2.) / 2. + .5;
  float a2 = t / 6.7;
  float m = sin(t);
  return mix(vec2(-0.835, -0.2321) * mat2(cos(a2), sin(a2), -sin(a2), cos(a2)), vec2(cos(a), sin(a)) * r, m);
}

float atime() { 
  vec2 o = vec2(0.,0.);
  float d = .1/4.;
  float k = 2.;
  float now = floor(time / d) * d + d/2.;
  float away = clamp((now - time) / d + .5, 0., 1.);
  float adjust;
  float maxn = k / d;
  for (float n = 0.; n <= maxn; n++) {
    bool last = n + 1. > maxn;
    float i = n * d + 0.5;
    if (its(o, start(now - i)) >= float(maxit)) {
      adjust -= last ? 1.-away : 1.;
    }
    if (its(o, start(now + i)) >= float(maxit)) {
      adjust += last ? away : 1.;
    }
  }
  //return time;
  return max(0., time + adjust * d);
}

vec2 jitter(vec2 p, float n) {
  float dx = fract(sin(dot(p, vec2(12.9898 * n, 78.233))) * 43758.5453) - 0.5;
  float dy = fract(sin(dot(p, vec2(17.9898 * n, 78.233))) * 43758.5453) - 0.5;
  return p + vec2(dx, dy) * pixd();
}

vec4 pal(float n, vec2 p, float ktime) {
  //return vec4(fract(n),0.,0.,1.);
  //return vec4(n / (float(maxit) * 2.)/2. + .2, 0., 0., 1.);
  float th = 5.;
  if (n < th) {
    return vec4(float(n) / (float(th) + 5.), 0., 0., 1.);
  }
  if (n > float(maxit)) {
    //return vec4(0.,0., clamp((n - float(maxit)) / 1., 0., 1.), 1.);
    float w = (n - float(maxit)); 
    //return vec4(0.,0.,w,1.);
    float inner = 1.1 + .6 * (2. - (ktime - time)) / 4.;
    float m = 0.;
    for (float j = 0.; j < antialias; j++) {
      float i = its(jitter(p, j), start(ktime) * inner);
      m += i;
    }
    m = m / antialias;
    if (m >= float(maxit)) {
      return vec4(0.,0.,0.,1.);
    }
    float r = m / float(maxit - 1);
    return vec4( ((1. - r)/3. + .0) ,pow(w,3.),0.,1.);
  }
  return vec4(2./3., float(n - th) / (float(maxit) - th), 0., 1.);
}

vec4 layercol(vec4 a, vec4 b) {
  return vec4(mix(a.rgb, b.rgb, 1.-a.a), max(a.a, b.a));
}

vec4 coloraa(vec2 p, float ktime) {
  p *= 3.;
  vec4 over = vec4(0.,0.,0.,0.);
  if(debug) {
      if (length(p-start(ktime)) < .04) {
        over = max(over, vec4(0.,1.,0.,1.));
      }
    for (float n = -3.; n <= 3.; n+=0.05) {
      float r = 1. - abs(n / 3.) / 2.;
      if (length(p-start(time - n)) < .05) {
        over = max(over, vec4(0.,0.,1.,r));
      }
    }
  }
  vec4 c;
  for (float n = 0.; n < antialias; n++) {
    float i = its(jitter(p, n), start(ktime));
    c += pal(i, p, ktime);
  }
  return layercol(over, c/antialias);
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy - resolution.xy / 2.) * pixd();
    float ktime = atime();
    glFragColor = coloraa(uv, ktime);
}
