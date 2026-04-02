#version 420

// original https://www.shadertoy.com/view/XccXW8

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Shader optimization kata. Public domain.

// Trying the cut and project method for aperiodic tilings.
// Tile substitution is better in practice,
// but cut-and-project doesn't hardcode the layout
// and I wanted to understand the math behind it.

// 4D is Ammann–Beenker and 5D is Penrose/Robinson,
// but my favourite is the blue projection from 6 dimensions.
// Does it have a name?

// References:

// - "Pestujeme lineární algebru" by Luboš Motl and Miloš Zahradník (in Czech), ch 10.1:
//   https://matematika.cuni.cz/zahradnik-pla.html

// - "Ammann-Beenker" by knighty (to double-check my math):
//   https://www.shadertoy.com/view/MddfzH

// We'll be projecting 2D faces of n-D cubes onto an angled 2D plane.
// We need to check all possible face orientations (pairs of n-D axes).
// Normally you would loop over indices (i.e. i=0, j=3),
// but it's faster to select the axes directly (1,0,0,1).
// It's also more friendly to GLSL compilers that don't like branches.

// For each tile orientation, four neighboring tiles need to be tested.
// I think there should be a way to check early
// which of the four tiles may contain the pixel,
// but couldn't figure it out (or prove it's impossible).

// Functions missing in old GLSL versions (if you need those).
/*
float Round(float v) { return floor(v + .5); }
vec2 Round(vec2 v)   { return floor(v + .5); }
vec3 Round(vec3 v)   { return floor(v + .5); }
vec4 Round(vec4 v)   { return floor(v + .5); }
mat2 Inverse(mat2 m) {
  float a = m[0].x, b = m[1].x,
        c = m[0].y, d = m[1].y;
  return mat2(d,-c, -b,a) / (a*d - b*c);
}
*/

float lw = .04;  // line width
float aa = 1.;  // antialiasing width (depends on resolution and zoom)

// Rotate by d degrees. 
mat2 rot(float d) {
  return mat2(cos(radians(d + vec4(0,-90,90,0))));
}

// A 5D|6D vector will be represented by a vec4 with an extra float|vec2.
// Kinda wordy, but faster than a struct.
float Dot(float a0,vec4 a, float b0,vec4 b) { return a0*b0 + dot(a,b); }
float Dot(vec2 a0,vec4 a, vec2 b0,vec4 b) { return dot(a0,b0) + dot(a,b); }

// We'll be projecting onto this 2D plane laid out in n-D space.
// Its dual vectors are arranged in a regular 2n-gon:
//   U = (1, cos(a), cos(2a) ... cos((n–1)a)),
//   V = (0, sin(a), sin(2a) ... sin((n–1)a)),
// where a = 360° / 2n.
// The original n-D cubes are axis-aligned,
// so their edges will be projected into the dual directions.

const float M4 = sqrt(2./4.);  // normalisation factor
const vec4 U4 = M4 * cos(radians(360./8.) * vec4(0,1,2,3));
const vec4 V4 = M4 * sin(radians(360./8.) * vec4(0,1,2,3));

const float M5 = sqrt(2./5.);
const float U50 = M5;
const vec4 U5   = M5 * cos(radians(360./10.) * vec4(1,2,3,4));
const float V50 = 0.;
const vec4 V5   = M5 * sin(radians(360./10.) * vec4(1,2,3,4));

const float M6 = sqrt(2./6.);
const vec2 U60 = M6 * cos(radians(360./12.) * vec2(0,1));
const vec4 U6  = M6 * cos(radians(360./12.) * vec4(2,3,4,5));
const vec2 V60 = M6 * sin(radians(360./12.) * vec2(0,1));
const vec4 V6  = M6 * sin(radians(360./12.) * vec4(2,3,4,5));

// Project a point onto the 2D plane.
vec2 proj(vec4 p) { return vec2(dot(p,U4), dot(p,V4)); }
vec2 proj(float p0,vec4 p) { return vec2(Dot(p0,p,U50,U5), Dot(p0,p,V50,V5)); }
vec2 proj(vec2 p0,vec4 p) { return vec2(Dot(p0,p,U60,U6), Dot(p0,p,V60,V6)); }

