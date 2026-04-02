#version 420

// original https://www.shadertoy.com/view/Wdt3WN

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float kScale = 0.75;

const float kRadius1 = kScale * 0.1875;
const float kRadius2 = kScale * 0.125;
const float kRadius3 = kScale * 0.0625;

//const float kMotionRadius = 0.05 * kRadius1;
const float kMotionRadius = 0.0;

const vec2 kSize = kScale * vec2(0.45, 0.625);
const vec2 kOffset = kScale * vec2(0.225, 0.2375);

const vec3 kColorBlack = vec3(0.0);
const vec3 kColorRed = vec3(0.608, 0.118, 0.141);
const vec3 kColorOrange = vec3(0.875, 0.373, 0.094);

float sdfBox(vec2 p, vec2 s) {
  vec2 v = abs(p) - s;
  return max(v.x, v.y);
}

vec2 sdfMod(vec2 p, vec2 s) {
  return mod(p + 0.5 * s, s) - 0.5 * s;
}

float sdfHexagonalShapes(vec2 p, float r, vec2 s) {
  vec2 q = abs(sdfMod(p, s));
  vec2 n = -normalize(vec2(1.0, sqrt(3.0)));
  float d1 = dot(n, q) + r;
  float d2 = r - q.x;
  return -min(d1, d2);
}

float sdfAlternatingHexagonalShapes(vec2 p, float r) {
  float d1 = sdfHexagonalShapes(p, r, kSize);
  float d2 = sdfHexagonalShapes(p + kOffset, r, kSize);
  return min(d1, d2);
}

float sdfFillingShapes(vec2 p, float r) {
  vec2 s = vec2(0.5 * kSize.x - kRadius1, 2.0 * r / sqrt(3.0));
  vec2 q1 = sdfMod(p + vec2(0.0, kOffset.x), kSize);
  float d1 = sdfBox(q1, s);
  vec2 q2 = sdfMod(p + vec2(kOffset.x, 0.0), kSize);
  float d2 = sdfBox(q2, s);
  return min(d1, d2);
}

float sdfShape1(vec2 p, float t) {
  p += kMotionRadius * vec2(cos(t), sin(t));
  return sdfAlternatingHexagonalShapes(p, kRadius1);
}

float sdfShape2(vec2 p, float t) {
  p += kMotionRadius * vec2(cos(t), sin(t));
  float d1 = sdfAlternatingHexagonalShapes(p, kRadius2);
  float d2 = sdfFillingShapes(p, kRadius2);
  return min(d1, d2);
}

float sdfShape3(vec2 p, float t) {
  p += kMotionRadius * vec2(cos(-1.5 * t), sin(-1.5 * t));
  return sdfAlternatingHexagonalShapes(p, kRadius3);
}

vec2 makePoint(vec2 gl_FragCoord, vec2 resolution) {
  return (2.0 * gl_FragCoord.xy - resolution) / resolution.x;
}

vec3 mixShape(int i, vec3 bgColor, vec3 fgColor, vec2 p, float t) {
  float d = 0.0;
  if (i == 1) {
    d = sdfShape1(p, t);
  } else if (i == 2) {
    d = sdfShape2(p, t);
  } else if (i == 3) {
    d = sdfShape3(p, t);
  }
  float w = fwidth(d);
  float e = smoothstep(-w, 0.0, -d);
  return mix(bgColor, fgColor, e);
}

vec3 render(vec2 gl_FragCoord, vec2 resolution, float time) {
  vec2 p = makePoint(gl_FragCoord, resolution);
  vec3 color = kColorBlack;
  color = mixShape(1, color, kColorOrange, p, time);
  color = mixShape(2, color, kColorBlack, p, time);
  color = mixShape(3, color, kColorRed, p, time);
  return color;
}

void main(void) {
  vec3 color = render(gl_FragCoord.xy, resolution.xy, time);
  glFragColor = vec4(color, 1.0);
}
