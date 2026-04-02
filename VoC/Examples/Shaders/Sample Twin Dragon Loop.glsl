#version 420

// original https://www.shadertoy.com/view/DtjGDK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Base -1+i Twindragon Loop, mla, 2023.
// Original: https://www.shadertoy.com/view/dtj3Wy by @FabriceNeyret2

// base -1+i  allows to represent the whole complex plane as a binary number set.
// TwinDragon of order n = all positions that can be represented with n bits.
// cf https://en.wikipedia.org/wiki/Complex-base_system#Base_%E2%88%921_%C2%B1_i

// Replaced complex div with a matrix multiplication - other matrices
// are possible, though the ones I've tried have been rather ugly (and
// break the looping).
//
// There is a relation between the magic numbers NCOLS and LOOP, but I'm
// not sure what it is. Some interesting sample values shown.
//
// Loop goes faster (on Intel anyway) with explicit counter & bound.

bool alert = false;
void assert(bool b) {
  if (!b) alert = true;
}

mat2 rotate(float t) {
  return mat2(cos(t),-sin(t),sin(t),cos(t));
}

vec3 h2rgb(float h) {
  vec3 rgb = clamp( abs(mod(h*6.0+vec3(0.0,4.0,2.0),6.0)-3.0)-1.0, 0.0, 1.0 );
  return rgb*rgb*(3.0-2.0*rgb); // cubic smoothing    
}

void main(void) { //WARNING - variables void (out vec4 O, vec2 I) { need changing to glFragColor and gl_FragCoord.xy
  vec2 I = gl_FragCoord.xy;
  vec4 O = vec4(0.0);

  int AA = 2, NBITS = 80;
  int NCOLS = 8, LOOP = NCOLS/2;
  //NCOLS = 2, LOOP = 4;
  //NCOLS = 4, LOOP = 4;
  //NCOLS = 16, LOOP = NCOLS/2;
  //NCOLS = 3, LOOP = NCOLS*4;
  //NCOLS = 5, LOOP = NCOLS*4;
  mat2 A = 0.5*mat2(-1,-1,1,-1); // NB: det(a) = 0.5 < 1
  vec3 basecol = vec3(1,1,0.5);
  I -= 0.5*resolution.xy; // Centering
  O = vec4(0);
  for (int i = 0; i < AA; i++) {
    for (int j = 0; j < AA; j++) {
      vec2 p = I + vec2(i,j)/float(AA);
      p *= rotate(0.1*time); // Rotate a little
      p *= exp2(mod(-0.75*time,float(LOOP))); // Exponential zoom
      int i = 0;
      for (i = 0; i < NBITS; i++) {
        assert(i < NBITS-1);
        p = floor(A*p); // Integral division by -1+i
        if (p == vec2(0)) break;
      }
      O.rgb += float(i%NCOLS)/float(NCOLS-1)*basecol;
      //O.rgb += h2rgb(float(i%NCOLS)/float(NCOLS));
    }
  }
  O /= float(AA*AA);
  O = pow(O,vec4(0.4545));
  if (alert) O.r = 1.0;

  glFragColor = O;
}