//// 4D: Ammann–Beenker tiling

// Test if a point 'p' lies in a tile.
// Return the barycentric distance to the closest edge, or zero if it's outside.
//   The vectors 'a' and 'b' are the tile orientation (each picks an n-D axis),
//   the offset 's' selects one of the four neighbors with the same orientation
//   and 'm' converts barycentric (AB) <-> projected (UV) coodinates.
float tile4(vec4 p, mat2 m, vec2 s, vec4 a, vec4 b) {
  // on the a,b axes we're exactly in the center of a cube (0.5)
  // on the other axes, unproject the center point back to n-D space
  vec2 q = s * m;
  // round to find out in which n-D cube we are
  // subtract from p to get position in cube: p[...] = -0.5..0.5
  p -= (vec4(1)-a-b) * round(q.x*U4 + q.y*V4);
  // project to UV, get barycentric distance to both edges (inside = positive)
  vec2 f = .5 - abs(m * proj(p) - s);
  return max(0., min(f.x, f.y));  // pick the closest one, zero outside
}

// Test if a point lies in the four neighboring tiles with the same 2D orientation.
// Return the color multiplier (bright in the center, dark antialiased edges).
//   The vectors 'a' and 'b' are the tile orientation (each picks an n-D axis).
float t4(vec4 p, vec4 a, vec4 b) {
  mat2 m = inverse(mat2(proj(a), proj(b)));  // barycentric (AB) <-> projected (UV)
  vec2 r = round(vec2(dot(p,a), dot(p,b)));  // closest vertex on the (a,b) plane
  vec2 s = vec2(.5, -.5);
  float d = tile4(p,m,r+s.xx,a,b) +
            tile4(p,m,r+s.xy,a,b) +
            tile4(p,m,r+s.yx,a,b) +
            tile4(p,m,r+s.yy,a,b);  // test four squares around the closest vertex

  // highlight tile center
  return d +
    // tile edges: make them all the same width
    smoothstep(lw-aa, lw+aa,
      min(d / length(vec2(m[0].x, m[1].x)),
          d / length(vec2(m[0].y, m[1].y))));
}

// Return the color of the 4D tiling.
vec3 dim4(vec2 x) {
  // rotate 22.5 degrees to make stars upright
  mat2 R = rot(22.5);
  float zoom = 5.;
  vec2 screen = R * zoom * x;
  aa = 1.5*zoom/resolution.y;

  // move upwards (= away from the center)
  vec4 p = screen.x*U4 + screen.y*V4 - time*(R[1].x*U4 + R[1].y*V4);

  vec2 u = vec2(0,1);
  vec3 edge = vec3(.1,.06,.03);
  vec3 c = edge;
  
  // try all 6 face orientations
  c += (vec3(.9,.5,.1) - edge) * t4(p,u.yxxx,u.xyxx);
  c += (vec3(.8,.3, 0) - edge) * t4(p,u.yxxx,u.xxyx);
  c += (vec3(.6,.12,0) - edge) * t4(p,u.yxxx,u.xxxy);
  c += (vec3(.4,.2,.1) - edge) * t4(p,u.xyxx,u.xxyx);
  c += (vec3(.7,.4,.2) - edge) * t4(p,u.xyxx,u.xxxy);
  c += (vec3(.6,.3,.1) - edge) * t4(p,u.xxyx,u.xxxy);
  return c;
}

//// 5D: Penrose / Robinson tiling

float tile5(float p0,vec4 p, mat2 m, vec2 s, float a0,vec4 a, float b0,vec4 b) {
  vec2 q = s * m;
  p0 -=    (1.-a0-b0) * round(q.x*U50 + q.y*V50);
  p  -= (vec4(1)-a-b) * round(q.x*U5  + q.y*V5);
  vec2 f = abs(m * proj(p0,p) - s);
  return max(0., .5 - max(f.x, f.y));
}

