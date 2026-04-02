#version 420

// original https://www.shadertoy.com/view/WtdBWj

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

////////////////////////////////////////////////////////////////////////////////
//
// Dual snub hexagonal tiling (so the tiles are generally pentagons).
// Matthew Arcus, mla, 2021
//
// Wythoff construction, with the Wythoff point varying across the plane.
// Inspired by Craig S. Kaplan: https://twitter.com/cs_kaplan/status/1361089568229974017
// 
// <mouse>: Uniform tiling across plane
//
////////////////////////////////////////////////////////////////////////////////

vec2 reflection(vec2 p, vec2 q, vec2 r) {
  // reflect p in the line through q and r
  p -= q;
  vec2 n = (r-q).yx * vec2(1,-1);
  p -= 2.0*dot(p,n)*n/dot(n,n);
  p += q;
  return p;
}

float segment(vec2 p, vec2 a, vec2 b) {
  vec2 pa = p - a;
  vec2 ba = b - a;
  float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
  float d = length(pa - ba * h);
  return d;
}

float line(vec2 p, vec2 a, vec2 b) {
  vec2 pa = p-a;
  vec2 ba = b-a;
  float h = dot(pa,ba)/dot(ba,ba);
  return length(pa - ba * h);
}

vec2 rotate(vec2 p, float t) {
  return cos(t)*p + sin(t)*vec2(-p.y,p.x);
}

const float X = sqrt(3.0);

float drawone(vec2 z, vec2 t0, float d) {
  d = min(d,segment(z,t0,vec2(0)));
  d = min(d,segment(z,t0,vec2(X,0)));
  d = min(d,segment(z,t0,vec2(0,1)));

  d = min(d,segment(-z,t0,vec2(0)));
  d = min(d,segment(-z,t0,vec2(X,0)));
  d = min(d,segment(-z,t0,vec2(0,1)));
  return d;
}

void main(void) {
  vec2 z = (2.0*gl_FragCoord.xy-resolution.xy)/resolution.y;
  z = rotate(z,0.05*time);
  z *= 16.0;
  vec2 z0 = z;

  const mat2 M = mat2(X,-3,X,3);
  z.x += X;
  z = inverse(M)*z; // Convert to square grid
  z -= floor(z);
  z = M*z; // Back to triangles
  z.x -= X;

  if (z.y < 0.0) z = -z; // Rotate lower triangle to upper.

  // Rotational symmetry about triangle centre, so map centre of triangle to origin...
  z.y -= 1.0;

  // ...and reflect in planes of symmetry of triangle
  const vec2 A = normalize(vec2(1,X));
  const vec2 B = normalize(vec2(-1,X));
  int parity = 0;
  float ta = dot(z,A);
  if (ta < 0.0) z -= 2.0*ta*A;
  float tb = dot(z,B);
  if (tb < 0.0) z -= 2.0*tb*B;
  if (int(ta>0.0) + int(tb>0.0) == 1) z.x = -z.x; // Want even number of reflections
  z.y += 1.0;        // Shift origin back to region centre,

  float pwidth = fwidth(z0.x);
  
  vec3 col0 = vec3(0);
  vec3 col1 = vec3(0.9);//vec3(1,0,0);
  vec3 col2 = vec3(0.95);//vec3(1,1,0);

  float d = min(abs(z.x),z.y);
  d = min(d,line(abs(z),vec2(0,1),vec2(X,0)));
  float mfact = smoothstep(-pwidth,pwidth,d);
  vec3 col = mix(col1,col2,(z.x < 0.0 ? mfact : mfact-1.0));
  
  vec2 z1 = vec2(-1,1)*reflection(z,vec2(X,0),vec2(0,1));
  vec2 z2 = reflection(vec2(-1,1)*z,vec2(X,0),vec2(0,1));
  vec2 t0 = (gl_FragCoord.xy-0.5*resolution.xy)/resolution.y;
  //if (mouse*resolution.xy.z > 0.0) t0 = (mouse*resolution.xy.xy-0.5*resolution.xy)/resolution.y;
  t0 = 1.2*rotate(t0,-0.2*time);
  
  d = 1e8;
  d = drawone(z,t0,d);
  d = drawone(z1,t0,d);
  d = drawone(z2,t0,d);

  col = mix(col0,col,smoothstep(0.015,0.015+1.25*pwidth,d));

  glFragColor = vec4(col,1.0);
}
