#version 420

// original https://www.shadertoy.com/view/lljBWz

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

////////////////////////////////////////////////////////////////////////////////
//
// Projective conics, quadrangles and quadrilaterals
//
// Copyright (c) Matthew Arcus, 2018
// MIT License: https://opensource.org/licenses/MIT
//
// Display a complete quadrangle with its dual quadrilateral.
// Also with a fifth point construct a dual pair of conics, one
// passing through the points of the quadrangle, one tangent
// to the reciprocal line.
//
// Projective conics have a neat 3x3 matrix representation that we
// make heavy use of here.
//
// Controls:
// Drag green point to change conic
// 'b': show base configuration
// 'd': show dual configuration
// '1' and '2': change initial configuration
// 'f': change line & point drawing style
// 'z': zoom in
//
////////////////////////////////////////////////////////////////////////////////

int configuration = 3;
bool invert = false;
bool drawbase = true;
bool drawdual = false;

const float lwidth = 0.03;
const float pwidth = 0.12;
float ledge0 = 0.0, ledge1 = lwidth;
float pedge0 = 0.0, pedge1 = pwidth;
const float scale = 2.5;
float zoom = 1.0;

const float PI =  3.141592654;
float eps = 1e-4;

const vec3 pcolor0 = vec3(1,0,0);
const vec3 pcolor1 = vec3(0,1,0);
const vec3 pcolor2 = vec3(1,1,0);
const vec3 pcolor3 = vec3(0,1,1);
const vec3 lcolor0 = pcolor0;
const vec3 lcolor1 = pcolor1;
const vec3 lcolor2 = pcolor2;
const vec3 ccolor0 = vec3(1,1,1);
const vec3 ccolor1 = vec3(0,0,1);

// Represent a projective conic as a 3x3 matrix:
//
// M = (a,d,e,
//      d,b,f,
//      e,f,c)
//
// is: axx + byy + czz + 2(dxy + exz + fyz) = 0
// calculated as pMp for p = (x,y,z).
//
// We can treat this as a distance field, scaled by the
// (x,y) derivative in order to get correct line widths.

// With this representation, the dual conic is just the inverse;
// if the determinant is zero then there is no dual and the
// conic is degenerate.

// Distance from the conic
float dist(vec3 p, mat3 m) {
  return dot(p,m*p);
}

// The gradient uses the same matrix.
// Don't homegenize the result!
vec3 grad(vec3 p, mat3 m) {
  return m*p*2.0;
}

float conic(vec3 p, mat3 m) {
  float d = dist(p,m);
  vec3 dd = grad(p,m);
  d = abs(d/(p.z*length(dd.xy))); // Normalize for Euclidean distance
  return 1.0-smoothstep(ledge0,ledge1,d);
}

// Find a projective mapping taking p0,p1,p2,p4 to
// triangle of reference and unit point, ie:
// p0 -> (1,0,0), p1 -> (0,1,0), p2 -> (0,0,1), p3 -> (1,1,1)
// No three points collinear.
mat3 rproject(vec3 p0, vec3 p1, vec3 p2, vec3 p3) {
  // Just an inverse for the first three points
  // (the triangle of reference). No inverse if collinear.
  mat3 m = inverse(mat3(p0,p1,p2)); // column major!
  vec3 p3a = m*p3;
  // Then scale each row so the unit point (1,1,1) is correct
  m = transpose(m);
  // zero components here only if not collinear
  m[0] /= p3a[0];
  m[1] /= p3a[1];
  m[2] /= p3a[2];
  m = transpose(m);
  return m;
}

// Construct the conic defined by 5 points.
// Method taken from "Geometry", Brannan, Esplan & Gray, CUP, 2012
mat3 solve(vec3 p0, vec3 p1, vec3 p2, vec3 p3, vec3 p4) {
  // p takes p0,p1,p2,p3 to triangle of reference and unit point
  mat3 p = rproject(p0,p1,p2,p3);
  // Now construct a conic through the images of p0-p4,
  vec3 p4a = p*p4;
  float a = p4a.x, b = p4a.y, c = p4a.z;
  float d = c*(a-b);
  float e = b*(c-a);
  float f = a*(b-c);
  mat3 m = mat3(0,d,e,
                d,0,f,
                e,f,0);
  // And combine the two.
  return transpose(p)*m*p;
}

float point(vec3 p, vec3 q) {
  if (abs(p.z) < eps) return 0.0;
  if (abs(q.z) < eps) return 0.0;
  p /= p.z; q /= q.z; // Normalize
  return 1.0-smoothstep(pedge0,pedge1,distance(p,q));
}

float line(vec3 p, vec3 q) {
  // Just treat as a degenerate conic. Note factor of 2.
  // We could do this more efficiently of course.
  return conic(p,mat3(0,  0,  q.x,
                      0,  0,  q.y,
                      q.x,q.y,2.0*q.z));
}

vec3 join(vec3 p, vec3 q) {
  // Return either intersection of lines p and q
  // or line through points p and q, r = kp + jq
  return cross(p,q);
}

// Screen coords to P2 coords
vec3 map(vec2 p) {
  return vec3(scale*zoom*(2.0*p - resolution.xy) / resolution.y, 1);
}

//-------------------------------------------------
//From https://www.shadertoy.com/view/XtXGRS#
vec2 rotate(in vec2 p, in float t) {
  return p * cos(-t) + vec2(p.y, -p.x) * sin(-t);
}

