#version 420

// original https://www.shadertoy.com/view/WdsBzS

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

////////////////////////////////////////////////////////////////////////////////
//
// Loopless Conic Envelopes
// Matthew Arcus, mla, 2020
//
// A demo of drawing envelopes of conic curves looplessly
//
////////////////////////////////////////////////////////////////////////////////

const float PI = 3.1415927;
int AA = 2;

// With homogeneous coordinates, (x,y,z) corresponds to the Euclidean
// point (x/z,y/z), so (kx,ky,kz) represents the same point for any
// k. z can be regarded as a "scaling" parameter, so (x,y,0)
// represents a point infinitely far away (like a vanishing point in a
// perspective drawing it can be regarded as a pure direction), in
// fact, a point on the "line at infinity", equation z = 0.
//
// Lines also are represented as l = vec3(a,b,c) with point p being on line l
// just when dot(l,p) = 0, again, multiples of (a,b,c) represent the
// same line, so (a,b,c) represents the Euclidean line ax+by+c = 0.
//
// If l1 and l2 are lines, join(l1,l2) is their intersection, and if p1,p2 are
// points, then join(p1,p2) is the line between them. join is just
// cross product:

vec3 join(vec3 p, vec3 q) {
  return cross(p,q);
}

// Actually drawing a point or a line or a conic involves Euclidean notions of
// scale and distance, so we need to convert to Euclidean points (or do something
// equivalent), so to draw a point, we need the distance between the pixel point
// and the point being drawn (we can look on this as mapping both points to the
// z=1 plane and measuring distances there):

float point(vec3 p, vec3 q) {
  return distance(p.xy/p.z,q.xy/q.z);
}

// We can short circuit the calculations a little:
// If p = (x,y,z) and l = (a,b,c) then (x/z,y/z) is the Euclidean point
// and if |(a,b)| = 1, then the distance to the line is ax+by+c:
float line(vec3 p, vec3 l) {
  return abs(dot(p,l)/(p.z*length(l.xy)));
}

// For a line given by two points, just join the points into a line:
float line(vec3 p, vec3 q, vec3 r) {
  return line(p,join(q,r));
}

// A conic curve is represented by a 3x3 symmetric matrix A and p is on the
// conic just when dot(p,A*p) = dot(p*A,p) = 0. Lines tangent to the conic then
// satisfy dot(l,inverse(A)*l) = dot(l*inverse(A),l) = 0 (points and lines
// are dual).
//
// For simple conics where the matrix is diagonal, we can just use a
// a vector to represent the conic, the code is much the same:
//
// To turn the conic equation into a distance function, we need to
// divide by the magnitude of the gradient, and the gradient at p is
// just 2.0*A*p (analogous to dx^2/dx = 2x):
float conic(vec3 p, mat3 A) {
  float s = dot(p,A*p);
  vec3 ds = 2.0*A*p; // Gradient
  return abs(s/(p.z*length(ds.xy))); // Normalize for Euclidean distance
}

// Note, this is solving at^2 + 2bt + c = 0, so the discriminant is
// b^2 - ac, not b^2 - 4ac.
bool quadratic(float a, float b, float c, out float t1, out float t2) {
  // Assumes we have checked for a == 0 or c == 0
  float disc = b*b-a*c;
  if (disc < 0.0) return false;
  if (b >= 0.0) {
    // Try to avoid rounding error.
    t1 = -b-sqrt(disc);
    t2 = c/t1; t1 /= a;
  } else {
    t2 = -b+sqrt(disc);
    t1 = c/t2; t2 /= a;
  }
  return true;
}

// Find the intersections of the line through p0,p1 with the conic
// defined by A by solving a quadratic equation.
// (or dually, find the tangent lines to A through join of lines p0,p1).
bool intersection(vec3 p0, vec3 p1, mat3 A, out vec3 q0, out vec3 q1) {
  // Any line through p0, p1 is expressible as p0+t*p1,
  // so solve (p0 + t*p1)A((p0 + t*p1) = 0 =>
  // p0*A*p0 + 2*t*p0*A*p1 + t^2*p1*A*p1 = 0
  // We have a quadratic equation:
  float a = dot(p1,A*p1), b = dot(p0,A*p1), c = dot(p0,A*p0);
  // a==0 or c==0 indicate p1 or p0 are actually on conic
  if (a == 0.0) { q0 = q1 = p1; return true; }
  if (c == 0.0) { q0 = q1 = p0; return true; }
  float t1,t2;
  if (!quadratic(a,b,c,t1,t2)) return false;
  q0 = p0 + t1*p1;
  q1 = p0 + t2*p1;
  return true;
  
}

