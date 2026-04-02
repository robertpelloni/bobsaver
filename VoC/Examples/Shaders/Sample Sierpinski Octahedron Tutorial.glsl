#version 420

// original https://www.shadertoy.com/view/wdfyDj

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

////////////////////////////////////////////////////////////////////////////////
//
// Sierpinski Octahedron Tutorial
//
// Matthew Arcus, 2020.
//
// Draw a wire frame octahedron, with the first couple of layers of the
// Sierpinski triangulation applied to the sides. In itself, this isn't
// all that exciting, but it leads on nicely to the next step, which
// is to move up a dimension.
//
// I've tried to make this something of a tutorial with more explanation
// of what is going on than usual and I've used a lot of forward
// declarations so the code can be read somewhat top down. I hope some
// people find that useful. I haven't gone into much detail about
// lighting etc. as we aren't doing anything very clever here and the
// basic stuff is well covered elsewhere.
//
////////////////////////////////////////////////////////////////////////////////

// First we must declare some global variables - we don't want to
// overuse these, but they are useful for setting global configuration
// etc. One useful purpose is for simple runtime checks - it's hard
// knowing what is going on in a shader, so some way of reporting
// conditions to the user is very handy.

bool alert = false;
void assert(bool b) {
  if (!b) alert = true;
}
//#define assert(x) // Uncomment this to remove assertions

// Various configurables - their meaning will become clear later.
//#define SPHERICAL // Uncomment to project to sphere
vec3 light = vec3(0,2,1); // Position of light
float eradius = 0.001; // Radius of an edge
float pradius = 0.02; // Radius of a vertex sphere
float eyedist = 2.5; // Eye is at (0,0,eyedist);
float PI = 3.1415927; // A useful constant - don't need more figures than this
int level = 2; // How many Sierpinski subdivisions <= 2 to do.

// Raymarching configuration.
int maxsteps = 50;
float precis = 1e-2; 

bool dorotate = true;

vec3 screencolor(vec2 z);

// The main function called by Shadertoy.
void main(void) {
  // screen coordinate. In fact, Shadertoy always sets the w or a
  // coordinate of the colour to 1, so we will do most of our work
  // with vec3 colours.

  // It's useful for the shader to mainly work with "normalized"
  // dimensions rather than actual pixel dimensions - a common
  // convention is to normalize to [-1,1] vertically and [-a,a]
  // horizontally, where a is the screen aspect ratio (so horizontal
  // and vertical scales are the same). I tend to call this 'z' as we
  // often want to treat it as a complex number, but some might prefer
  // 'uv', or 'p'.

  vec2 z = (2.0*gl_FragCoord.xy-resolution.xy)/resolution.y;

  // The maincolor function declared earlier actually does the work.
  vec3 col = screencolor(z);

  // Check nothing has gone wrong.
  if (alert) col.r = 1.0;

  // Set the final fragment colour.
  glFragColor = vec4(col,1);
}

vec3 raycolor(vec3 q, vec3 r);
vec3 transformframe(vec3);

vec3 screencolor(vec2 z) {
  // z is a normalized screen coordinate, return the colour for that
  // coordinate.

  // We are doing a 3d scene, so we need to set things up with a
  // camera and a "projection screen". There are various ways of doing
  // this, for this shader where the main interest is around the
  // origin, this simple setup will do - imagine a device with a 
  // rectangular grid as in Albrecht Dürer's woodcut:
  // https://www.metmuseum.org/art/collection/search/366555 - the grid
  // is at a fixed position from the eye, and the whole device can be
  // moved around as a unit to view the scene from different
  // positions (for example, by rotating under mouse control).

  // The initial location of the virtual eye or camera.
  vec3 eye = vec3(0,0,eyedist);

  // The direction of a ray from the eye to a point on the virtual
  // screen - the screen goes from -1 to +1 vertically, so we have a
  // vertical viewing angle of 2*atan(0.5) = 53 degrees.
    vec3 ray = vec3(z,-2);

  // Now we follow that ray into the scene and see what generates the
  // light that comes down that ray in the opposite direction.

  // First, apply a transformation to both eye and ray to allow viewing the
  // scene from different directions. Also transform the light, so the
  // effect will be that we are rotating the scene before us.
  eye = transformframe(eye);
  ray = transformframe(ray);
  light = transformframe(light);
  
  // Calculations are easier if the ray has unit length. Do this after
  // rotating as sin and cos can introduce small inaccuracies.
  ray = normalize(ray);

  // Now raycolor will follow the ray from eye and return the colour
  // to display for that ray.
  vec3 col = raycolor(eye,ray);
  col = pow(col,vec3(0.4545)); // Gamma correction - see elsewhere
  return col;
}

float getdistance(vec3 q, vec3 r, out int type);
vec3 getnormal(vec3 p);