vec3 transform(vec3 p) {
  p.x -= sin(0.08*time);
  p.xy = rotate(p.xy,0.2*time);
  p.yz = rotate(p.yz,0.1*time);
  return p;
}

vec3 cmix(vec3 color0, vec3 color1, float level) {
  if (invert) return mix(color0,1.0-color1,level);
  else return mix(color0,color1,level);
}

vec3 mid(vec3 p, vec3 q) {
  return p*q.z + q*p.z;
}

const int CHAR_0 = 48;
const int CHAR_A = 65;
const int CHAR_B = 66;
const int CHAR_C = 67;
const int CHAR_D = 68;
const int CHAR_F = 70;
const int CHAR_Z = 90;
bool keypress(int code) {
#if defined LOCAL || __VERSION__ < 300
  return false;
#else
  return texelFetch(iChannel0, ivec2(code,2),0).x != 0.0;
#endif
}

void main(void) {
  drawbase = !keypress(CHAR_B);
  drawdual = !keypress(CHAR_D);
  if (keypress(CHAR_Z)) zoom = 0.25;
  if (keypress(CHAR_F)) {
      float pixelwidth = 2.0*scale/resolution.y;
      pedge0 = pwidth-pixelwidth;
      //pedge1 = pwidth+pixelwidth;
      ledge0 = lwidth-pixelwidth;
      //ledge1 = lwidth+pixelwidth;
  }    
  configuration = int(keypress(CHAR_0+1)) + 2*int(keypress(CHAR_0+2));
  vec3 p = map(gl_FragCoord.xy);
  vec3 p0,p1,p2,p3,p4; // p4 is the movable point
  if (configuration == 0) {
    p0 = vec3(1,0,0); p1 = vec3(0,1,0);
    p2 = vec3(0,0,1); p3 = vec3(1,1,1);
    p4 = vec3(0.5,-1,1);
  } else if (configuration == 1) {
    p0 = vec3(0,0,1); p1 = vec3(1,0,1);
    p2 = vec3(0,1,1); p3 = vec3(1,1,1);
    p4 = vec3(0.5,-1,1);
  } else if (configuration == 2) {
    p0 = vec3(0,0,1); p1 = vec3(0,1,1);
    p2 = vec3(0.866,-0.5,1); p3 = vec3(-0.866,-0.5,1);
    p4 = vec3(0.5,-1,1);
  } else {
    p0 = vec3(1,0,1);  p1 = vec3(0,1,1);
    p2 = vec3(-1,0,1); p3 = vec3(0,-1,1);
    p4 = vec3(0.5,-1,1);
  }
  p0 = transform(p0); p1 = transform(p1);
  p2 = transform(p2); p3 = transform(p3);
  if (mouse*resolution.xy.x != 0.0) {
    p4 = map(mouse*resolution.xy.xy);
  }
  vec3 p01 = join(p0,p1);
  vec3 p02 = join(p0,p2);
  vec3 p03 = join(p0,p3);
  vec3 p12 = join(p1,p2);
  vec3 p13 = join(p1,p3);
  vec3 p23 = join(p2,p3);

  mat3 M = solve(p0,p1,p2,p3,p4);

  // Don't try to invert if zero or nan determinant
  bool degenerate = abs(determinant(M)) < 1e-10;

  vec3 color = vec3(0);

  if (drawbase) {
    // The diagonal lines of the quadrangle
    color = cmix(color,lcolor2,line(p,p01));
    color = cmix(color,lcolor2,line(p,p02));
    color = cmix(color,lcolor2,line(p,p03));
    color = cmix(color,lcolor2,line(p,p12));
    color = cmix(color,lcolor2,line(p,p13));
    color = cmix(color,lcolor2,line(p,p23));
  }
  
  // The lines of the quadrilateral
  if (drawdual) {
    color = cmix(color,lcolor0,line(p,p0));
    color = cmix(color,lcolor0,line(p,p1));
    color = cmix(color,lcolor0,line(p,p2));
    color = cmix(color,lcolor0,line(p,p3));
    // The moving line
    color = cmix(color,lcolor1,line(p,p4));
  }

  // The conics
  if (drawbase) {
    color = cmix(color,ccolor0,conic(p,M));
  }
  if (!degenerate && drawdual) {
    // Inverse is dual conic.
    color = cmix(color,ccolor1,conic(p,inverse(M)));
  }

  // The points of the quadrangle
  if (drawbase) {
    color = cmix(color,pcolor0,point(p,p0));
    color = cmix(color,pcolor0,point(p,p1));
    color = cmix(color,pcolor0,point(p,p2));
    color = cmix(color,pcolor0,point(p,p3));
  }
  if (drawdual) {
    // The intersection points of the sides of the quadrilateral
    color = cmix(color,pcolor2,point(p,p01));
    color = cmix(color,pcolor2,point(p,p02));
    color = cmix(color,pcolor2,point(p,p03));
    color = cmix(color,pcolor2,point(p,p12));
    color = cmix(color,pcolor2,point(p,p13));
    color = cmix(color,pcolor2,point(p,p23));
  }
  // Alway draw the moving point
  color = cmix(color,pcolor1,point(p,p4));

  if (invert) color = 1.0 - color;
  glFragColor = vec4(pow(1.0*color,vec3(0.4545)),1);
}
