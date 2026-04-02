#version 420

// original https://www.shadertoy.com/view/tsXBzs

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

////////////////////////////////////////////////////////////////////////////////
//
// Cubeworld
// Matthew Arcus, mla, 2020
//
// The entire world consists of a single cube, each wall of the cube is just a
// passage back into the cube, through a different wall.
//
// Mouse to look around. Haven't worked out the details of doing lighting yet,
// so just uses fogging to indicate distance.
//
// Came out of thinking about tmst's excellent "Non-Euclidean World":
// https://www.shadertoy.com/view/WsXcWn
//
////////////////////////////////////////////////////////////////////////////////

const float PI = 3.1415927;
float AA = 2.0;
float maxdist = 15.0;
int maxiterations = 30;

bool alert = false;
void assert(bool b) {
  if (!b) alert = true;
}

float stepsize(vec3 p, vec3 r) {
  // Want least k such that p + kr has coordinate 1 in some dimension
  // eg. p.x+kr.x = 1 => k = (1-p.x)/r.x
  // eg. p.x+kr.x = 0 => k = -p.x/r.x
  // Want k positive, so assuming p.x is 0 < p.x < 1, depends on r.
  float k = 1e8;
  if (r.x > 0.0) k = (1.0-p.x)/r.x;
  else if (r.x < 0.0) k = min(k,-p.x/r.x);
  if (r.y > 0.0) k = min(k,(1.0-p.y)/r.y);
  else if (r.y < 0.0) k = min(k,-p.y/r.y);
  if (r.z > 0.0) k = min(k,(1.0-p.z)/r.z);
  else if (r.z < 0.0) k = min(k,-p.z/r.z);
  return k; // What if we cross 2 boundaries?
}

int gethitside(vec3 p) {
  if (p.x > 1.0) return 0;
  if (p.x < 0.0) return 1;
  if (p.y > 1.0) return 2;
  if (p.y < 0.0) return 3;
  if (p.z > 1.0) return 4;
  if (p.z < 0.0) return 5;
  return -1;
}

void nextdir(int hitside, inout vec3 r) {
  if (hitside == 0) { r.yz = vec2(r.z,-r.y); r.xz = r.zx; } // Reflection in x=y
  if (hitside == 1) { r.yz = vec2(r.z,-r.y); r.xz = vec2(-r.z,r.x); } // Rotation by 90 deg
  if (hitside == 4) { r.xz = vec2(r.z,-r.x); r.yz = vec2(-r.z,r.y); } // Opposite rotation by 90 deg
  if (hitside == 5) { r.xz = r.zx; r.yz = vec2(-r.z,r.y); } // Reflection in x=y
}

void nextpos(int hitside, inout vec3 p) {
  if (hitside == 0) p.x -= 1.0;
  if (hitside == 1) p.x += 1.0;
  if (hitside == 2) p.y -= 1.0;
  if (hitside == 3) p.y += 1.0;
  if (hitside == 4) p.z -= 1.0;
  if (hitside == 5) p.z += 1.0;
  if (hitside == 0) { p.yz = vec2(p.z,1.0-p.y); p.xz = p.zx; } // Reflection in x=y
  if (hitside == 1) { p.yz = vec2(p.z,1.0-p.y); p.xz = vec2(1.0-p.z,p.x); } // Rotation by 90 deg
  if (hitside == 4) { p.xz = vec2(p.z,1.0-p.x); p.yz = vec2(1.0-p.z,p.y); } // Opposite rotation by 90 deg
  if (hitside == 5) { p.xz = p.zx; p.yz = vec2(1.0-p.z,p.y); } // Reflection in x=y
}