float t5(float p0,vec4 p, float a0,vec4 a, float b0,vec4 b) {
  mat2 m = inverse(mat2(proj(a0,a), proj(b0,b)));
  vec2 r = round(vec2(Dot(p0,p,a0,a), Dot(p0,p,b0,b)));
  vec2 s = vec2(.5, -.5);
  float d = tile5(p0,p,m,r+s.xx,a0,a,b0,b) +
            tile5(p0,p,m,r+s.xy,a0,a,b0,b) +
            tile5(p0,p,m,r+s.yx,a0,a,b0,b) +
            tile5(p0,p,m,r+s.yy,a0,a,b0,b);
  return d + smoothstep(lw-aa, lw+aa,
    min(d / length(vec2(m[0].x, m[1].x)),
        d / length(vec2(m[0].y, m[1].y))));
}

vec3 dim5(vec2 x) {
  mat2 R = rot(18. + 30.);
  float zoom = 5.;
  vec2 screen = R * zoom * x;
  aa = 1.5*zoom/resolution.y;
  R = rot(-120.) * R;

  float p0 = screen.x*U50 + screen.y*V50 - time*(R[1].x*U50 + R[1].y*V50);
  vec4 p = screen.x*U5 + screen.y*V5 - time*(R[1].x*U5 + R[1].y*V5);

  vec2 u = vec2(0,1);
  vec3 edge = vec3(.04,.1,.04);
  vec3 c = edge;
  
  // try all 10 face orientations
  c += (vec3(.4,.9,.4) - edge) * t5(p0,p,u.y,u.xxxx,u.x,u.yxxx);
  c += (vec3(.6,.7,.2) - edge) * t5(p0,p,u.y,u.xxxx,u.x,u.xyxx);
  c += (vec3(.3,.5, 0) - edge) * t5(p0,p,u.y,u.xxxx,u.x,u.xxyx);
  c += (vec3(.2,.3, 0) - edge) * t5(p0,p,u.y,u.xxxx,u.x,u.xxxy);
  c += (vec3( 0,.3,.2) - edge) * t5(p0,p,u.x,u.yxxx,u.x,u.xyxx);
  c += (vec3( 0,.5,.4) - edge) * t5(p0,p,u.x,u.yxxx,u.x,u.xxyx);
  c += (vec3(.2,.7,.6) - edge) * t5(p0,p,u.x,u.yxxx,u.x,u.xxxy);
  c += (vec3(.3,.6, 0) - edge) * t5(p0,p,u.x,u.xyxx,u.x,u.xxyx);
  c += (vec3( 0,.4, 0) - edge) * t5(p0,p,u.x,u.xyxx,u.x,u.xxxy);
  c += (vec3( 0,.6,.3) - edge) * t5(p0,p,u.x,u.xxyx,u.x,u.xxxy);
  return c;
}

//// 6D

float tile6(vec2 p0,vec4 p, mat2 m, vec2 s, vec2 a0,vec4 a, vec2 b0,vec4 b) {
  vec2 q = s * m;
  p0 -= (vec2(1)-a0-b0) * round(q.x*U60 + q.y*V60);
  p  -=   (vec4(1)-a-b) * round(q.x*U6  + q.y*V6);
  vec2 f = abs(m * proj(p0,p) - s);
  return max(0., .5 - max(f.x, f.y));
}

float t6(vec2 p0,vec4 p, vec2 a0,vec4 a, vec2 b0,vec4 b) {
  mat2 m = inverse(mat2(proj(a0,a), proj(b0,b)));
  vec2 r = round(vec2(Dot(p0,p,a0,a), Dot(p0,p,b0,b)));
  vec2 s = vec2(.5, -.5);
  float d = tile6(p0,p,m,r+s.xx,a0,a,b0,b) +
            tile6(p0,p,m,r+s.xy,a0,a,b0,b) +
            tile6(p0,p,m,r+s.yx,a0,a,b0,b) +
            tile6(p0,p,m,r+s.yy,a0,a,b0,b);
  return d + smoothstep(lw-aa, lw+aa,
    min(d / length(vec2(m[0].x, m[1].x)),
        d / length(vec2(m[0].y, m[1].y))));
}

