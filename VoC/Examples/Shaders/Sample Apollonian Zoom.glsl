#version 420

// original https://www.shadertoy.com/view/Wt3XR8

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

////////////////////////////////////////////////////////////////////////////////
//
// Apollonian circles. Iterated inversion in a ring of circles.
//
////////////////////////////////////////////////////////////////////////////////

const float N = 5.0; // Number of circles
const int max_iterations = 40;
const float pi = 3.14159265;

// Circles are represented as vec3(x,y,r2) where
// (x,y) is the centre and r2 is the squared radius.

// Invert pos in circle c
vec2 invert(vec2 pos, vec3 c) {
  vec2 p = pos-c.xy;
  float p2 = dot(p,p);
  return p*c.z/p2 + c.xy;
}
  
// Invert pos in circle if it is inside 
bool checkinverse(inout vec2 pos, vec3 c, inout float r2min) {
  vec2 p = pos-c.xy; 
  float p2 = dot(p,p);
  r2min = min(r2min,abs(p2-c.z));
  if (p2 > c.z) {
    return false;
  } else {
    pos = p*c.z/p2 + c.xy;
    return true;
  }
}

bool checkinverse2(inout vec2 pos, vec3 c, inout float r2min) {
  vec2 p = pos-c.xy; 
  float p2 = dot(p,p);
  r2min = min(r2min,abs(p2-c.z));
  if (p2 < c.z) {
    return false;
  } else {
    pos = p*c.z/p2 + c.xy;
    return true;
  }
}

// N circles in a ring, with tangency points on unit circle,
// plus a central circle, tangent to the others, plus an
// surrounding circle, tangent to the ring circles.
// The radius of the ring circles can vary so as to overlap
// or to leave a gap.
vec4 gasket(vec2 pos, bool varyradius){
  float theta = pi/N;
  float r = 1.0/cos(theta);
  float s = tan(theta);
  float r2min = 1e10;
  float t = -0.2*time;
  float rfactor = !varyradius?1.0:0.95 + 0.26*(1.0+cos(0.5*time));
  for(int n = 0; n < max_iterations; n++){
    vec3 c = vec3(0,0,pow(r-s,2.0));
    // Try inverting in central circle
    if (!checkinverse(pos,c,r2min) &&
        !checkinverse2(pos,vec3(0.0,0.0,pow(r+s,2.0)),r2min)) {
      bool found = false;
      // else try in the circles of the ring.
      for (float i = 0.0; i < N; i++) {
        vec3 c = vec3(r*sin(2.0*i*theta+t),
                      r*cos(2.0*i*theta+t),
                      rfactor*s*s);
        if (checkinverse(pos,c,r2min)) {
          found = true;
          break;
        }
      }
      if (!found) return vec4(pos,n,r2min);
    }
  }
  return vec4(pos,max_iterations,r2min);
}

// Smooth HSV to RGB conversion 
// Function by iq, from https://www.shadertoy.com/view/MsS3Wc
vec3 hsv2rgb( in vec3 c ) {
  vec3 rgb = clamp( abs(mod(c.x*6.0+vec3(0.0,4.0,2.0),6.0)-3.0)-1.0, 0.0, 1.0 );
  rgb = rgb*rgb*(3.0-2.0*rgb); // cubic smoothing    
  return c.z * mix( vec3(1.0), rgb, c.y);
}

vec3 getCol(vec4 n){
  vec3 col = hsv2rgb(vec3(mod(n.z/20.0,1.0),0.8,0.8));
  col *= 0.6+0.4*smoothstep(0.05,0.1,sqrt(n.w));
  return col;
}

bool keypress(int code) {
  return false; //texelFetch(iChannel0, ivec2(code,2),0).x != 0.0;
}

const int CHAR_A = 65;
const int CHAR_D = 68;
const int CHAR_H = 72;
const int CHAR_J = 74;
const int CHAR_V = 86;
const int CHAR_Z = 90;

vec2 cmul(vec2 z, vec2 w) {
  return vec2(z.x*w.x - z.y*w.y, z.x*w.y + z.y*w.x);
}

vec2 cinv(vec2 z) {
  return z/dot(z,z)*vec2(1,-1);
}

vec2 csqrt(vec2 z) {
  float r = length(z);
  return vec2(sqrt(0.5*(r+z.x)),sign(z.y)*sqrt(0.5*(r-z.x)));
}

#define AA 2.0

void main(void) {
  glFragColor.xyz = vec3(0);
  vec2 z0 = 2.0 * gl_FragCoord.xy / resolution.y - vec2(resolution.x / resolution.y, 1.0);
  float zoom = 1.0; 
  if (!keypress(CHAR_Z)) zoom = exp(44.0-mod(0.4*time,88.0));
  for (float i = 0.0; i < AA; i++) {
    for (float j = 0.0; j < AA; j++) {
      float delta = 1.0/(AA*resolution.y);
      vec2 z = z0 + delta*vec2(i,j);
      z *= zoom;
      if (keypress(CHAR_H)) {
        z.y += 1.0;
        z = invert(z,vec3(0,-1,2)); // Map half plane to unit disk.
      }
      if (keypress(CHAR_D)) {
        z = invert(z,vec3(0,0,1)); // Invert in unit disk
      }
      if (keypress(CHAR_A) && mouse*resolution.xy.x != 0.0) {
        vec2 m = 2.0 * mouse*resolution.xy.xy / resolution.y - vec2(resolution.x / resolution.y, 1.0);
        //m = 1.2*vec2(cos(0.0789*time),sin(0.0789*time));
        m *= zoom;
        // Map origin to m with an inversion
        vec2 c = m/dot(m,m); // m inverted in unit circle
        z = invert(z,vec3(c,dot(c,c)-1.0));
      }
      bool varyradius = !keypress(CHAR_V);
      vec4 data = gasket(z,varyradius);
             
      glFragColor.xyz += getCol(data);
    }
  }
  glFragColor.xyz /= AA*AA;
}