// Find the tangents to a conic from the point z, since this involves
// solving a quadratic equation, there may be no (real) solution, so
// return a boolean to indicate success or otherwise.
bool tangents(vec3 z, mat3 A, out vec3 tan1, out vec3 tan2) {
  // Construct two lines through the point - assuming that z is not at
  // infinity, l1 and l2 will be distinct.
  vec3 l1 = join(z,vec3(1,0,0));
  vec3 l2 = join(z,vec3(0,1,0));
  return intersection(l1,l2,A,tan1,tan2);
}

// crossratio(infinity,p,q,r) = pr/pq
// Assumes p,q,r are collinear.
// -1 if p is midpoint of q and r
// r = p + k(q-p) or r = (1-k)p + kq where k = ratio(p,q,r)
float ratio(vec3 p, vec3 q, vec3 r) {
  p /= p.z; q /= q.z; r /= r.z;
  return dot(r-p,q-p)/dot(q-p,q-p);
}

vec3 getcolor(vec3 z, vec3 pointer) {
  // This is just a plain unit circle, which seems very dull,
  mat3 A = mat3(1,0,0,
                0,1,0,
                0,0,-1);
  // until we rotate it in projective space, when it transitions
  // to ellipse, parabola, hyperbola, then back to parabola,
  // ellipse and circle.
  float t = time;
  mat3 rot = mat3(cos(t),0,sin(t),
                  0,1,0,
                  -sin(t),0,cos(t));
  A = A*rot;

  // We use the inverse of the conic matrix to find lines.
  mat3 Ainv = inverse(A);

  float dconic = conic(z,A); // The distance to the conic

  // Draw the grid of tangent lines to the conic, with lines
  // passing through a baseline:
  vec3 base0 = vec3(-1,0,1);
  vec3 base1 = pointer;
  vec3 baseline = join(base0,base1);
  vec3 tan1, tan2; // Put tangent solutions here
  float ldist = dconic; // This will be minimum distance to a line,
  float pdist = 1e8; // and the minimum distance to a point
  pdist = min(pdist,point(z,2.0*base0-base1)); // Opposite baseline end
  if (tangents(z,Ainv,tan1,tan2)) {
    // Find where the tangents hit the baseline
    vec3 z1 = join(tan1,baseline); 
    vec3 z2 = join(tan2,baseline);
    float k1 = ratio(base0,base1,z1);
    float k2 = ratio(base0,base1,z2); 
    float N = 16.0;
    float t = 0.0;//0.1*time;
    k1 = round(N*(k1+t))/N-t;
    k2 = round(N*(k2+t))/N-t;
    // If the rounded baseline point is in the right range (and the
    // tangent from there is defined) then draw it. Since there will
    // be two tangents from the baseline point, we need to make sure
    // we use the right one - if baseline point and the pixel point
    // are on the same side of the conic, then use the same quadratic
    // root for both, otherwise use different roots. We find which
    // side the points are with the ratio function.
    //
    // If line l is a tangent to the conic A, then the intersection
    // point of the tangent is Ainv*l (and the tangent line at point
    // p is A*p). A is symmetric, so A*p = p*A and Ainv*l = l*Ainv.
    vec3 tan11,tan12;
    if (abs(k1) <= 1.0 && tangents(base0+k1*(base1-base0),Ainv,tan11,tan12)) {
      vec3 t1 = Ainv*tan1; // The point of tan1 on the conic
      if (ratio(t1,z1,z) > 0.0) ldist = min(ldist,line(z,tan11));
      else ldist = min(ldist,line(z,tan12));
    }
    vec3 tan21,tan22;
    if (abs(k2) <= 1.0 && tangents(base0+k2*(base1-base0),Ainv,tan21,tan22)) {
      vec3 t2 = Ainv*tan2; // The point of tan2 on the conic
      if (ratio(t2,z2,z) > 0.0) ldist = min(ldist,line(z,tan22));
      else ldist = min(ldist,line(z,tan21));
    }
  }
  ldist = min(ldist,line(z,baseline));
  pdist = min(pdist,point(z,pointer));
  vec3 col = vec3(0.75+0.25*cos(20.0*dconic),1,1);
  col *= smoothstep(0.01,max(fwidth(z.x),0.02),ldist);
  col *= smoothstep(0.08,0.1,pdist);
  return col;
}

void main(void) {
  vec3 col = vec3(0);
  float scale = 5.0;
  vec2 pointer;
  //if (mouse*resolution.xy.x > 0.0) pointer = (2.0*mouse*resolution.xy.xy-resolution.xy)/resolution.y;
  //else 
  pointer = cos(0.5*time-vec2(0,0.4*PI));
  for (int i = 0; i < AA; i++) {
    for (int j = 0; j < AA; j++) {
      vec2 z = (2.0*(gl_FragCoord.xy+vec2(i,j)/float(AA))-resolution.xy)/resolution.y;
      col += getcolor(vec3(scale*z,1),vec3(scale*pointer,1));
    }
  }
  col /= float(AA*AA);
  col = pow(col,vec3(0.4545));
  glFragColor = vec4(col,1);
}
