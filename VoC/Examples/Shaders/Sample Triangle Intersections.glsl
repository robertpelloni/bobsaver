#version 420

// original https://www.shadertoy.com/view/llsfWl

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// (c) Matthew Arcus 2017
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

// Experimenting with ray-triangle intersection algorithms.
// Finding intersection requires solving a linear system of equations.
// Can solve directly with matrix inversion or, possibly faster,
// use Cramer's rule, with simplifications (Möller, Trumbore algorithm).

// Draws a twisted prism of N triangles centred around origin.
// Color is a direct conversion of barycentric coords to RGB.

const int N = 50;
float scale = 1.5;

const float PI = 3.14159;
const float TWOPI = 2.0*PI;

// find a,b such that:
// p + kr = av0 + bv1 + (1-a-b)v2 = a(v0-v2)+b(v1-v2)+v2
// ie. -kr + a(v0-v2) + b(v1-v2) = p-v2
// return vec4(k,a,b,c) where c = 1-a-b
#if 0
// Solve linear system with a matrix inversion
vec4 triangle(vec3 p, vec3 r, vec3 v0, vec3 v1, vec3 v2) {
  vec3 a = inverse(mat3(-r,v0-v2,v1-v2))*(p-v2);
  return vec4(a,1.0-a.y-a.z);
}
#else
// Standard algorithm by Tomas Möller and Ben Trumbore.
// Uses Cramer's rule with some simplifications to solve linear system as above.
// http://webserver2.tecgraf.puc-rio.br/~mgattass/cg/trbRR/Fast%20MinimumStorage%20RayTriangle%20Intersection.pdf
vec4 triangle(vec3 o, vec3 d, vec3 v0, vec3 v1, vec3 v2) {
  // find a,b such that:
  // p + kr = av0 + bv1 + (1-a-b)v2 = a(v0-v2)+b(v1-v2)+v2
  // ie. -kr + a(v0-v2) + b(v1-v2) = p-v2
  vec3 e1 = v0 - v2;
  vec3 e2 = v1 - v2;
  vec3 t = o - v2;
  vec3 p = cross(d,e2);
  vec3 q = cross(t,e1);
  vec3 a = vec3(dot(q,e2),dot(p,t),dot(q,d))/dot(p,e1);
  return vec4(a,1.0-a.y-a.z);
}
#endif

// Rotation matrices, nb: column major.
// Matrix from quaternion
mat3 qrot(vec4 q) {
  float x = q.x, y = q.y, z = q.z, w = q.w;
  return 2.0*mat3(0.5-y*y-z*z, x*y+z*w,     x*z-y*w,
                  x*y-z*w,     0.5-x*x-z*z, y*z+x*w,
                  x*z+y*w,     y*z-x*w,     0.5-x*x-y*y);
}

// Rotations about x,y,z axes.
mat3 xrotate(float theta) {
  return mat3(1,0,0,0,cos(theta),sin(theta),0,-sin(theta),cos(theta));
}
mat3 yrotate(float theta) {
  return mat3(cos(theta),0,sin(theta),0,1,0,-sin(theta),0,cos(theta));
}
mat3 zrotate(float theta) {
  return mat3(cos(theta),sin(theta),0,-sin(theta),cos(theta),0,0,0,1);
}

void main(void) {
  vec2 xy = scale*(2.0*gl_FragCoord.xy - resolution.xy)/resolution.y;
  // p+kq is viewing ray
  // Rotate camera with quaterion.
  vec3 axis = normalize(vec3(1,1,1));
  float theta = -0.1618*time;
  mat3 m = qrot(vec4(sin(theta)*axis,cos(theta)));
  vec3 p = vec3(0,0,-6);
  vec3 q = normalize(vec3(xy,0)-p);
  vec2 mouse = vec2(0.0);//float(mouse*resolution.xy.x > 0.0)*TWOPI*(mouse*resolution.xy.xy-resolution.xy)/resolution.xy;
  // y coord determines rotation about x axis etc.
  m = m*yrotate(mouse.x)*xrotate(-mouse.y);
  p = m*p; q = m*q;

  // Initialize triangle matrices
  mat3 m1 = zrotate(-0.5*time); // Rotate triangle about centre
  mat3 m1inc = zrotate(TWOPI/float(N));
  mat3 m2 = mat3(1); // Rotate triangle about y-axis
  mat3 m2inc = yrotate(TWOPI/float(N));
  vec3 off = vec3(1,0,0); // Base triangle offset
  vec4 amin = vec4(1e8,0,0,0);
  for (int i = 0; i < N; i++) {
    // Equilateral triangle pointing left.
    vec3 v0 = off + m1*vec3(-1,0,0);
    vec3 v1 = off + m1*vec3(0.5,-0.866,0);
    vec3 v2 = off + m1*vec3(0.5,0.866,0);
    v0 = m2*v0; v1 = m2*v1; v2 = m2*v2;
    m1 = m1inc*m1;
    m2 = m2inc*m2;
    vec4 a = triangle(p,q,v0,v1,v2);
    // Vectorize comparisons,check:
    // 0 <= a,b,c <= 1 and 0 <= k < kmin
    bool hit = all(bvec2(all(greaterThanEqual(a,vec4(0))),
                         all(lessThanEqual(a,vec4(amin.x,1,1,1)))));
    amin -= float(hit)*amin; // Try to avoid rounding error
    amin += float(hit)*a;
  }
  glFragColor = vec4(amin.yzw,1.0); // Use barycentric coords as RGB values
}