vec3 getbasecolor(int type) {
  assert(type >= 0);
  if (type == 0) return vec3(0.75,1,0.75);
  if (type == 1) return vec3(0.2);
  return vec3(1,0,1);
}

vec3 getbackground(vec3 r) {
  //return r; // Colourful fun
  return vec3(0,0,0.1); // The more sober option.
}

vec3 raycolor(vec3 q, vec3 r) {
  // The scene is represented by a surface, We follow the ray and find
  // if it intersects the surface - if so, apply some simple lighting
  // to the colour at the intersection point. 'type' is set to an
  // integer indicating what has been hit.
  int type = -1;
  float t = getdistance(q,r,type);

  // getdistance returns -ve for no intersection, so return background
  // colour for that direction.
  if (t < 0.0) return getbackground(r);

  // Get the surface point that has been hit,
  vec3 p = q+t*r;

  // and the normal at that point.
  vec3 normal = getnormal(p);

  // Apply lighting. This is a basic "Lambertian" model.
  vec3 lightdir = normalize(light-p);
  vec3 color = getbasecolor(type);
  float ambient = 0.3;
  float diffuse = 0.7*clamp(dot(normal,lightdir),0.0,1.0);
  color *= ambient+ diffuse;
  return color;
}

// We have got to raymarching at last. Much has been written
// elsewhere on how this works, which I won't repeat here, the general
// idea is that de(p) gives an estimate of the minimum distance to
// the surface, so we can safely move that far along the ray without
// hitting the surface, and then repeat the procedure. Our scene is
// just spheres and cylinders, with nothing fancy going on so
// something very simple will do here.

// Note that the DE function also returns the type of object hit
// (basically, what colour it should be) - for a complex DE function
// it might be more efficient to have separate functions, one that
// just returns the distance, and one that just returns the type that
// can be called separately at the end to determine the colour (we
// could write it as a single function though, used in two places and
// rely on the code optimizer to inline and remove any useless
// calculations from each use).

float de(vec3 p, out int type); // The distance estimator

float getdistance(vec3 q, vec3 r, out int type) {
  // Octahedron is mostly radius <= 1 and eyedist is distance of eye from
  // origin, so this should cover the entire scene.
  float maxdist = eyedist + 2.0;
  float t = 0.0;
  for (int i = 0; i < maxsteps; i++) {
    //assert(i < 20); // Assertions are useful for seeing what's going on.
    vec3 p = q+t*r;
    float d = de(p,type);
    if (abs(d) < precis) return t; // Close enough to the surface.
    t += d;
    if (t > maxdist) break;
  }
  return -1.0;
}

float segment(vec3 p, vec3 q, vec3 r);
float dist(vec3 p, vec3 q);

// The de function for our octahedron. The octahedron, with vertices
// at (1,0,0),(-1,0,0),(0,1,0),(0,-1,0),(0,0,1),(0,0,-1) has mirror
// symmetries in the 3 planes, x=0, y=0, z=0, so de(p) = de(abs(p))
// and setting p = abs(p) in fact maps all faces of the octahedron to
// the one at (1,0,0),(0,1,0),(0,0,1) (or, maps p to p' where the
// distance from p to the octahedron is the same as the distance from
// p' to that single face).
//
// Additionally, there are symmetries in the diagonal planes x=y,
// etc. so de(p) = de(p.yxz), ie. we can swap any pairs of
// coordinates, so we can map p -> p1 with p1.x >= p1.y >= p1.z and
// the effect of this is to map the entire triangular face into a
// small right angled triangle at (0,0,0),(1,0,0) and 0.5*(1,1,0),
// (the 'fundamental region' for the set of symmetries).
//
// Note that points on the face all have coordinates (a,b,c) with
// a+b+c = 1 and 0 <= a,b,c <= 1. (In fact, the actual coordinates of
// the points in the face are the same as their barycentric or
// trilinear coordinates, making calculations very easy).

// So, to actually draw something: we have a triangle ABC, though we
// are mainly working in a small sector around A. From the triangle
// ABC, the only vertex in the sector is A, the only line is AB, so if
// we draw just these, we see a complete octahedron, the rest is
// filled in by our mirror symmetries.

// For the Sierpinski construction, we want to draw the inner
// triangle, which goes between the midpoints of the sides. Again,
// because we are working in a small sector around A, we just need to
// draw the midpoint of AB and part of the line from there to the
// midpoint of BC, or, as in the code, set A1,B1,C1 to be the vertices
// of the new "corner triangle" around A, so A1 = A, B1 = midpoint of
// AB, C1 = midpoint of AC, and then we just need to draw point B1 and
// the line from B1 to C1.
//
// Finally, we want to draw the centre triangle of that smaller corner
// triangle, so find the midpoints of its sides (AB1 etc.) and draw
// lines between them - again, we just need points AB1 and BC1 and
// the lines from AB1 to CA1 and from AB1 to BC1. It's easy to see
// what is needed by commenting out the 'p = abs(p)' line so just one
// triangular face is displayed (and drawing a picture on a piece of
// paper always helps).

