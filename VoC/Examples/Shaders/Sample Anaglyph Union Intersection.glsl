#version 420

// original https://www.shadertoy.com/view/WdcGRs

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/**
  Part two of Learning of to RayMarch!
  updated functions for light and shadow,
  fixed  issues cause Min_Dist and Epsilon.
  Learning shapes and how to color items 
  and use specific materials.
*/

precision mediump float;
// Changes size of balls and hole in board
const float size = .65;
// Amount of smoothing between objects
const float smoothing = 2.35;

const float PI = 3.14159;
const float interpupillary = 0.3;

// Define Basic ray_marching Parameters
#define MAX_STEPS 100
#define MAX_DIST 45.
#define MIN_DIST .01
#define EPSILON .0001

//https://www.iquilezles.org/www/articles/smin/smin.htm
float smin( float a, float b, float k ){
  float res = exp2( -k*a ) + exp2( -k*b );
  return -log2( res )/k;
}

mat2 r2(float a){ 
  float c = cos(a); 
  float s = sin(a); 
  return mat2(c, s, -s, c); 
}
  
float sphereSDF(vec3 p, float s) {
  return length(p-vec3(0.)) - s;
}

float boxSDF(vec3 p, vec3 s) {
  vec3 d = abs(p-vec3(0.)) - s;
  return min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0));
}

vec2 rotate(vec2 p, float t) {
  return p * cos(t) + vec2(p.y, -p.x) * sin(t);
}

float map_scene(vec3 p) {
  float bmp = 12.;
  float displacement = sin(bmp*p.x)*sin(bmp*p.y)*sin(bmp* p.z)*.04;
  float floorDist = boxSDF(vec3(p.x,p.y+5.,p.z),vec3(15.5,.1, 15.5))+ displacement;
  
  vec3 q2 = p;
  vec3 q = p;

  q.xz *= r2(-sin(time*.6));
  q.xy *= r2(-sin(time)* 0.4);
  float boxDist = boxSDF(q, vec3(2.5, .1, 2.5));
  float cullDist = sphereSDF(q, size * 3.5);

  float shapeDist = max(-cullDist, boxDist);

  p.y += 1. * cos(time * 1.25) + .5;
  p.x -= sin(time * .7);
  float spA = sphereSDF(p, size * .5);

  q.z += .35 * sin(time * 2.5) + .6;
  q.x += cos(time* 2.);
  float spB = sphereSDF(q, size * .5);
  
  p.y -= 1.25 * cos(125. + time) + 2.5;
  p.x += sin(125. + time * 2.);
  float spC = sphereSDF(p, size * .5);

  q.z -= .75 * sin(time * 1.15) * 1.5;
  q.x -= .85 * cos(time* 1.7) + 1.7;
  float spD = sphereSDF(q, size * .5);
  
  float sphereA = smin(spA, spB, smoothing);
  float sphereB = smin(spC, spD, smoothing);
  float sphereDist = smin(sphereA, sphereB, smoothing);
  float unionDist = smin(sphereDist, shapeDist, smoothing);
  return min(unionDist, floorDist);
}

float ray_march(vec3 rayorigin, vec3 raydirection) {
  float distance = 0.0;
  float position = map_scene(rayorigin);
  for(int i=0; i < MAX_STEPS; i++) {
    position = map_scene(rayorigin + distance * raydirection);
    distance += position;
    if(distance>MAX_DIST || position<MIN_DIST) break;
  }
  return distance;
}

vec3 get_normal(vec3 p) {
   return normalize(vec3(
    map_scene(vec3(p.x + EPSILON, p.y, p.z)) - map_scene(vec3(p.x - EPSILON, p.y, p.z)),
    map_scene(vec3(p.x, p.y + EPSILON, p.z)) - map_scene(vec3(p.x, p.y - EPSILON, p.z)),
    map_scene(vec3(p.x, p.y, p.z  + EPSILON)) - map_scene(vec3(p.x, p.y, p.z - EPSILON))
  ));
}

float get_light(vec3 p, vec3 lightPos){
  vec3 tolight = normalize(lightPos - p);
  vec3 n = get_normal(p);
  float diffuse = dot(n, tolight);
  float distance_tolight = ray_march(p + n * .1 * 2., n);
  
  /** shadow */
  if(distance_tolight<length(lightPos-p)) diffuse *= .1;

  // diffuse *= clamp(distance_tolight, 0., 1.);
  return clamp(diffuse, 0., 1.);
}

mat3 get_camera(vec3 rayorigin, vec3 ta, float rotation) {
    vec3 cw = normalize(ta-rayorigin);
    vec3 cp = vec3(sin(rotation), cos(rotation),0.0);
    vec3 cu = normalize( cross(cw,cp) );
    vec3 cv = normalize( cross(cu,cw) );
    return mat3( cu, cv, cw );
}

void main(void) {
  /** normalizing center coords */
  vec2 uv = (gl_FragCoord.xy - .5 * resolution.xy ) / resolution.y;
  vec3 col = vec3(0.);
  float red = 0.;
  float cyan = 0.;

  /** ray origin and ray direction for camera */

  vec3 rayorigin = vec3(0.,3.25,-13.);
  vec3 target = vec3(0.);
  mat3 cameraMatrix = mat3(0.);
  vec3 rd = vec3(0.);

  /** lights - movment and pre render */
  vec3 lightPos =  vec3(5., 3., -5.);

  /** Anaglyph process */
  vec3 p = vec3(.0);
  float d = 0.; 
  float zoomfactor = 2.0;
    
  /** Red Shift */
  rayorigin.x += interpupillary;
  cameraMatrix = get_camera(rayorigin, target, 0. );
  rd = cameraMatrix * normalize( vec3(uv.xy, zoomfactor) );
  d = ray_march(rayorigin, rd);
  p = d * rd + rayorigin;
  red += get_light(p, lightPos);

  /** Cyan Shift */
  rayorigin.x -= interpupillary;
  cameraMatrix = get_camera(rayorigin, target, 0. );
  rd = cameraMatrix * normalize( vec3(uv.xy, zoomfactor) );
  d = ray_march(rayorigin, rd);
  p = d * rd + rayorigin;
  cyan += get_light(p, lightPos);
  
  /** Mixdown */
  col = vec3( red, vec2(cyan) );

  if (d > MAX_DIST - 0.0001) {
    col = vec3(uv.y) * 1.5;
  } 

  glFragColor = vec4(col, 1.0);
}
