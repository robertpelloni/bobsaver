#version 420

// original https://www.shadertoy.com/view/7tlGDr

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

////////////////////////////////////////////////////////////////////////////////
//
// Drawing an ellipse as an affine transformation of a circle. mla, 2021
//
// Mouse changes transformation
//
// The inner ellipse is inscribed in the yellow triangle (and passes through
// the midpoints of its sides, making it Steiner's inellipse) and the triangle
// is inscribed in the outer ellipse, which is just double the inner. The
// the sides of the blue parallelogram are also tangent at their midpoints and
// the cross lines in the parallelogram are conjugate diameters of the ellipse.
//
// The whole configuration is just an affine transformation of a circle in a
// square and an equilateral triangle.

// 'x' to see untransformed configuration.
// 'h' for extra hyperbolae
// 'a' for a different regular transformation
//
////////////////////////////////////////////////////////////////////////////////

float lwidth1 = 0.02;
float lwidth2 = 0.04;

const float PI = 3.1415927;

vec3 colors[] =
  vec3[](vec3(0.996078,0.152941,0.0705882),
         vec3(0.988235,0.376471,0.0392157),
         vec3(0.984314,0.6,0.00784314),
         vec3(0.988235,0.8,0.101961),
         vec3(0.996078,0.996078,0.2),
         vec3(0.698039,0.843137,0.196078),
         vec3(0.4,0.690196,0.196078),
         vec3(0.203922,0.486275,0.596078),
         vec3(0.00784314,0.278431,0.996078),
         vec3(0.266667,0.141176,0.839216),
         vec3(0.52549,0.00392157,0.686275),
         vec3(0.760784,0.0784314,0.376471),
         vec3(0.0705882,0.152941,0.996078));

#define RED (colors[0])
#define REDORANGE (colors[1])
#define ORANGE (colors[2])
#define YELLOWORANGE (colors[3])
#define YELLOW (colors[4])
#define YELLOWGREEN (colors[5])
#define GREEN (colors[6])
#define BLUEGREEN (colors[7])
#define BLUE (colors[8])
#define BLUEPURPLE (colors[9])
#define PURPLE (colors[10])
#define REDPURPLE (colors[10])

#define DARK(c) (0.5*(c))
#define LIGHT(c) (0.5+0.5*(c))

const int CHAR_A = 65;
const int CHAR_H = 72;
const int CHAR_X = 88;
const int CHAR_Y = 89;
const int CHAR_Z = 90;

// Macros for use in "common" blocks.
#define key(code) (texelFetch(iChannel3, ivec2((code),2),0).x != 0.0)

float segment(vec2 p, vec2 a, vec2 b) {
  p -= a;
  b -= a;
  float h = clamp(dot(p,b)/dot(b,b), 0.0, 1.0);
  return length(p-b*h);
}

float line(vec2 p, vec2 a, vec2 b) {
  p -= a;
  b -= a;
  float h = dot(p,b)/dot(b,b);
  return length(p-b*h);
}

vec3 doline(vec3 col, vec3 linecol, float d) {
  return mix (linecol, col, mix(0.1,1.0,smoothstep(lwidth1,lwidth2,d)));
}

