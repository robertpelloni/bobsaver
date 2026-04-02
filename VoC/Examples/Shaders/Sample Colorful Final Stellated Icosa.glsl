#version 420

// original https://www.shadertoy.com/view/3dBBDh

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// I like polyhedron. It's beautiful.
// reference:https://www.shadertoy.com/view/XtXGRS  thanks!!

// This is the Final stellation of the icosahedron.
// reference:https://en.wikipedia.org/wiki/Final_stellation_of_the_icosahedron

// constants.
#define PI    3.14159

// face vectors of icosahedron.
// top:(0.0, 1.0, 0.0), inner 5 faces, outer 5 faces.
const vec3 f20_1 = vec3(-0.60706, 0.79465, 0.0);
const vec3 f20_2 = vec3(-0.18759, 0.79465, 0.57735);
const vec3 f20_3 = vec3(0.49112, 0.79465, 0.35682);
const vec3 f20_4 = vec3(0.49112, 0.79465, -0.35682);
const vec3 f20_5 = vec3(-0.18759, 0.79465, -0.57735);
const vec3 f20_6 = vec3(-0.98225, 0.18759, 0.0);
const vec3 f20_7 = vec3(-0.30353, 0.18759, 0.93417);
const vec3 f20_8 = vec3(0.79465, 0.18759, 0.57735);
const vec3 f20_9 = vec3(0.79465, 0.18759, -0.57735);
const vec3 f20_10 = vec3(-0.30353, 0.18759, -0.93417);
// vertice vectors of icosahedron.
const vec3 v20_1 = vec3(0.0, 1.0, 0.0);
const vec3 v20_2 = vec3(0.89443, 0.44721, 0.0);
const vec3 v20_3 = vec3(0.27639, 0.44721, -0.85065);
const vec3 v20_4 = vec3(-0.72361, 0.44721, -0.52573);
const vec3 v20_5 = vec3(-0.72361, 0.44721, 0.52573);
const vec3 v20_6 = vec3(0.27639, 0.44721, 0.85065);
// from hsb to rgb.
vec3 getRGB(float h, float s, float b){
  vec3 c = vec3(h, s, b);
  vec3 rgb = clamp(abs(mod(c.x * 6.0 + vec3(0.0, 4.0, 2.0), 6.0) - 3.0) - 1.0, 0.0, 1.0);
  rgb = rgb * rgb * (3.0 - 2.0 * rgb);
  return c.z * mix(vec3(1.0), rgb, c.y);
}
// rotation of vector.
vec2 rotate(vec2 p, float t){
  return p * cos(t) + vec2(-p.y, p.x) * sin(t);
}
// rotation with X axis.
vec3 rotateX(vec3 p, float t){
  p.yz = rotate(p.yz, t);
  return p;
}
// rotation with Y axis.
vec3 rotateY(vec3 p, float t){
  p.zx = rotate(p.zx, t);
  return p;
}
// rotation of Z axis.
vec3 rotateZ(vec3 p, float t){
  p.xy = rotate(p.xy, t);
  return p;
}
// Final stellation of the icosahedron.
float finalStellaIcosa(vec3 p, float size){
  float d1 = size; // for vertices... base of 60 corns.
  float d2 = size * 0.41947; // for faces... sides of 60 corns.

  float v1 = abs(dot(p, v20_1)) - d1;
  float v2 = abs(dot(p, v20_2)) - d1;
  float v3 = abs(dot(p, v20_3)) - d1;
  float v4 = abs(dot(p, v20_4)) - d1;
  float v5 = abs(dot(p, v20_5)) - d1;
  float v6 = abs(dot(p, v20_6)) - d1;

  float f1 = abs(dot(p, f20_1)) - d2;
  float f2 = abs(dot(p, f20_2)) - d2;
  float f3 = abs(dot(p, f20_3)) - d2;
  float f4 = abs(dot(p, f20_4)) - d2;
  float f5 = abs(dot(p, f20_5)) - d2;
  float f6 = abs(dot(p, f20_6)) - d2;
  float f7 = abs(dot(p, f20_7)) - d2;
  float f8 = abs(dot(p, f20_8)) - d2;
  float f9 = abs(dot(p, f20_9)) - d2;
  float f10 = abs(dot(p, f20_10)) - d2;

  // corn group 1.
  float result = max(-v2, max(f6, max(f7, f10)));
  result = min(result, max(-v3, max(f7, max(f8, f6))));
  result = min(result, max(-v4, max(f8, max(f9, f7))));
  result = min(result, max(-v5, max(f9, max(f10, f8))));
  result = min(result, max(-v6, max(f10, max(f6, f9))));

  // corn group 2.
  result = min(result, max(-v5, max(f2, max(f5, f10))));
  result = min(result, max(-v3, max(f10, max(f2, f1))));
  result = min(result, max(-v1, max(f1, max(f10, f7))));
  result = min(result, max(-v6, max(f7, max(f1, f5))));
  result = min(result, max(-v4, max(f5, max(f7, f2))));

  // corn group 3.
  result = min(result, max(-v5, max(f1, max(f8, f3))));
  result = min(result, max(-v6, max(f3, max(f1, f6))));
  result = min(result, max(-v4, max(f6, max(f3, f2))));
  result = min(result, max(-v1, max(f2, max(f6, f8))));
  result = min(result, max(-v2, max(f8, max(f2, f1))));

  // corn group 4.
  result = min(result, max(-v1, max(f3, max(f7, f9))));
  result = min(result, max(-v3, max(f9, max(f3, f2))));
  result = min(result, max(-v6, max(f2, max(f9, f4))));
  result = min(result, max(-v2, max(f4, max(f2, f7))));
  result = min(result, max(-v5, max(f7, max(f4, f3))));

  // corn group 5.
  result = min(result, max(-v1, max(f4, max(f8, f10))));
  result = min(result, max(-v4, max(f10, max(f4, f3))));
  result = min(result, max(-v2, max(f3, max(f10, f5))));
  result = min(result, max(-v3, max(f5, max(f3, f8))));
  result = min(result, max(-v6, max(f8, max(f5, f4))));

  // corn group 6.
  result = min(result, max(-v2, max(f9, max(f1, f5))));
  result = min(result, max(-v1, max(f5, max(f9, f6))));
  result = min(result, max(-v5, max(f6, max(f5, f4))));
  result = min(result, max(-v3, max(f4, max(f6, f1))));
  result = min(result, max(-v4, max(f1, max(f4, f9))));

  return result;
}
// map function.
float map(vec3 p){
  return finalStellaIcosa(p, 0.5);
}
// normal vector.
vec3 calcNormal(vec3 p){
  const vec2 eps = vec2(0.0001, 0.0);
  // mathematical procedure.
  vec3 n;
  n.x = map(p + eps.xyy) - map(p - eps.xyy);
  n.y = map(p + eps.yxy) - map(p - eps.yxy);
  n.z = map(p + eps.yyx) - map(p - eps.yyx);
  return normalize(n);
}
// ray marching.
float march(vec3 ray, vec3 camera){
  const float maxd = 20.0; // limit distance.
  const float precis = 0.001; // precision.
  const int ITERATION = 64; // iteration limit.
  float h = precis * 2.0; // heuristic. 

  // marching until arrive at 20.0 .

  float t = 0.0;

  // if marching failed, returns -1.0(negative value).
  float result = -1.0;

  for(int i = 0; i < ITERATION; i++){
    if(h < precis || t > maxd){ break; }
  // add heuristic value.
    h = map(camera + t * ray);
    t += h;
  }
// if t < maxd, marching success. returns t.
  if(t < maxd){ result = t; }
  return result;
}
// camera rotation.
void transform(inout vec3 p){
// AUTO MODE.
  p = rotateX(p, PI * time * 0.3);
  p = rotateY(p, PI* time * 0.15);
}
// background color(grey).
vec3 getBackground(vec2 p){
  vec3 color = vec3(0.85);
  return color * (0.4 + p.y * 0.3);
}
// main code.
void main(void) {
  // y:-1.0～1.0
  vec2 p = (2.0 * gl_FragCoord.xy - resolution.xy) / min(resolution.x, resolution.y);
  // get background color.
  vec3 color = getBackground(p);
  // set ray vector.
  vec3 ray = normalize(vec3(p, -1.8));
  // set camera position. (on z axis, 4.5)
  vec3 camera = vec3(0.0, 0.0, 4.5);
  // lighting.
  vec3 light = normalize(vec3(0.5, 0.8, 3.0));
  // rotation(ray, camera, lighting, all.)
  transform(ray);
  transform(camera);
  transform(light);
  // get marching result.
  float t = march(ray, camera);
  // if t is negative, color is background color.
  if(t > -0.001){
    vec3 pos = camera + t * ray; // on the surface.
    vec3 n = calcNormal(pos); // get normal vector.
    // lighting effect.
    float diff = clamp((dot(n, light) + 0.5) * 0.7, 0.3, 1.0);
    // coloring.
    float hue = (atan(pos.z, pos.x) + PI) * 0.5 / PI;
    float saturation = (1.0 - atan(length(pos.xz), pos.y) / PI) + 0.4;
    float brightness = length(pos);
    vec3 baseColor = getRGB(hue, saturation, brightness);
    // blending.
    baseColor *= diff;
    // fadeout effect.
    color = mix(baseColor, color, tanh(t * 0.1));
  }
  // it's all.
  glFragColor = vec4(color, 1.0);
}
