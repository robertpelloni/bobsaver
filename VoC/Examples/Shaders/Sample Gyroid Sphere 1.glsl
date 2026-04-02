#version 420

// original https://www.shadertoy.com/view/wddfDM

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define MIN_DIST 0.001
#define MAX_DIST 10.

#define PI 3.1415926
#define TAU 6.2831853

float opIntersection(float d1, float d2) {
  return max(d1, d2);
}

// from https://github.com/doxas/twigl
mat3 rotate3D(float angle, vec3 axis){
    vec3 a = normalize(axis);
    float s = sin(angle);
    float c = cos(angle);
    float r = 1.0 - c;
    return mat3(
        a.x * a.x * r + c,
        a.y * a.x * r + a.z * s,
        a.z * a.x * r - a.y * s,
        a.x * a.y * r - a.z * s,
        a.y * a.y * r + c,
        a.z * a.y * r + a.x * s,
        a.x * a.z * r + a.y * s,
        a.y * a.z * r - a.x * s,
        a.z * a.z * r + c
    );
}

float sdSphere(vec3 p, float radius) {
  return length(p) - radius;
}

float sdGyroid(vec3 p, float scale, float thickness, float bias) {
  p *= scale;
  return abs(dot(sin(p*.5), cos(p.zxy * 1.23)) - bias) / scale - thickness;
}

vec2 sceneSDF(vec3 p) {
  p *= rotate3D(time * .2, vec3(0, 1, 0));
  
  float gyroid = sdGyroid(p, 10., .01, 0.) * .55;
  float d = opIntersection(sdSphere(p, 1.5), gyroid);

  return vec2(d, 1.);
}

// Compute camera-to-world transformation.
mat3 setCamera(in vec3 ro, in vec3 ta, float cr) {
  vec3 cw = normalize(ta - ro);
  vec3 cp = vec3(sin(cr), cos(cr), 0.0);
  vec3 cu = normalize(cross(cw,cp));
  vec3 cv = normalize(cross(cu,cw));
  return mat3(cu, cv, cw);
}

// Cast a ray from origin ro in direction rd until it hits an object.
// Return (t,m) where t is distance traveled along the ray, and m
// is the material of the object hit.
vec2 castRay(in vec3 ro, in vec3 rd) {
    float tmin = MIN_DIST;
    float tmax = MAX_DIST;
   
#if 0
    // bounding volume
    float tp1 = (0.0 - ro.y) / rd.y; 
    if(tp1 > 0.0) tmax = min(tmax, tp1);
    float tp2 = (1.6 - ro.y) / rd.y; 
    if(tp2 > 0.0) { 
        if(ro.y > 1.6) tmin = max(tmin, tp2);
        else tmax = min(tmax, tp2 );
    }
#endif
    
    float t = tmin;
    float m = -1.0;
    for(int i = 0; i < 100; i++) {
        float precis = 0.0005 * t;
        vec2 res = sceneSDF(ro + rd * t);
        if(res.x < precis || t > tmax) break;
        t += res.x;
        m = res.y;
    }

    if(t > tmax) m =- 1.0;
    return vec2(t, m);
}

// Compute normal vector to surface at pos, using central differences method?
vec3 calcNormal(in vec3 pos) {
  // epsilon = a small number
  vec2 e = vec2(1.0, -1.0) * 0.5773 * 0.0005;

  return normalize(
    e.xyy * sceneSDF(pos + e.xyy).x + 
    e.yyx * sceneSDF(pos + e.yyx).x + 
    e.yxy * sceneSDF(pos + e.yxy).x + 
    e.xxx * sceneSDF(pos + e.xxx).x
  );
}

vec3 computeColor(vec3 ro, vec3 rd, vec3 pos, float d, float m) {
  vec3 nor = calcNormal(pos);
  return nor;
}

// Figure out color value when casting ray from origin ro in direction rd.
vec3 render(in vec3 ro, in vec3 rd) { 
  // cast ray to nearest object
  vec2 res = castRay(ro, rd);
  float distance = res.x; // distance
  float materialID = res.y; // material ID

  vec3 col = vec3(245,215,161)/255.;
  if(materialID > 0.0) {
    vec3 pos = ro + distance * rd;
    col = computeColor(ro, rd, pos, distance, materialID);
  }
  return vec3(clamp(col, 0.0, 1.0));
}

void main(void) {
  // Ray Origin)\t
  vec3 ro = vec3(2.3);
  vec3 ta = vec3(0.0);
  // camera-to-world transformation
  mat3 ca = setCamera(ro, ta, 0.0);

  vec3 color = vec3(0.0);

  vec2 p = (-resolution.xy + 2.0 * gl_FragCoord.xy) / resolution.y;

  // ray direction
  vec3 rd = ca * normalize(vec3(p.xy, 2.0));

  // render\t
  vec3 col = render(ro, rd);

  color += col;

  glFragColor = vec4(color, 1.0);
}
