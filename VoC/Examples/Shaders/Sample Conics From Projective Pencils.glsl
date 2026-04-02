#version 420

// original https://www.shadertoy.com/view/tdSyDz

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

////////////////////////////////////////////////////////////////////////////////
//
// Conics as Intersections of Pencils of Lines
// Matthew Arcus, mla, 2020
//
// Companion piece to https://www.shadertoy.com/view/Ws2cRh: here we
// have a correspondence between to two pencils of lines (a pencil of
// lines is just the set of all lines through a given point), where
// the points of intersection of corresponding lines outline the
// conic (corresponding lines have the same colour).
//
// Mouse changes the parameters of the correspondence, generating
// different conics.
//
// A projective mapping of parameter t, 0 <= t < PI to the lines
// in a pencil (as the angle with some axis) is:
//
// g(t) = atan(A*tan(t+B)+C)
//
// and since tan(t+B) =  we see that:
//
// g(t) = atan(A*(tan(t)+tan(B))/(1-tan(t)*tan(B))+C)
//      = atan(f(tan(t))) where f(x) = A*(x+tan(B))/(1-x*tan(B)) + C
// 
// (so f(x) is a 1d real Mobius tranformation: f(x) = (ax+b)/(cx+d),
// but we have parametrized it with (A,B,C) rather than (a,b,c,d) -
// think of stereographic projection from a circle to a line).
//
// Given two pencils, we can establish a correspondence with two
// mappings g1, g2 as above, and then line g1(t) in pencil 1
// corresponds with line g2(t) in pencil 2. Here, g1(t) is the
// identity map, with A=1,B=C=0, and g2(t) has A = 1 and derives B and
// C from mouse position. Only N regularly spaced lines from [0..PI]
// are displayed.
//
////////////////////////////////////////////////////////////////////////////////

const float PI =  3.141592654;

vec3 join(vec3 p, vec3 q) {
  // Return either intersection of lines p and q
  // or line through points p and q, r = kp + jq
  return cross(p,q);
}

float point(vec3 p, vec3 q) {
  if (abs(p.z) <= 1e-4) return 1e8;
  p /= p.z; q /= q.z; // Normalize
  return distance(p.xy,q.xy);
}

float line(vec3 p, vec3 q) {
  return abs(dot(p,q)/(p.z*length(q.xy)));
}

// Smooth HSV to RGB conversion 
// Function by iq, from https://www.shadertoy.com/view/MsS3Wc
vec3 hsv2rgb( in vec3 c ) {
  vec3 rgb = clamp( abs(mod(c.x*6.0+vec3(0.0,4.0,2.0),6.0)-3.0)-1.0, 0.0, 1.0 );
  rgb = rgb*rgb*(3.0-2.0*rgb); // cubic smoothing    
  return c.z * mix( vec3(1.0), rgb, c.y);
}

float N = 50.0;

// Find parameter t of the nearest displayed line from the pencil.
// t is actually in range [0,1)
float nearestline(vec2 p, vec2 centre, vec3 mobius, out float index) {
  float A = mobius.x, B = mobius.y, C = mobius.z;
  p -= centre;
  float t = p.y/p.x;
  // Look out for infinities here
  if (p.x == 0.0) sign(p.y)*1e4;
  //t = atan(A*tan(t+B)+C);
  t = A*(t+B)/(1.0-t*B)+C;
  t = atan(t);
  // Add time offset and round to nearest line
  t = t/PI+0.05*time;
  t *= N;
  t = mod(round(t),N);
  index = t;
  t /= N;
  return t;
}

// Make line coordinates for the line with parameter t in the given pencil.
vec3 makelinecoords(float t, vec2 centre, vec3 mobius) {
  float A = mobius.x, B = mobius.y, C = mobius.z;
  t -= 0.05*time;
  t = (tan(t*PI)-C)/A;
  // Infinities!
  if (abs(t) > 1e4) t = sign(t)*1e4;
  t = (t-B)/(1.0+t*B);
  return join(vec3(centre,1),vec3(centre+vec2(1,t),1));
}

void main(void) {
  vec2 p = (2.0*gl_FragCoord.xy - resolution.xy)/resolution.y;
  float scale = 3.0;
  float A = 1.0, B = 1.4, C = -0.5;
  //if (mouse*resolution.xy.x > 0.0) {
  //  vec2 m = (2.0*mouse*resolution.xy.xy - resolution.xy)/resolution.y;
  //  B = tan(0.5*PI*m.y); // B represents angular offset
  //  C = m.x; // C is linear offset
  //}
  p *= scale;
  vec2 centre1 = vec2(1,0);
  vec2 centre2 = vec2(-1,0);
  vec3 mobius1 = vec3(1,0,0);
  vec3 mobius2 = vec3(A,B,C);
  float index1,index2;
  float t1 = nearestline(p,centre1,mobius1,index1);
  vec3 l1 = makelinecoords(t1,centre1,mobius1);
  vec3 l12 = makelinecoords(t1,centre2,mobius2);
  vec3 p1 = join(l1,l12);

  float t2 = nearestline(p,centre2,mobius2,index2);
  vec3 l2 = makelinecoords(t2,centre2,mobius2);
  vec3 l21 = makelinecoords(t2,centre1,mobius1);
  vec3 p2 = join(l2,l21);
  
  float lwidth0 = 0.0;
  float pwidth0 = 0.02;
  float lwidth1 = 0.015;
  lwidth1 = max(lwidth1,1.5*fwidth(p.x));
  float pwidth1 = max(0.05,fwidth(p.x));
  pwidth1 = max(pwidth1,fwidth(p.x));
  vec3 col = vec3(0);
  vec3 pcolor = vec3(0.8);
  float d;
  d = line(vec3(p,1),l2);
  col = mix(hsv2rgb(vec3(index2/N,1,1)),col,smoothstep(lwidth0,lwidth1,d));
  d = line(vec3(p,1),l1);
  col = mix(hsv2rgb(vec3(index1/N,1,1)),col,smoothstep(lwidth0,lwidth1,d));
  d = point(vec3(p,1),p1);
  col = mix(pcolor,col,smoothstep(pwidth0,pwidth1,d));
  d = point(vec3(p,1),p2);
  col = mix(pcolor,col,smoothstep(pwidth0,pwidth1,d));
  glFragColor = vec4(pow(col,vec3(0.4545)),1);
}