vec3 dim6(vec2 x) {
  mat2 R = rot(15.);
  float zoom = 5.;
  vec2 screen = R * zoom * x;
  aa = 1.5*zoom/resolution.y;
  R = rot(-240.) * R;

  vec2 p0 = screen.x*U60 + screen.y*V60 - time*(R[1].x*U60 + R[1].y*V60);
  vec4 p = screen.x*U6 + screen.y*V6 - time*(R[1].x*U6 + R[1].y*V6);

  vec2 u = vec2(0,1);
  vec3 edge = vec3(0,.07,.15);
  vec3 c = edge;

  // try all 15 face orientations
  c += (vec3(.1,.7, 1) - edge) * t6(p0,p,u.yx,u.xxxx,u.xy,u.xxxx);
  c += (vec3( 0,.6,.9) - edge) * t6(p0,p,u.yx,u.xxxx,u.xx,u.yxxx);
  c += (vec3( 0,.4,.7) - edge) * t6(p0,p,u.yx,u.xxxx,u.xx,u.xyxx);
  c += (vec3( 0,.2,.5) - edge) * t6(p0,p,u.yx,u.xxxx,u.xx,u.xxyx);
  c += (vec3( 0,.1,.3) - edge) * t6(p0,p,u.yx,u.xxxx,u.xx,u.xxxy);
  c += (vec3(.1,.45,1) - edge) * t6(p0,p,u.xy,u.xxxx,u.xx,u.yxxx);
  c += (vec3( 0,.3,.8) - edge) * t6(p0,p,u.xy,u.xxxx,u.xx,u.xyxx);
  c += (vec3( 0,.2,.6) - edge) * t6(p0,p,u.xy,u.xxxx,u.xx,u.xxyx);
  c += (vec3( 0,.1,.4) - edge) * t6(p0,p,u.xy,u.xxxx,u.xx,u.xxxy);
  c += (vec3(.3,.4,.9) - edge) * t6(p0,p,u.xx,u.yxxx,u.xx,u.xyxx);
  c += (vec3(.2,.2,.6) - edge) * t6(p0,p,u.xx,u.yxxx,u.xx,u.xxyx);
  c += (vec3(.1,.1,.4) - edge) * t6(p0,p,u.xx,u.yxxx,u.xx,u.xxxy);
  c += (vec3(.1,.5,.5) - edge) * t6(p0,p,u.xx,u.xyxx,u.xx,u.xxyx);
  c += (vec3( 0,.6,.7) - edge) * t6(p0,p,u.xx,u.xyxx,u.xx,u.xxxy);
  c += (vec3( 0,.3,.4) - edge) * t6(p0,p,u.xx,u.xxyx,u.xx,u.xxxy);
  return c;
}

// Draw all three tilings.

void main(void) { //WARNING - variables void (out vec4 o, vec2 x) { need changing to glFragColor and gl_FragCoord.xy

  vec2 x=gl_FragCoord.xy;

  // y: -1..1, slowly rotate
  vec2 p = rot(10.*time) * ((x+x-resolution.xy) / resolution.y);

  // Find out in which triangular segment we are.
  vec3 hex = vec3(.5, -.5, -.5*sqrt(3.));
  vec3 q = vec3(p.x, dot(p,hex.xz), dot(p,hex.yz));  // triangular coords
  vec3 c;   // inner color
  float d;  // distance from boundary
  if (q.y<0. && q.z<0.) {
    c = dim4(p);
    d = min(-q.y, -q.z);
  }
  else if (q.x>0.) {
    c = dim5(p);
    d = min(q.x, q.y);
  }
  else {
    c = dim6(p);
    d = min(-q.x, q.z);
  }

  c *= 2.5 / (2. + dot(p,p));  // vignette
  aa = 1.5 / resolution.y;
  c = 1. - (1.-c) * smoothstep(.01-aa, .01+aa, d);  // white boundary
  //c *= smoothstep(.01-aa, .01+aa, d);  // black boundary

  glFragColor = vec4(sqrt(c),1);
}