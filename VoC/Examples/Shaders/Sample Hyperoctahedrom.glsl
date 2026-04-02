#version 420

// original https://www.shadertoy.com/view/WdfcW2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

////////////////////////////////////////////////////////////////////////////////
//
// Sierpinski Hyperoctahedron Tutorial
//
// Matthew Arcus, 2020.
//
// A follow on to https://www.shadertoy.com/view/wdfyDj, in which we
// do essentially the same thing, the Sierpinski construction on an
// octahedron, but going up to 4-dimensional space (R4) and using
// stereographic projection to get back to 3 dimensions (R3). Now we
// are dealing with a hyperoctahedron or 16-cell, but the calculations
// remain essential the same.
//
// As before, heavily annotated in tutorial style. The main changes
// are in the DE function itself and the raymarcher, which now has a
// more demanding job to do.
//
// No controls, apart from mouse rotation: config changes need recompilation.
//
////////////////////////////////////////////////////////////////////////////////

// As before. Start off with some global variables.

bool dorotate = false;  // Autorotate scene
bool ctranslate = true; // Do Clifford translation

// To see what is going on better, set the 'nofold' option to just see a single
// tetrahedral hyperface. Reduce eyedist eg. to 2.0 to see this better.
bool nofold = false;
float eyedist = 10.0;     // Distance of eye from origin
vec3 light = vec3(0,2,1); // Light direction
int numsteps = 200;       // Maximum raymarching steps
float precis = 1e-3;      // Raymarching precision
float lfactor = 0.8;      // "Lipschitz" factor
float eradius = 0.015;    // Radius of edge
float pradius = 0.05;     // Radius of point

int level = 2;            // Sierpinski division level, 0, 1 or 2

float PI = 3.1415927;

bool alert = false;
void assert(bool b) {
  if (!b) alert = true;
}
//#define assert(x)

// The outer wrapper is the same as the octahedron shader, so let's
// start with the DE function.

// Auxiliary functions
// Spherical distance between points on hypersphere
float sdistance(vec4 p, vec4 q);
// Spherical distance from p to great circle through q and r
float ssegment(vec4 p, vec4 q, vec4 r); 

vec4 stereographic(vec3 p3, inout float scale); // Stereographic projection
vec4 qmul(vec4 p, vec4 q); // Quaternion multiplication

// To draw a 4-dimensional figure, we use stereographic projection to
// map the figure into R3 (or rather, use the inverse to find what
// point in R4 is mapped to the R3 point under consideration).
//
// Inverse stereographic projection uses a projection point of
// (0,0,0,1), (the 'north hyperpole') to project points on the w=0
// hyperplane (ie. the normal embedding of R3 in R4) onto the unit
// hypersphere. We can also represent this as an inversion in a
// sphere, centre (0,0,0,1), radius sqrt(2) and that is how we
// calculate it here.

// The stereographic projection, and inversions generally, are
// conformal, in that at each point the scale factor is the same in
// all directions - this is important for ray marching as it means
// that after applying a conformal map, we just need to multiply the
// DE by the appropriate scale factor to get a coherent DE for the
// mapped surface, with the caveat that the scale factor will vary
// over the course of the ray, but provided it doesn't vary too much,
// we can deal with this by reducing the step size by a small fiddle
// factor, or by ensuring that large steps get clamped to something
// less likely to lead to overshooting the surface. ('Lipschitz
// continuity' is very relevant here).

