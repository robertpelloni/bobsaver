#version 420

// original https://www.shadertoy.com/view/3tBcRh

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

////////////////////////////////////////////////////////////////////////////////
//
// Equithirds tiling with barycentric coords, mla, 2020
//
// https://tilings.math.uni-bielefeld.de/substitution/equithirds/
//
// Given points p,q,r, the centroid is at (p+q+r)/3 and the trisectors
// of side pq are (p+2q)/3, (2p+q)/3. These are the points needed to
// recursively construct the equithirds tiling, and the rest is just
// bookkeeping. We could reuse the current barycentric coords for the
// subdivided triangle, but for simplicity we recalculate them each time
// around. And not a trig function to be seen.
//
// See also:
// https://www.shadertoy.com/view/WtSczR by jeyko
// https://www.shadertoy.com/view/WlfGWN by fizzer
//
////////////////////////////////////////////////////////////////////////////////

void getbary(vec2 z, vec2 p, vec2 q, vec2 r, out float a, out float b, out float c) {
  // Thanks to wikipedia
  mat2 t = mat2(p-r,q-r);
  vec2 lam = inverse(t)*(z-r);
  a = lam.x; b = lam.y; c = 1.0-a-b;
}

float linedist(vec2 p, vec2 a, vec2 b) {
  vec2 pa = p-a;
  vec2 ba = b-a;
  float h = dot(pa,ba)/dot(ba,ba);
  return length(pa-ba*h);
}

int tiling(vec2 z, int iterations, vec2 p, vec2 q, vec2 r, out float d) {
  int state = 0;
  for (int i = 0; i < iterations; i++) {
    float a,b,c;
    getbary(z,p,q,r,a,b,c);
    if (state == 0) {
      vec2 s = (p+q+r)/3.0;
      if (a < b && a < c) {
        p = s; // q,r stay same
      } else if (b < a && b < c) {
        q = r; r = p; p = s;
      } else {
        r = q; q = p; p = s;
      }
      state = 1;
    } else {
      vec2 s = (r+2.0*q)/3.0;
      vec2 t = (q+2.0*r)/3.0;
      if (b > 2.0*c) {
        r = q; q = p; p = s;
      } else if (c > 2.0*b) {
        q = r; r = p; p = t;
      } else {
        q = s; r = t;
        state = 0;
      }
    }
  }
  d = min(linedist(z,p,q),
          min(linedist(z,q,r),
              linedist(z,r,p)));
              
  return state;
}

void main(void) {
  vec2 z = (2.0*gl_FragCoord.xy-resolution.xy)/resolution.y;
  float k = 5.0;
  vec2 p = k*vec2(0,1), q = k*vec2(0.5*sqrt(3.0),-0.5), r = k*vec2(-0.5*sqrt(3.0),-0.5);
  vec3 col = vec3(0);
  int iterations = 2+int(time)%12;
  float d;
  int t = tiling(z,iterations,p,q,r,d);
  float lwidth = 0.1*exp2(-0.5*float(iterations));
  if (t == 0) col = vec3(1,0,0);
  else col = vec3(0,1,1);
  col = mix(vec3(1),col,0.8);
  col *= smoothstep(0.5*lwidth,lwidth,d);
  glFragColor = vec4(col,1);
}