vec3 diagram(const vec2 p, const vec2 mouse) {
  // Main transformation matrix
  mat2 X = mat2(1,0,0.5,1);
  // Set from mouse
  X = mat2(0.5,mouse.y,mouse.x,0.5);
  //if (key(CHAR_X)) X = mat2(1,0,1e-5,1); // (Almost) untransformed
  // Add an extra rotation - this leaves ellipse invariant
  float t = 0.2*PI*time;
  {
    mat2 A = mat2(cos(t),sin(t),-sin(t),cos(t));
    //if (key(CHAR_A)) A = mat2(tan(t),0,0,1.0/tan(t));
    X *= A;
  }
  mat2 Xinv = inverse(X);
  
  // Equilateral triangle
  vec2 A = X*vec2(0,2);
  vec2 B = X*vec2(-sqrt(3.0),-1);
  vec2 C = X*vec2(+sqrt(3.0),-1);
  // Midpoints of sides
  vec2 AB = 0.5*(A+B);
  vec2 BC = 0.5*(B+C);
  vec2 CA = 0.5*(C+A);
  // Square corners
  vec2 F = X*vec2(1,1);
  vec2 G = X*vec2(1,-1);

  // Compute vertices & foci of ellipse
  // See: https://en.wikipedia.org/wiki/Ellipse#General_ellipse_2
  vec2 f1 = X*vec2(1,0);
  vec2 f2 = X*vec2(0,1);
  // Ellipse is p = cos(t)*f1 + sin(t)*f2
  // Tangent at p = -sin(t)*f1 + cos(t)*f2
  // So tangent is perpendicular to p when:
  // (cos(t)*f1 + sin(t)*f2).(-sin(t)*f1 + cos(t)*f2) = 0
  float t0 = 0.5*atan(2.0*dot(f1,f2)/(dot(f1,f1)-dot(f2,f2)));

  // The four vertices are ±v0, ±v1
  vec2 v0 = f1*cos(t0)+f2*sin(t0);
  vec2 v1 = f1*cos(t0+0.5*PI)+f2*sin(t0+0.5*PI);

  // Calculate focus from axes
  float a2 = 0.25*dot(v0,v0);
  float b2 = 0.25*dot(v1,v1);
  float c2 = a2-b2;
  // Which foci are real?
  vec2 focus = c2 >= 0.0 ? v0*sqrt(c2/a2) : v1*sqrt(-c2/b2);

  // Do the drawing
  float var = 0.5;//+texture(iChannel0,0.25*p).y;
  lwidth1 *= var;
  lwidth2 *= var;
  
  vec3 col = vec3(1,1,0.8);
  float d;

  // Axes of ellipse
  d = 1e8;
  d = min(d,abs(segment(p,v0,-v0)));
  d = min(d,abs(segment(p,v1,-v1)));
  col = doline(col,RED,d);

  d = 1e8;
  d = min(d,abs(segment(p,A,B)));
  d = min(d,abs(segment(p,B,C)));
  d = min(d,abs(segment(p,C,A)));
  //d = min(d,abs(segment(p,A,BC)));
  //d = min(d,abs(segment(p,B,CA)));
  //d = min(d,abs(segment(p,C,AB)));
  col = doline(col,YELLOW,d);

  // The square
  d = 1e8;
  d = min(d,abs(segment(p,F,G)));
  d = min(d,abs(segment(p,F,-G)));
  d = min(d,abs(segment(p,-F,G)));
  d = min(d,abs(segment(p,-F,-G)));

  //d = min(d,abs(segment(p,F,-F)));
  //d = min(d,abs(segment(p,G,-G)));
  d = min(d,abs(line(p,X*vec2(0,-1),X*vec2(0,1))));
  d = min(d,abs(line(p,X*vec2(-1,0),X*vec2(1,0))));
  col = doline(col,BLUE,d);

  d = 1e8;
  d = min(d,abs(segment(p,focus,BC)));
  d = min(d,abs(segment(p,-focus,BC)));
  col = doline(col,vec3(0.1),d);

  // Implicit function is f(inverse(X)*p) where f is circle function
  // Gradient is transpose(X)*f'(inverse(X)*p)
  vec2 p1 = Xinv*p;
  // Use circle implicit function, but use transpose transform to adjust gradient.
  // Implicit function is x^2+y^2 = 1, so gradient is (2x,2y)
  float d2 = dot(p1,p1);
  d = abs(d2-1.0);
  d = min(d,abs(d2-4.0)); // Circumellipse
  vec2 grad = 2.0*p1;
  grad *= Xinv; // Postmultiply for transpose
  d /= length(grad);
  col = doline(col,RED,d);
  //if (key(CHAR_H)) {
    // Conjugate hyperbolae, tangent to ellipse.
  //  d = min(abs(p1.x*p1.y-0.5),abs(-p1.x*p1.y-0.5));
  //  d /= length(p1.yx*Xinv);
  //  col = doline(col,GREEN,d);
  //}
  
  d = length(p);
  d = min(d,distance(p,focus));
  d = min(d,distance(p,-focus));
#if 0
  d = min(d,distance(p,v0));
  d = min(d,distance(p,-v0));
  d = min(d,distance(p,v1));
  d = min(d,distance(p,-v1));
#endif
  d = min(d,distance(p,A));
  d = min(d,distance(p,B));
  d = min(d,distance(p,C));
  //d = min(d,distance(p,AB));
  //d = min(d,distance(p,BC));
  //d = min(d,distance(p,CA));
  d = min(d,distance(p,X*vec2(1,0)));
  d = min(d,distance(p,X*vec2(-1,0)));
  d = min(d,distance(p,X*vec2(0,1)));
  d = min(d,distance(p,X*vec2(0,-1)));
  col = mix(vec3(0), col, smoothstep(lwidth2,2.0*lwidth2,d));
  col *= 0.5;//+0.5*texture(iChannel0,0.25*p).x;
  return col;
}

void main(void) {
  float scale = 2.0;
  vec2 p = vec2(scale*(2.0*gl_FragCoord.xy-resolution.xy)/resolution.y);
  p *= 1.05;
  vec2 mouse = vec2(scale*(2.0*mouse*resolution.xy.xy-resolution.xy)/resolution.y);
  vec3 col = diagram(p,mouse);
  glFragColor = vec4(pow(col,vec3(0.4545)),1);
}