bool traceray(inout vec3 p, inout vec3 r, out vec3 n, out int type, out float totaldist) {
  totaldist = 0.0;
  vec3 p0 = p;
  for (int i = 0; i < maxiterations; i++) {
    if (i > 0) {
      // find intersection with sphere at p0
      vec3 q = p-p0;
      //(q+kr).(q+kr) = r2
      float A = dot(r,r);
      float B = dot(q,r);
      float r = 0.05;
      float r2 = r*r;
      float C = dot(q,q)-r2;
      float D = B*B-A*C;
      if (D >= 0.0) {
        float t = (-B-sqrt(D))/A;
        totaldist += t;
        n = q+t*r;
        type = 6;
        return true;
      }
    }
    float eps = 1e-3;
    float k = stepsize(p,r)+eps;
    p += k*r;
    totaldist += k;
    if (totaldist > maxdist) return false;
    // determine the hit side
    int hitside = gethitside(p);
    type = hitside;
    vec3 border = min(p,1.0-p);
    // Have we hit the wall frames?
    if (hitside/2 == 0 && min(border.y,border.z) < 0.05) { n = vec3(1,0,0); return true; }
    if (hitside/2 == 1 && min(border.z,border.x) < 0.05) { n = vec3(0,1,0); return true; }
    if (hitside/2 == 2 && min(border.x,border.y) < 0.05) { n = vec3(0,0,1); return true; }
    // Advance p and r
    nextpos(hitside,p);
    nextdir(hitside,r);
  }
  return false;
}

void moveforward(inout vec3 p, inout vec3 r, vec3 dir, float t) {
  for (int i = 0; i < 50; i++) {
    float k = stepsize(p,dir) ;
    float eps = 1e-3;
    if (t <= k) break;
    k += eps;
    p += k*dir;
    t -= k;
    int hitside = gethitside(p);
    nextpos(hitside,p);
    nextdir(hitside,dir);
    nextdir(hitside,r);
  }
  p += t*dir;
}

vec3 getcolor(int type) {
  if (type == 0) return vec3(1,0,0);
  if (type == 1) return vec3(0,1,0);
  if (type == 2) return vec3(0,0,1);
  if (type == 3) return vec3(1,1,0);
  if (type == 4) return vec3(1,0,1);
  if (type == 5) return vec3(0,1,1);
  return vec3(0.2);
}

vec3 raycolor(vec3 p, vec3 r) {
    int type; vec3 n; float totaldist;
    vec3 bgcol = vec3(1,1,0.5);
    //vec3 bgcol = vec3(1);
    if (!traceray(p,r,n,type,totaldist)) return bgcol;
    vec3 basecolor = getcolor(type);
    vec3 color = basecolor;
    color *= 0.5;
    color = mix(color,bgcol,totaldist/maxdist);
    return color;
}

vec2 rotate(vec2 p, float t) {
  return mat2(cos(t),sin(t),-sin(t),cos(t))*p;
}

vec3 transform(in vec3 p) {
  //if (mouse*resolution.xy.x > 0.0) {
  //  float theta = -(2.0*mouse*resolution.xy.y-resolution.y)/resolution.y*PI;
  //  float phi = -(2.0*mouse*resolution.xy.x-resolution.x)/resolution.x*PI;
  //  p.yz = rotate(p.yz,theta);
  //  p.zx = rotate(p.zx,-phi);
  //}
  if (false) {
    p.zx = rotate(p.zx,time * 0.2);
    p.xy = rotate(p.xy,time * 0.125);
  }
  return p;
}

void main(void) {
  vec3 col = vec3(0);
  for (float i = 0.0; i < AA; i++) {
    for (float j = 0.0; j < AA; j++) {
      vec2 uv = (2.0*(gl_FragCoord.xy+vec2(i,j)/AA)-resolution.xy)/resolution.y;
      vec3 r = vec3(uv,2);
      vec3 p = vec3(0.5);
      r = transform(r);
      r = normalize(r); // Normalize after transform
      moveforward(p,r,vec3(0,0,1),mod(0.2*time,4.0));
      vec3 c = raycolor(p,r);
      col += c;
    }
  }
  col /= float(AA*AA);
  col = pow(col,vec3(0.4545));
  if (alert) col = vec3(1,0,0);
  glFragColor = vec4(col,1);
}