float de(vec3 p3, out int type) {
  float scale = 1.0;
  vec4 p = stereographic(p3,scale);

  if (ctranslate) {
    // Apply a rotation in R4 with a quaternion.
    // Quaternions represent rotations (and reflections) in R4 just as
    // well as in R3, with p -> qpr, for quaternions q and r
    // representing a general rotation. Here we multiply by a single
    // quaternion, giving a "Clifford translation" which after
    // stereographic projection appears as a screw motion - a rotation
    // combined with a translation along the rotation axis (here the
    // vertical y-axis).
    // https://en.wikipedia.org/wiki/William_Kingdon_Clifford
    float t = 0.1*time;
    // The 'normalize' here shouldn't be necessary, but sin and cos
    // can be relatively inaccurate.
    vec4 Q = normalize(vec4(sin(t)*vec3(0,1,0),cos(t)));
    p = qmul(p,Q);
  }

  // Exactly as with the octahedron, set p = abs(p), reflecting
  // everything into the positive sector and into a single
  // (tetrahedral) hyperface. Then sort the coordinates to
  // take everything into a small sector around vertex A(1,0,0,0).
  if (!nofold) p = abs(p);
  // Sort the coordinates
  if (p.x < p.y) p.xy = p.yx;
  if (p.z < p.w) p.zw = p.wz;
  if (p.x < p.z) p.xz = p.zx;
  if (p.y < p.w) p.yw = p.wy;
  if (p.y < p.z) p.yz = p.zy;
  // Check all is well. On my laptop there is a weird bug where if
  // these assertions are removed, the sort doesn't get done
  // properly.
  assert(p.x >= p.y);
  assert(p.y >= p.z);
  assert(p.z >= p.w);

  // The tetrahedron is on the hyperplane x+y+z+w = 1, but we need to
  // project everything onto the hypersphere, with |p| = 1, so though
  // we do our calculations on the hyperplane, we normalize
  // before drawing anything (we could do this in the drawing
  // functions, but it's more efficient to do it once and for all
  // here).

  // The main tetrahedron, (A,B,C,D). Just a normal R3 equilateral
  // tetrahedron with side length sqrt(2), it just happens to be in
  // R4 rather than R3 (like the equilateral triangle side of the
  // octahedron in the earlier shader).
  vec4 A = vec4(1,0,0,0);
  vec4 B = vec4(0,1,0,0);
  vec4 C = vec4(0,0,1,0);
  vec4 D = vec4(0,0,0,1);
  // The 'corner' tetrahedron, (A1,B1,C1,D1), that we want to
  // subdivide in turn.
  vec4 A1 = A;
  vec4 B1 = 0.5*(A+B);
  vec4 C1 = 0.5*(A+C);
  vec4 D1 = 0.5*(A+D);

  //  It has 6 edges, with 6 midpoints, but we only need these 4.
  vec4 AB1 = 0.5*(A1+B1);
  vec4 AC1 = 0.5*(A1+C1);
  vec4 BC1 = 0.5*(B1+C1);
  vec4 BD1 = 0.5*(B1+D1);

  // Normalize to hypersphere for drawing. I expect the compiler
  // can constant fold these.
  A1 = normalize(A1);
  B1 = normalize(B1);
  C1 = normalize(C1);
  D1 = normalize(D1);

  AB1 = normalize(AB1);
  AC1 = normalize(AC1);
  BC1 = normalize(BC1);
  BD1 = normalize(BD1);

  // Now draw the points and lines, to the desired level.
  float d = 1e8, d0 = d;
  for (;;) { 
    d = min(d,ssegment(p,A,B)-eradius);
    if (level == 0) break;
    d = min(d,ssegment(p,B1,C1)-eradius);
    if (level == 1) break;
    d = min(d,ssegment(p,AB1,BC1)-eradius);
    d = min(d,ssegment(p,AC1,AB1)-eradius);
    d = min(d,ssegment(p,BC1,BD1)-eradius);
    break;
  }
  if (d < d0) type = 0; d0 = d;

  for (;;) { 
    d = min(d,sdistance(p,A)-pradius);
    if (level == 0) break;
    d = min(d,sdistance(p,B1)-pradius);
    if (level == 1) break;
    d = min(d,sdistance(p,AB1)-pradius);
    d = min(d,sdistance(p,BC1)-pradius);
    break;
  }
  if (d < d0) type = 1; d0 = d;

  // Finally return the distance, but taking into account the
  // scaling factor from the stereographic projection.
  return d/scale;
}

// The revised raymarcher - this now has a much harder job to do - the
// surface can now extend out as far as the eye can see and even pass
// through the eye point itself, and the surface itself is more
// complex so we must tread carefully. As mentioned above, its a good
// idea to use a 'Lipschitz' factor to reduce the step size and also
// keep the step below some limit. To avoid many inefficient small
// steps when stepping out to a distant point, the limit should be
// dependent on the distance travelled so far, and the desired
// precision should also be distance dependent for similar reasons.

// Another problem to deal with here is negative steps, which as our
// DE function is signed, will happen and are usually a good thing -
// but if we find ourselves stepping backwards past the eye point,
// then we should give up - this can easily happen if the surface can
// passes through the eye point, for example.

// Of course, all these cautious changes means that we might
// need to do more steps, so increase numsteps accordingly - we can
// still use our assertion to see how many steps are actually being
// taken and find that 50 or fewer usually suffice.

float de(vec3 p) { int t; return de(p,t); }

float march(vec3 q, vec3 r) {
  float t = 0.01; // Total distance so far.
  float maxdist = eyedist + 10.0;
  for (int i = 0; i < numsteps; i++) {
    //assert(i < 50);
    vec3 p = q+t*r;
    float d = de(p);
    if (abs(d) < t*precis) return t;
    d = min(d,max(0.5,0.5*t));
    t += lfactor*d;
    // We can go backwards!
    if (t < 0.0 || t > maxdist) break;
  }
  return -1.0;
}

// Measuring distances on the hypersphere: this is done just like on a R3
// sphere, measuring along a great circle route, so the dot product of
// the two vectors gives the cosine of the angle between them, and the
// spherical distance is just that angle.
float sdistance(vec4 p, vec4 q) {
  // acos gives the correct answer, but the Euclidean distance
  // is a good approximation, particularly up close. The result is
  // visually indistinguishable and acos is expensive (the Euclidean
  // distance is an underestimate of the spherical distance, which is
  // just what we want for raymarching).
  //return acos(clamp(dot(p,q),-1.0,1.0));
  return distance(p,q);
}

