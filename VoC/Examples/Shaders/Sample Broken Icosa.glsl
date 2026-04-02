#version 420

// original https://www.shadertoy.com/view/ttXcz7

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// constant.
#define pi 3.14159
// palette
const vec3 black = vec3(0.2);
const vec3 green = vec3(0.3, 0.9, 0.4);
const vec3 white = vec3(1.0);
const vec3 silver = vec3(0.5);
// for folding.
const vec3 nc5 = vec3(-0.5, -0.809017, 0.309017);
const vec3 pab5 = vec3(0.0, 0.0, 0.809017);
const vec3 pbc5 = vec3(0.5, 0.0, 0.809017);
const vec3 pca5 = vec3(0.0, 0.269672, 0.706011);
const vec3 nab5 = vec3(0.0, 0.0, 1.0);
const vec3 nbc5 = vec3(0.525731, 0.0, 0.850651);
const vec3 nca5 = vec3(0.0, 0.356822, 0.934172);
// hsb to rgb.
vec3 getRGB(float h, float s, float b){
  vec3 c = vec3(h, s, b);
  vec3 rgb = clamp(abs(mod(c.x * 6.0 + vec3(0.0, 4.0, 2.0), 6.0) - 3.0) - 1.0, 0.0, 1.0);
  rgb = rgb * rgb * (3.0 - 2.0 * rgb);
  return c.z * mix(vec3(1.0), rgb, c.y);
}
// rotation.
vec2 rotate(vec2 p, float t){
  return p * cos(t) + vec2(-p.y, p.x) * sin(t);
}
// x axis rotation.
vec3 rotateX(vec3 p, float t){
  p.yz = rotate(p.yz, t);
  return p;
}
// y axis rotation.
vec3 rotateY(vec3 p, float t){
  p.zx = rotate(p.zx, t);
  return p;
}
// z axis rotation.
vec3 rotateZ(vec3 p, float t){
  p.xy = rotate(p.xy, t);
  return p;
}
// fold H3 with counting.
int foldH3Count(inout vec3 p){
  int n = 0;
  float _dot;
  for(int i = 0; i < 5; i++){
    if(p.x < 0.0){ p.x = -p.x; n++; }
    if(p.y < 0.0){ p.y = -p.y; n++; }
    _dot = dot(p, nc5);
    if(_dot < 0.0){ p -= 2.0 * _dot * nc5; n++; }
  }
  return n;
}
vec3 getP5(vec3 u){
  return u.x * pab5 + u.y * pbc5 + u.z * pca5;
}
vec3 getP5(float u1, float u2, float u3){
  return u1 * pab5 + u2 * pbc5 + u3 * pca5;
}
// sphere.
float sphere(vec3 p, float r){
  return length(p) - r;
}
// bar. (n:direction, r:radius)
float bar(vec3 p, vec3 n, float r){
  return length(p - dot(p, n) * n) - r;
}
// half open bar.
float halfBar(vec3 p, vec3 n, float r){
  return length(p - min(0.0, dot(p, n)) * n) - r;
}
// update distance.
// 0:min, union.
// 1:max, intersection.
// 2:minus min, difference.
void updateDist(inout vec3 color, inout float dist, vec3 c, float d, int modeId){
  if(d < dist && modeId == 0){ color = c; dist = d; }
  if(d > dist && modeId == 1){ color = c; dist = d; }
  if(-d > dist && modeId == 2){ color = c; dist = -d; }
}
// map function.
vec4 map(vec3 p){
  vec3 color = black;
  float t = 1e20;
  int n = foldH3Count(p);
  float base = 1.0;
  float thick = 0.1;
  float ratio = 2.0 + sin(time * pi);
  base *= ratio;
  thick *= ratio;
  updateDist(color, t, getRGB(float(n) / 15.0, 1.0, 1.0), max(dot(p - pbc5 * base, nca5), dot(p - pbc5 * (base - thick), -nca5)), 0);
  vec3 v = normalize(cross(pbc5 - pab5, nca5));
  updateDist(color, t, black, dot(p - getP5(0.0, 1.0 / ratio, 0.0) * base, v), 1);
  updateDist(color, t, silver, halfBar(p - getP5(0.0, 0.0, 0.9) * base, nca5, 0.05), 0);
  return vec4(color, t);
}
// normal vector.
vec3 calcNormal(vec3 p){
  const vec2 eps = vec2(0.0001, 0.0);
  // mathematical procedure.
  vec3 n;
  n.x = map(p + eps.xyy).w - map(p - eps.xyy).w;
  n.y = map(p + eps.yxy).w - map(p - eps.yxy).w;
  n.z = map(p + eps.yyx).w - map(p - eps.yyx).w;
  return normalize(n);
}
// ray marching.
float march(vec3 ray, vec3 camera){
  const float maxd = 20.0; // searching limit.
  const float precis = 0.001; // precision.
  const int ITERATION = 64; // iteration limit.
  float h = precis * 2.0; // heuristics.

  float t = 0.0; // current distance.

  float result = -1.0;
  for(int i = 0; i < ITERATION; i++){
    if(h < precis || t > maxd){ break; }
    // adding heuristics value.
    h = map(camera + t * ray).w;
    t += h;
  }
  // if t < maxd, it means success(h < precis).
  if(t < maxd){ result = t; }
  return result;
}
// camera move.
void transform(inout vec3 p){
  p = rotateX(p, pi * time * 0.3);
  p = rotateY(p, pi * time * 0.15);
}
// background.
vec3 getBackground(vec2 p){
  vec2 i = floor(p * 10.0);
  vec3 color = mix(green, white, 0.6 + 0.3 * mod(i.x + i.y, 2.0));
  return color;
}
// main.
void main(void) {
  vec2 p = (gl_FragCoord.xy * 2.0 - resolution.xy) / min(resolution.x, resolution.y);
  vec3 color;
  // ray vector.
  vec3 ray = normalize(vec3(p, -1.8));
  // camera position.
  vec3 camera = vec3(0.0, 0.0, 4.5);
  // light vector.
  vec3 light = normalize(vec3(0.5, 0.8, 3.0));
  // camera rotation.
  transform(ray);
  transform(camera);
  transform(light);
  color = getBackground(p);
  // get ray marching result.
  float t = march(ray, camera);
  // if t > -0.001, it means success. if not, background color.
  if(t > -0.001){
    vec3 pos = camera + t * ray;
    vec3 n = calcNormal(pos);
    // lighting.
    float diff = clamp((dot(n, light) + 0.5) * 0.7, 0.3, 1.0);
    vec3 baseColor = map(pos).xyz;
    baseColor *= diff;
    // fadeout.
    color = mix(baseColor, color, tanh(t * 0.04));
  }
  glFragColor = vec4(color, 1.0);
}
