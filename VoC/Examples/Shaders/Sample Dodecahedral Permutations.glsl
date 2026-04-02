#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/Wt3cDH

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

////////////////////////////////////////////////////////////////////////////////
//
// Dodecahedral Permutations, Matthew Arcus, mla, 2020
// The alternating group A5 as rotations of a dodecahedron.
// 
// The group A5 (the group of even permutations of five objects) has
// 60 elements, there are 60 rotations of a dodecahedron & in fact
// the two groups are isomorphic.
//
// The isomorphism can be constructed as follows: color the
// dodecahedron vertices as for the compound of five tetrahedra;
// there is then one diagonal for each color pair, and the end
// vertices of each diagonal are each adjacent to three vertices in
// the three remaining colours, so to select permutation
// c0,c1,c2,c3,c4, find diagonal c0-c4, rotate so c0 is 'uppermost',
// then rotate about diagonal to put c1,c2,c3 in correct positions.
//
// Here the dodecahedron vertices are stereographically projected to
// the plane, then rotated to form the sixty A5 permutations with the
// colors, in order BRGBY, of the central vertex, the three vertices
// around the centre, clockwise from top, and the outermost vertex.
// 
////////////////////////////////////////////////////////////////////////////////

// Dodecahedron vertices, aligned with z-axis.
// vertex[i] = -vertex[(i+10)%20]
const int N = 20; // Number of vertices
vec3 vertex[N] = vec3[]
  (vec3(0,0,1),

   vec3(0,0.6667,0.7453),
   vec3(0.5773,-0.3333,0.7453),
   vec3(-0.5773,-0.3333,0.7453),

   vec3(-0.5773,0.7453,0.3333),
   vec3(-0.9342,0.1274,0.3333),
   vec3(-0.3568,-0.8727,0.3333),
   vec3(0.3568,-0.8727,0.3333),
   vec3(0.9342,0.1273,0.3333),
   vec3(0.5773,0.7453,0.3333),

   vec3(0,0,-1),

   vec3(0,-0.6667,-0.7453),
   vec3(-0.5773,0.3333,-0.7453),
   vec3(0.5773,0.3333,-0.7453),

   vec3(0.5773,-0.7453,-0.3333),
   vec3(0.9342,-0.1274,-0.3333),
   vec3(0.3568,0.8727,-0.3333),

   vec3(-0.3568,0.8727,-0.3333),
   vec3(-0.9342,-0.1273,-0.3333),
   vec3(-0.5773,-0.7453,-0.3333));

// Compound of five tetrahedra colouring.
int colorindex[N] = int[] (0,1,2,3,4,2,4,1,4,3, 4,2,3,1,3,0,2,0,1,0);

vec3 color[6] = vec3[](vec3(0),vec3(1,0,0),vec3(0,1,0),
                       vec3(0,0,1),vec3(1,1,0),vec3(0.9));

// Quaternions

// R3 rotation of p with quaternion q
vec3 qrot(vec3 p, vec4 q) {
  return p + 2.0*cross(q.xyz,cross(q.xyz,p)+q.w*p);
}

vec4 qpow (vec4 q, float t) {
  // Maybe use an approximation for small q.xyz
  if (q.xyz == vec3(0)) return vec4(vec3(0),pow(q.w,t));
  float r = length(q);
  float phi = acos(q.w/r);
  vec3 n = normalize(q.xyz);
  return pow(r,t)*vec4(sin(t*phi)*n,cos(t*phi));
}

// For normalized q
vec4 qpow1 (vec4 q, float t) {
  if (q.xyz == vec3(0)) return vec4(0,0,0,1);
  float phi = acos(q.w);
  vec3 n = normalize(q.xyz);
  return vec4(sin(t*phi)*n,cos(t*phi));
}

vec4 qmul(vec4 p, vec4 q) {
  vec3 P = p.xyz, Q = q.xyz;
  return vec4(p.w*Q+q.w*P+cross(P,Q),p.w*q.w-dot(P,Q));
}

vec4 qconj(vec4 p) {
  return vec4(-p.xyz,p.w);
}

vec4 qinv(vec4 p) {
  return qconj(p)/dot(p,p);
}

vec4 qdiv(vec4 p, vec4 q) {
  return qmul(p,qinv(q));
}

vec4 qabs(vec4 p) {
  // Convert to quaternion with q.w >= 0
  return p.w >= 0.0 ? p : -p;
}

