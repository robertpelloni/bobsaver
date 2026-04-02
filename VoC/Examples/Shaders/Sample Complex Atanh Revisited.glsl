#version 420

// original https://www.shadertoy.com/view/fldGRB

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

////////////////////////////////////////////////////////////////////////////////
// Complex Inverse Hyperbolic Tangent
//
// Domain mapping of sums of complex atanh.
// Care needed for alignment across branch cuts.
//
// Key controls:
// 'c': checkerboard
// 'm': monochrome
// 'o': circles
// 'p': z -> z^5
// 'i': z -> z+1/z
//
////////////////////////////////////////////////////////////////////////////////

float A = 11.0, B = 10.0; // Rotation angle is atan(B,A)
float scale = 1.5;
float PI = 3.14159;

// Complex functions
vec2 cmul(vec2 z, vec2 w) {
  //return vec2 (z.x*w.x-z.y*w.y, z.x*w.y+z.y*w.x);
  return mat2(z,-z.y,z.x)*w;
}

vec2 cinv(vec2 z) {
  float t = dot(z,z);
  return vec2(z.x,-z.y)/t;
}

vec2 cdiv(vec2 z, vec2 w) {
  return cmul(z,cinv(w));
}

vec2 clog(vec2 z) {
  float r = length(z);
  return vec2(log(r),atan(z.y,z.x));
}

// Inverse hyperbolic tangent 
vec2 catanh(vec2 z) {
  return 0.5*clog(cdiv(vec2(1,0)+z,vec2(1,0)-z));
}

vec2 cexp(vec2 z) {
  // If cos and sin were perfect we wouldn't need normalize
  return exp(z.x)*normalize(vec2(cos(z.y),sin(z.y)));
}

vec2 cpow(vec2 z, float x) {
  return cexp(x*clog(z));
}

vec3 mono(float h) {
  return fract(h)*vec3(1,0.8,0.8); // The monochrome look
}

// Iq's hsv function, but just for hue.
vec3 h2rgb(float h ) {
  vec3 rgb = clamp( abs(mod(h*6.0+vec3(0.0,4.0,2.0),6.0)-3.0)-1.0, 0.0, 1.0 );
  return 0.8*rgb*(3.0-2.0*rgb); // cubic smoothing    
}

const int KEY_PAGE_UP = 33;
const int KEY_PAGE_DOWN = 34;
const int KEY_LEFT = 37;
const int KEY_RIGHT = 39;
const int KEY_UP = 38;
const int KEY_DOWN = 40;

const int CHAR_0 = 48;

const int CHAR_A = 65;
const int CHAR_B = 66;
const int CHAR_C = 67;
const int CHAR_D = 68;
const int CHAR_E = 69;
const int CHAR_F = 70;
const int CHAR_G = 71;
const int CHAR_H = 72;
const int CHAR_I = 73;
const int CHAR_J = 74;
const int CHAR_K = 75;
const int CHAR_L = 76;
const int CHAR_M = 77;
const int CHAR_N = 78;
const int CHAR_O = 79;
const int CHAR_P = 80;
const int CHAR_Q = 81;
const int CHAR_R = 82;
const int CHAR_S = 83;
const int CHAR_T = 84;
const int CHAR_U = 85;
const int CHAR_V = 86;
const int CHAR_W = 87;
const int CHAR_X = 88;
const int CHAR_Y = 89;
const int CHAR_Z = 90;

// Macros for use in "common" blocks.
#if !defined(key)
#define key(code) (texelFetch(iChannel3, ivec2((code),2),0).x != 0.0)
#endif
#define store(i,j) (texelFetch(iChannel2, ivec2((i),(j)),0))
#define keycount(key) (int(store(0,(key)).x))

vec3 getcolor(float h) {
 //if (!key(CHAR_M)) return mono(h);
 return 0.1+0.8*h2rgb(h);
}

void main(void) {
  //if (mouse*resolution.xy.x > 0.0) {
    // Get angle from mouse position
  //  vec2 m = (2.0*mouse*resolution.xy.xy-resolution.xy)/resolution.y;
  //  m *= 20.0;
  //  A = floor(m.x), B = floor(m.y);
  //}
  vec2 rot = vec2(A,B);
  vec2 z = (2.0*gl_FragCoord.xy-resolution.xy)/resolution.y;
  z *= scale;
  //if (!key(CHAR_P)) z = cpow(z,5.0);//min(1.0+floor(time),5.0));
  // catanh is liable to add random multiples of PI
  // to the y output. This being so, our coloring function must
  // return the same color for all such multiples, ie. it must
  // be periodic with period PI
  //if (!key(CHAR_I)) z += cinv(z); // z += 1/z
  z = catanh(-0.5*z) + catanh(cmul(vec2(cos(0.1*time),sin(0.1*time)), z));
  z /= PI; // Required period is now 1
  float px = fwidth(z.x); // z.x is continuous, unlike z.y
  z.y += 0.02*time;
  //z.y = mod(z.y,1.0); // Check periodicity - this should have no effect!
  z = cmul(rot,z); // rotate z
  px *= length(rot); // and scale pixel width
  vec2 index = round(z); // Nearest grid point
  z -= index; // Reduce to [-0.5,+0.5]
  float hx = fract(index.x/(B==0.0 ? 1.0 : B)); // Color for column
  float hy = fract(index.y/(A==0.0 ? 1.0 : A)); // Color for row
  float d = max(abs(z.x),abs(z.y)); // Square
  vec3 colx = getcolor(hx);
  vec3 coly = getcolor(hy+0.25);
  vec3 col = vec3(0);
  //if (!key(CHAR_C)) {
  //  float k = z.x*z.y;
  //  col = mix(colx,coly, smoothstep(-px,px,sign(k)*min(abs(z.x),abs(z.y)))); // Checkerboard
  //} else {
    col = mix(coly,colx, smoothstep(-px,px,d-0.3)); // Concentric
  //}
  col *= 1.0-smoothstep(-px,px,d-0.5);
  col = pow(col,vec3(0.4545));
  glFragColor = vec4(col,1);
}