// Find the (spherical) distance from p to the line (great circle)
// through q and r. Again, this is almost the same calculation as in
// R3 - find the nearest point on the line to p by projecting p onto
// the qr-plane and normalizing, then after checking the point is in
// bounds, return the spherical distance to that point.
float ssegment(vec4 p, vec4 q, vec4 r) {
  // Map p to the plane defined by q and r (and the origin):
  // p = aq + br + x, where q.x = r.x = 0 so:
  // p.q = aq.q + br.q and:
  // p.r = aq.r + br.r
  // Solve by inverting a 2x2 matrix.
  mat2 m = inverse(mat2(dot(q,q),dot(q,r),dot(q,r),dot(r,r)));
  vec2 ab = m*vec2(dot(p,q),dot(p,r));
  ab = max(ab,0.0); // Clamp to segment
  // p1 in plane of q,r, on hypersphere
  vec4 p1 = normalize(ab[0]*q + ab[1]*r);
  // And return the distance to the closest point.
  return sdistance(p,p1);
}

// Get the normal of the surface at point p.
vec3 getnormal(vec3 p, float t) {
  float eps = 1e-2;
  vec2 e = vec2(eps,0);
  return normalize(vec3(de(p + e.xyy) - de(p - e.xyy),
                        de(p + e.yxy) - de(p - e.yxy),
                        de(p + e.yyx) - de(p - e.yyx)));
}

vec4 invert(vec4 p, vec4 q, float r2, inout float scale) {
  // Invert p in circle, centre q, radius square r2.
  // Return inverted point and multiply scale by scaling factor.
  p -= q;
  float k = r2/dot(p,p);
  p *= k;
  scale *= k;
  p += q;
  return p;
}

vec4 stereographic(vec3 p, inout float scale) {
  return invert(vec4(p,0),vec4(0,0,0,1),2.0,scale);
}

// Rotate vector p by angle t.
vec2 rotate(vec2 p, float t) {
  return cos(t)*p + sin(t)*vec2(-p.y,p.x);
}

// Quaternion multiplication
// (p+P)(q+Q) = pq + pQ + qP + PQ
vec4 qmul(vec4 p, vec4 q) {
  vec3 P = p.xyz, Q = q.xyz;
  return vec4(p.w*Q+q.w*P+cross(P,Q),p.w*q.w-dot(P,Q));
}

vec3 getbackground(vec3 r) {
  //return r; // Colourful fun
  return vec3(0); // The more sober option.
}

vec3 getbasecolor(int type) {
  assert(type >= 0);
  if (type == 0) return vec3(1,1,0.45);
  if (type == 1) return vec3(0.2);
  return vec3(1,0,1);
}

// Rotate according to mouse position
vec3 transformframe(vec3 p) {
  //if (mouse*resolution.xy.x > 0.0) {
    // Full range of rotation across the screen.
    float phi = (2.0*mouse.x*resolution.xy.x-resolution.x)/resolution.x*PI;
    float theta = (2.0*mouse.y*resolution.xy.y-resolution.y)/resolution.y*PI;
    p.yz = rotate(p.yz,theta);
    p.zx = rotate(p.zx,-phi);
  //}
  // autorotation - we always rotate a little as otherwise nothing can
  // be seen (since the z-axis is part of the model).
  float t = 1.0;
  if (dorotate) t += time;
  p.yz = rotate(p.yz,-t*0.125);
  p.zx = rotate(p.zx,-t*0.1);
  return p;
}

// Follow ray from q, direction r.
vec3 raycolor(vec3 q, vec3 r) {
  float t = march(q,r);
  if (t < 0.0) return getbackground(r);
  vec3 p = q+t*r;
  vec3 normal = getnormal(p,t);
  int type;
  de(p,type); // Just to get the object type
  vec3 color = getbasecolor(type);
  float ambient = 0.3;
  vec3 lightdir = normalize(light);
  float diffuse = 0.7*clamp(dot(normal,lightdir),0.0,1.0);
  color *= ambient+ diffuse;
  return color;
}

// Get the colour for a screen point (with normalized coordinates)
vec3 screencolor(vec2 z) {
  vec3 eye = vec3(0,0,eyedist);
  vec3 ray = vec3(z,-2);
  eye = transformframe(eye);
  ray = transformframe(ray);
  light = transformframe(light);
  ray = normalize(ray);
  vec3 col = raycolor(eye,ray);
  col = pow(col,vec3(0.4545)); // Gamma correction - see elsewhere
  return col;
}

// The main function called by Shadertoy
void main(void) {
  vec2 z = (2.0*gl_FragCoord.xy-resolution.xy)/resolution.y;
  vec3 col = screencolor(z);
  if (alert) col.r = 1.0; // Check nothing has gone wrong.
  glFragColor = vec4(col,1);
}