// slerp: spherical interpolation between q0 and q1
// This is basically (q1/q0)^t * q0
// Be careful with operation order here.
// Assumes q0,q1 normalized so q1/q0 = q1*q0'
// The qabs ensures we go the short way round.
vec4 slerp(vec4 q0, vec4 q1, float t) {
  return qmul(qpow1(qabs(qmul(q1,qconj(q0))),t),q0);
}

#define DEFSWAP(T) \
void swap(inout T p, inout T q) { T t = p; p = q; q = t; }

DEFSWAP(int)
DEFSWAP(vec3)

// Find rotation that maps p,q onto r,s
// Reflect p to r, q to q', then q' to s
vec4 getrotation(vec3 p, vec3 q, vec3 r, vec3 s) {
  if (p == r) {
    if (q == s) return vec4(0,0,0,1); // Nothing to do
    swap(p,q); swap(r,s);
  }
  vec3 n1 = r-p;
  vec4 q1 = vec4(n1,0); // Reflect p to r
  q = q-2.0*dot(n1,q)/dot(n1,n1)*n1;
  vec3 n2 = distance(q,s) < 0.01 ? cross(r,q+s) : s-q;
  vec4 q2 = vec4(n2,0);
  vec4 t = qmul(q2,q1);
  return normalize(t);
}

// Given three elements of a permutation, c0, c1, c2, find
// v0 with color(v0) = c0 and color(-v0) = c2, then find
// v1 adjacent to v0 with color(v1) = c1. This is always
// possible with the "5 tetrahedron" colouring.
ivec2 getvertices(ivec3 p) {
  int i,j;
  for (i = 0; i < N; i++) {
    // The opposite vertex is 10 places on
    if (colorindex[i] == p[0] && colorindex[(i+N/2)%N] == p[2]) break;
  }
  for (j = 0; j < N; j++) {
    // Find unique closest vertex with correct color
    if (colorindex[j] == p[1] && distance(vertex[i],vertex[j]) < 1.0) break;
  }
  return ivec2(i,j);
}

vec3 invert(vec3 p, vec3 centre, float r2) {
  p -= centre;
  p *= r2/dot(p,p);
  p += centre;
  return p;
}

vec3 istereo(vec2 p2) {
  // Inverse stereographic projection by inversion
  vec3 p = vec3(p2,0);
  vec3 centre = vec3(0,0,-1);
  float r2 = 2.0;
  p = invert(p,centre,r2);
  return p;
}

// For k = 2n, find the nth even permutation
// For k = 2n+1, find the nth odd permutation
// Return first, second and last elements of permutation
// Given the parity, the other two elements are determined.
ivec3 getperm(int k) {
  const int N = 5;
  int a[N] = int[](0,1,2,3,4);
  int p = 24;
  int inversions = 0;
  for (int i = N-1; i > 1; i--) {
    int k1 = k/p;
    inversions += i-k1;
    k = k%p;
    int tmp = a[k1];
    for (int j = k1; j < i; j++) {
      a[j] = a[j+1];
    }
    a[i] = tmp;
    p /= i;
  }
  if (inversions%2 != k%2) swap(a[0],a[1]);
  // Perms are in lexicographic reverse order
  return ivec3(a[4],a[3],a[0]);
}

void main(void) {
  vec2 p2 = (2.0*gl_FragCoord.xy-resolution.xy)/resolution.y;
  p2 *= 5.0;
  vec3 p = istereo(p2);
  float cycle = 4.0;
  float transition = 2.0;
  int n = int(time/cycle);
  ivec3 perm0 = getperm(n%60*2);
  ivec3 perm1 = getperm((n+1)%60*2);
  ivec2 vv0 = getvertices(perm0);
  ivec2 vv1 = getvertices(perm1);
  vec4 q0 = getrotation(vertex[0],vertex[1],vertex[vv0[0]],vertex[vv0[1]]);
  vec4 q1 = getrotation(vertex[0],vertex[1],vertex[vv1[0]],vertex[vv1[1]]);
  float t = smoothstep(1.0,2.0,transition*fract(time/cycle));
  vec4 q = slerp(q0,q1,t);
  q = normalize(q); // Just in case
  p = qrot(p,q);
  vec3 col = color[5];
  float dwidth = 0.3;
  for (int i = 0; i < N; i++) {
    float d = acos(clamp(dot(p,vertex[i]),-1.0,1.0));
    col = mix(color[colorindex[i]],col,smoothstep(0.0,max(0.01,fwidth(d)),d-dwidth));
  }
  glFragColor = vec4(col,1);
}
