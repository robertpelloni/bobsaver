#version 420

// original https://www.shadertoy.com/view/tdByR3

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

////////////////////////////////////////////////////////////////////////////////
//
// Concentric Spheres
// Matthew Arcus, mla, 2020
//
// Octahedral symmetry again.
//
// Inspired by: https://www.shadertoy.com/view/wd2cWW
//
// Nested spherical disdyakis dodecahedrons (this is actually what they are
// called: https://en.wikipedia.org/wiki/Disdyakis_dodecahedron)
//
////////////////////////////////////////////////////////////////////////////////

int AA = 2; // Set to 1 if too slow

vec3 light = vec3(0,2,1); // Position of light
float eradius = 0.03; // Thickness of an edge
float eyedist = 2.5;  // Eye is at (0,0,eyedist);
float PI = 3.1415927; 

// Raymarching configuration.
int maxsteps = 100;
float precis = 1e-3; 

bool dorotate = true;

// Find the distance to a spherical segment, encapsulated in m.
// m maps p to nearest point in some subspace (ie. a plane).
float ssegment(vec3 p, mat3 m) {
  vec3 p1 = normalize(m*p);
  // And return the 'distance' to the closest point.
  float len = length(p);
  float x = distance(p/len,p1);    // Distance on surface
  float y = len-1.0; // Radial distance
  return max(x,abs(y))-eradius;
}

// Matrix for segment through q and r - take a point p,
// Use q and r as basis vectors for subspace, so first
// take dot products with q and r, then map to coordinates
// in that basis (matrix m), then map back to R3. This is
// then the nearest point to p in the subspace.
// Assumes q and r normalized
mat3 mkmatrix(vec3 q, vec3 r) {
  mat2 m = inverse(mat2(1,dot(q,r),dot(q,r),1));
  return mat2x3(q,r)*m*transpose(mat2x3(q,r));
}

mat3 m0,m1,m2;
vec4 q0,q1,q2;

void init() {
  vec3 A = vec3(1,0,0);
  vec3 B = vec3(0,1,0);
  vec3 C = vec3(0,0,1);
  // The midpoints of the sides, named for opposites
  vec3 A1 = normalize(0.5*(B+C));
  vec3 B1 = normalize(0.5*(C+A));
  vec3 C1 = normalize(0.5*(A+B));
  m0 = mkmatrix(A,B);
  m1 = mkmatrix(A,A1);
  m2 = mkmatrix(C,C1);

  float t = 0.1*time;
  q0 = vec4(sin(t)*normalize(vec3(1,1,0)),cos(t));
  q1 = vec4(sin(t)*normalize(-vec3(1,1,1)),cos(t));
  q2 = vec4(sin(t)*normalize(vec3(0,1,1)),cos(t));
}

float de0(vec3 p, float k) {
  p *= k;
  p = abs(p); // Map to single face - skip this to see single face.
  // Sort the coordinates to map to fundamental region.
  if (p.x < p.y) p.xy = p.yx;
  if (p.y < p.z) p.yz = p.zy;
  if (p.x < p.y) p.xy = p.yx;

  float d = 1e8;
  d = min(d,ssegment(p,m0));
  d = min(d,ssegment(p,m1));
  d = min(d,ssegment(p,m2));
  return d/k;
}

// Quaternion multiplication
vec4 qmul(vec4 p, vec4 q) {
  vec3 P = p.xyz, Q = q.xyz;
  return p.w*q + q.w*p + vec4(cross(P,Q),-dot(P,Q));
}

vec4 qconj(vec4 p) {
  return vec4(-p.xyz,p.w);
}

// Might be better to turn into a matrix.
vec3 qrot(vec3 p, vec4 q) {
  vec4 r = qmul(qconj(q),qmul(vec4(p,0),q));
  return r.xyz;
}

float de(vec3 p) {
  float d = 1e8;
  float k = 1.2;
  d = min(d,de0(qrot(p,q0),k));
  d = min(d,de0(qrot(p,q1),1.0));
  d = min(d,de0(qrot(p,q2),1.0/k));
  return d;
}

// Get the normal of the surface at point p.
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
  //if (mouse*resolution.xy.x > 0.0) {
  //  // Full range of rotation across the screen.
  //  float phi = (2.0*mouse*resolution.xy.x-resolution.x)/resolution.x*PI;
  //  float theta = (2.0*mouse*resolution.xy.y-resolution.y)/resolution.y*PI;
  //  p.yz = rotate(p.yz,theta);
  //  p.zx = rotate(p.zx,-phi);
  //}
  // autorotation
  if (dorotate) {
    p.yz = rotate(p.yz,-time*0.125);
    p.zx = rotate(p.zx,time*0.1);
  }
  return p;
}

vec3 getbasecolor(int type) {
  return vec3(0.75,1,0.75);
}

vec3 getbackground(vec3 r) {
  return r; // Colourful fun
  return vec3(0,0,0.1); // The more sober option.
}

float maxdist = 10.0;
float march(vec3 q, vec3 r) {
  float t = 0.0;
  for (int i = 0; i < maxsteps; i++) {
    vec3 p = q+t*r;
    float d = de(p);
    if (abs(d) < precis) return t; // Close enough to the surface.
    t += d;
    if (t > maxdist) break;
  }
  return -1.0;
}

vec3 raycolor(vec3 q, vec3 r) {
  float t = march(q,r);
  if (t < 0.0) return getbackground(r);
  // Get the surface point that has been hit,
  vec3 p = q+t*r;
  // and the normal at that point.
  vec3 normal = getnormal(p);
  if (dot(normal,r) > 0.0) normal = vec3(0);
  
  // Apply lighting. This is a basic "Lambertian" model.
  vec3 lightdir = normalize(light-p);
  vec3 color = getbasecolor(0);
  float ambient = 0.3;
  float diffuse = 0.7*clamp(dot(normal,lightdir),0.0,1.0);
  color *= ambient+ diffuse;
  color = mix(color,getbackground(r),t/maxdist); // Fog
  return color;
}

void main(void) {
  init();
  maxdist = eyedist + 1.0;
  vec3 eye = vec3(0,0,eyedist);
  eye = transformframe(eye);
  light = transformframe(-light);
  vec3 col = vec3(0);
  for (int i = 0; i < AA; i++) {
    for (int j = 0; j < AA; j++) {
      vec2 z = (2.0*(gl_FragCoord.xy+vec2(i,j)/float(AA))-resolution.xy)/resolution.y;
      vec3 ray = vec3(z,-2);
      ray = transformframe(ray);
      ray = normalize(ray);
      col += raycolor(eye,ray);
    }
  }
  col /= float(AA*AA);
  col = pow(col,vec3(0.4545)); // Gamma
  glFragColor = vec4(col,1);
}
