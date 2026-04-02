#version 420

// original https://www.shadertoy.com/view/dlXGRN

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

////////////////////////////////////////////////////////////////////////
//
// Modular Flow,mla, 2022
//
// Apply a stretch and squeeze transform (x,y)-> (kx,y/k) to a lattice, 
// add just the right skew, and you get a nice looping flow pattern.
// 
// Inspiration:
// https://twitter.com/matthen2/status/1604117218027077634
// https://twitter.com/etiennejcb/status/1604946331411292166 (@Bleuje)
//
// For the maths:
// https://golem.ph.utexas.edu/category/2014/04/the_modular_flow_on_the_space.html
//
////////////////////////////////////////////////////////////////////////

bool alert = false;
int assert(bool b) {
 if (!b) alert = true;
 return 0;
}

// Rotate vector p by angle t.
vec2 rotate(vec2 p, float t) {
  return cos(t)*p + sin(t)*vec2(-p.y,p.x);
}

vec3 h2rgb(float h) {
  vec3 rgb = clamp( abs(mod(h*6.0+vec3(0.0,4.0,2.0),6.0)-3.0)-1.0, 0.0, 1.0 );
  return rgb*rgb*(3.0-2.0*rgb); // cubic smoothing    
}

uint ihash(uint x) {
    x ^= x >> 16;
    x *= 0x7feb352dU;
    x ^= x >> 15;
    x *= 0x846ca68bU;
    x ^= x >> 16;
    return x;
}

float segment(vec2 p, vec2 a, vec2 b) {
  p -= a; b -= a;
  float h = dot(p,b)/dot(b,b);
  h = clamp(h, 0.0, 1.0);
  return length(p-b*h);
}

// Find a canonical representative under the group action - generally
// the length of the vector decreases to a minimum, then increases
// again, so just iterate both ways to find the smallest (breaking ties
// the same way if two vectors are minimal).
vec2 reduce(vec2 p, mat2 A, mat2 Ainv) {
  if (p == vec2(0)) return p;
  while (true) {
    vec2 p1 = A*p;
    if (dot(p1,p1) >= dot(p,p)) break;
    p = p1;
  }
  while (true) {
    vec2 p1 = Ainv*p;
    if (dot(p1,p1) > dot(p,p)) break;
    p = p1;
  }
  return p;
}

vec3 getcol(vec2 ix) {
  //if (ix == vec2(0)) return vec3(1); // Show centre point
  uint h = uint(int(ix.x)*12345^int(ix.y));
  h = ihash(h);
  return h2rgb(float(h)/exp2(32.0));
}

void main(void) {
    // A can be any suitable element of the modular group. This
    // one has nice eigenvectors. Since determinant is 1, the
    // eigenvalues are real and distinct if Tr(A) > 2, and the
    // product of the eigenvalues is 1. If this is the case,
    // we have an eigendecomposition A = P'XP where P is the
    // matrix of eigenvectors and X is the diagonal matrix
    // of the eigenvalues k,1/k.
    mat2 A = mat2(2,1,1,1); // Must have Tr(A) > 2 and det(A) = 1
    //A = mat2(0,-1,1,3);
    float a = A[0][0], b = A[1][0], c = A[0][1], d = A[1][1];
    assert(a+d > 2.0);
    assert(a*d - b*c == 1.0);
    float trace = a+d;
    float disc = trace*trace-4.0;
    float l0 = 0.5*(trace-sqrt(disc));
    float l1 = 0.5*(trace+sqrt(disc)); // l1 = 2.618
    vec2 e0 = normalize(vec2(-b,a-l0));
    vec2 e1 = normalize(vec2(-b,a-l1));
    mat2 P = mat2(e0,e1); // Eigenvector matrix
    //P = mat2(-1, 1.618034,-1,-0.618034); // For A = (2,1,1,1) (unnormalized)
    mat2 Ainv = inverse(A);
    mat2 Pinv = inverse(P);
    float cycle = log(l1); // Largest eigenvalue
    vec2 uv = (2.0*gl_FragCoord.xy-resolution.xy)/resolution.y;
    uv += 0.25; uv = rotate(uv,0.1*time); uv -= 0.25;
    uv *= 8.0;
    //if (mouse*resolution.xy.x > 0.0) uv *= exp2(3.0*mouse*resolution.xy.x/resolution.x-1.0);
    float px = fwidth(uv.x);
    float k = exp(cycle*fract(0.25*time)-0.5); // Time loop (repeat every 4 seconds)
    uv *= vec2(k,1.0/k);
    uv = P*uv;
    vec2 ix = round(uv);
    uv -= ix;
    vec2 uv0 = uv;
    uv = Pinv*uv;
    uv *= vec2(1.0/k,k); 
    vec3 col = vec3(1,1,0.75);
    if (false) {
      vec2 uv1 = 0.5-abs(uv0);
      float d = min(uv1.x,uv1.y);
      float px = fwidth(d);
      vec3 col0 = vec3(0), col1 = vec3(0);
      if (mod(ix.x+ix.y,2.0) == 0.0) col0 = col;
      else col1 = col;
      col = mix(col0,col1,smoothstep(-px,px,d)); // Show cells
    }
    vec2 ix0 = ix;
    ix = reduce(ix,A,Ainv);
    float radius = 0.32;
    vec3 dcol = getcol(ix);
    vec2 rad = rotate(vec2(1,0),0.25*ix.x*time);
    dcol *= smoothstep(0.0,px,segment(uv,-rad,rad)-0.01); 
    col = mix(dcol,col,vec3(smoothstep(0.0,px,length(uv)-radius)));
    col *= smoothstep(0.0,px,abs(length(uv)-radius)-0.01);
    //if (ix0 != ix) col *= 0.5; // Fundamental region
    col = pow(col,vec3(0.4545));
    if (alert) col.r = 1.0;
    glFragColor = vec4(col,1.0);
}