float de(vec3 p, out int type) {
  p = abs(p); // Map to single face - skip this to see single face.
  // Sort the coordinates to map to fundamental region.
  if (p.x < p.y) p.xy = p.yx;
  if (p.y < p.z) p.yz = p.zy;
  if (p.x < p.y) p.xy = p.yx;
  // Check we are sorted.
  assert(p.x >= p.y);
  assert(p.y >= p.z);
  // 3 corners of the original triangle.
  vec3 A = vec3(1,0,0);
  vec3 B = vec3(0,1,0);
  vec3 C = vec3(0,0,1);
  // The 3 corners of the smaller corner triangle.
  vec3 A1 = A;
  vec3 B1 = 0.5*(A+B);
  vec3 C1 = 0.5*(A+C);
  // Midpoints of the sides of the smaller triangle.
  vec3 AB1 = 0.5*(A1+B1);
  vec3 BC1 = 0.5*(B1+C1);
  vec3 CA1 = 0.5*(C1+A1);

  // Some points are outside our fundamental region, but
  // the line segments are going in the right direction.
  float d = 1e8, d0 = d;
  for(;;) {
    d = min(d,segment(p,A,B)-eradius);
    if (level == 0) break;
    d = min(d,segment(p,B1,C1)-eradius);
    if (level == 1) break;
    d = min(d,segment(p,AB1,CA1)-eradius);
    d = min(d,segment(p,AB1,BC1)-eradius);
    break;
  }
  if (d < d0) type = 0; d0 = d;

  for(;;) {
    d = min(d,dist(p,A)-pradius);
    if (level == 0) break;
    d = min(d,dist(p,B1)-pradius);
    if (level == 1) break;
    d = min(d,dist(p,AB1)-pradius);
    d = min(d,dist(p,BC1)-pradius);
    break;
  }
  if (d < d0) type = 1; d0 = d;

  return d;
}

// We need to define just how to measure distances to the scene.
#if defined SPHERICAL
// Project the scene points (ie. q and r here) onto the unit sphere
// before measuring distances.
float dist(vec3 p, vec3 q) {
  return distance(p,normalize(q));
}

// For segment, also project p onto sphere, then find the closest
// point to the segment on the sphere, and take the Euclidean distance
// to that point.
float segment(vec3 p, vec3 q, vec3 r) {
  vec3 p1 = normalize(p);
  q = normalize(q);
  r = normalize(r);
  // Map p to the plane defined by q and r:
  // p = aq + br + x, where q.x = r.x = 0 so:
  // p.q = aq.q + br.q and:
  // p.r = aq.r + br.r
  // Solve by inverting a 2x2 matrix.
  mat2 m = inverse(mat2(dot(q,q),dot(q,r),dot(q,r),dot(r,r)));
  vec2 ab = m*vec2(dot(p1,q),dot(p1,r));
  // p1 is in plane of q,r, on hypersphere
  p1 = normalize(ab[0]*q + ab[1]*r);
  // Check if in segment, if angle p1,q > angle q,r, then
  // p1 is off the r end, etc:
  float t = dot(q,r);
  if (dot(p1,q) < t) p1 = r;
  else if (dot(p1,r) < t) p1 = q;
  // And return the distance to the closest point.
  return distance(p,p1);
}
#else
// The usual Euclidean distances:
float dist(vec3 p, vec3 q) {
  return distance(p,q);
}

// Find the distance from p to the segment between q and r.
float segment(vec3 p, vec3 q, vec3 r) {
  // Rebase to origin at q  
  p -= q; r -= q;
  // t*r is orthogonal projection of p onto qr.
  float t = clamp(dot(p,r)/dot(r,r), 0.0, 1.0);
  return distance(p,t*r);
}
#endif

// Finish off with some fairly standard utility functions.

// Get the normal of the surface at point p.
float de(vec3 p) { int type; return de(p,type); }
vec3 getnormal(vec3 p) {
  float eps = 0.001;
  vec2 e = vec2(eps,0);
  return normalize(vec3(de(p + e.xyy) - de(p - e.xyy),
                        de(p + e.yxy) - de(p - e.yxy),
                        de(p + e.yyx) - de(p - e.yyx)));
}

// Rotate vector p by angle t.
vec2 rotate(vec2 p, float t) {
  return cos(t)*p + sin(t)*vec2(-p.y,p.x);
}

// Rotate according to mouse position
vec3 transformframe(vec3 p) {
  // autorotation
  if (dorotate) {
    p.yz = rotate(p.yz,-time*0.125);
    p.zx = rotate(p.zx,time*0.1);
  }
  return p;
}
