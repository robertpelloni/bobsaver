#version 420

// original https://www.shadertoy.com/view/Dts3zB

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float PI = 3.141592653589793;
const float PI_2 = PI*2.;

// [0, 1] -> [0, 1]
float easeIn(float t) {
  return t*t*t*t;
}

// [0, 1] -> [0, 1]
float easeInOut(float t) {
  if (t < 0.5) {
    return easeIn(2.*t)/2.;
  } else {
    return 1. - easeIn(2. - 2.*t)/2.;
  }
}

mat2 rot(float theta) {
  return mat2(cos(theta), sin(theta), -sin(theta), cos(theta));
}

float crs(vec2 a, vec2 b) {
  return a.x*b.y - a.y*b.x;
}

vec3 toHex(vec2 p) {
  const mat2 m = mat2(sqrt(3.)/3., -1./3., 0., 2./3.);
  vec2 q = p * m;
  return vec3(q, -(q.x + q.y));
}

vec2 toCartesian(vec3 hex) {
  const mat2 m = mat2(sqrt(3.), sqrt(3.)/2., 0., 3./2.);
  return hex.xy * m;
}

float hexLength(vec3 pHex) {
  vec2 q = toCartesian(pHex) * rot(PI/6.);
  vec3 qHex = toHex(q);
  vec3 t = abs(qHex);
  return max(t.x, max(t.y, t.z)) * sqrt(3.);
}

float hexagon(vec2 p, float r) {
  float len = hexLength(toHex(p));
  return len - r;
}

float arcHexagon(vec2 p, float r, float theta1, float theta2) {
  vec3 hex1 = toHex(vec2(cos(theta1), sin(theta1)));
  float len1 = hexLength(hex1);
  vec2 q1 = toCartesian(hex1) * (r/len1);
  vec3 hex2 = toHex(vec2(cos(theta2), sin(theta2)));
  float len2 = hexLength(hex2);
  vec2 q2 = toCartesian(hex2) * (r/len2);

  if (crs(p, q1) > 0.) {
    return length(p - q1);
  } else if (crs(p, q2) < 0.) {
    return length(p - q2);
  } else {
    return abs(hexagon(p, r));
  }
}

float gridHexagon(vec2 p, float r, float alpha) {
  vec3 pHex = toHex(p);
  vec3 qHex = floor(pHex + .5);
  vec3 diff = abs(pHex - qHex);
  if (diff.x > diff.y && diff.x > diff.z) {
    qHex.x = -(qHex.y + qHex.z);
  } else if (diff.y > diff.z) {
    qHex.y = -(qHex.z + qHex.x);
  } else {
    qHex.z = -(qHex.x + qHex.y);
  }

  float theta1 = 0. + alpha;
  float theta2 = PI_2/3. + alpha;
  float d = arcHexagon(toCartesian(pHex - qHex), r, theta1, theta2);
  return d;
}

vec3 draw(vec2 p, vec3 power) {
  const float N = 3.;
  float stepSecs = 9./N;
  float t = mod(time, stepSecs*N);

  // [0, stepSecs*N) -> [0, N)
  t = floor(t/stepSecs) + easeInOut(fract(t/stepSecs));

  vec2 q1 = (p - vec2(0, 0))*rot(PI_2/3.*0.);
  vec2 q2 = (p - vec2(0, 1))*rot(PI_2/3.*1.);
  vec2 q3 = (p - vec2(0, 2))*rot(PI_2/3.*2.);

  float alpha = PI_2*(t/N) + PI/6.;
  float r = 1.15;

  float d1 = gridHexagon(q1, r, alpha);
  float d2 = gridHexagon(q2, r, alpha);
  float d3 = gridHexagon(q3, r, alpha);

  vec3 c1 = power / min(d1, d2);
  vec3 c2 = power / min(d2, d3);
  vec3 c3 = power / min(d3, d1);

  if (t < 1.) {
    return mix(c1, c2, t - 0.);
  } else if (t < 2.) {
    return mix(c2, c3, t - 1.);
  } else {
    return mix(c3, c1, t - 2.);
  }
}

vec3 palette(float t) {
  vec3 a = vec3(.2, .7, .8);
  vec3 b = vec3(.1, .3, .2);
  vec3 c = vec3(1., 1., 1.);
  vec3 d = vec3(2./3., 0./3., 1./3.);
  return a + b*cos(PI_2*(c*t + d));
}

void main(void) {
  vec2 p = (gl_FragCoord.xy*2. - resolution.xy) / min(resolution.x, resolution.y);
  
  const float scale = 6.;
  vec3 power = palette(time/12. + .5)*.2;
  vec3 col = draw(p*scale, power);
  
  glFragColor = vec4(col,1.0);
}
