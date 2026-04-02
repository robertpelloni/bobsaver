#version 420

// original https://www.shadertoy.com/view/3tSBRG

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// variant of https://shadertoy.com/view/3lSfWW
// inspired from https://shadertoy.com/view/WtBBD1

float A = .2, // Anisotropy. 1 = isotropic
      D = 0., // favorite dir
      K = 0.; // seed for random numbers
//#define D atan((p).y,(p).x)

//#define rot(a)       mat2( cos( a + vec4(0,11,33,0) ) )
  #define hash(p,K)    fract(sin(dot(p+K, vec2(12.9898, 78.233))) * 43758.5453)
//#define hash2(p) ( 2.* fract( sin( (p) * mat2(127.1,311.7, 269.5,183.3) ) *43758.5453123 ) - 1. )
  #define hash2(p)   cos( A/2.*6.28*hash(p,K) + vec2(0,11) + D + V(p)*time ) // variant of random gradient + rotating (= lownoise)
//#define l(i,j)     dot( hash2(I+vec2(i,j)) , F-vec2(i,j) )       // random wavelet at grid vertex I+vec2(i,j) 
  #define Gabor(v,x,f)   cos( 6.28*( 2.*dot(x,v) + f ) ) * exp(-.5*1.*dot(x,x) )
  #define l(i,j)     Gabor( hash2(I+vec2(i,j)), F-vec2(i,j) , hash(I+vec2(i,j),2.))       // random wavelet at grid vertex I+vec2(i,j) 
  #define L(j,x)     mix( l(0,j), l(1,j), x )

  #define V(p) 0.                                // flownoise rotation speed 
//#define V(p) 1.*( 2.*mod((p).x+(p).y,2.)- 1. ) // checkered rotation direction 
//#define V(p) length(p)
//#define V(p) ( 8. - length(p) )

float GaboryPerlin(vec2 p) {
    vec2 I = floor(p), 
         F = fract(p), 
     //  U = F;
     //  U = F*F*(3.-2.*F);                   // based Perlin noise
         U = F*F*F*( F* ( F*6.-15.) + 10. );  // improved Perlin noise ( better derivatives )
    return mix( L(0,U.x) , L(1,U.x) , U.y );  // smooth interpolation of corners random wavelets
}

float layer(vec2 U) {
#if 0
    float v = GaboryPerlin( U );             // only 1 kernel
#else
    float v = 0., N = 4.;
    for ( float i = 0.; i < 5.; i++, K+=.1 ) // sum N kernels
        v += GaboryPerlin( U ); 
    v /= 2.*sqrt(N);
    v *= mix(127./80.,127./50.,A)/2.; // try to regularize std-dev
#endif 
    return v;
}

float cascade(vec2 U) {  // --- regular additive cascade
    float v = 0., s = .5, A0=A;
    U += 100.;
    for (int i=0; i<5; i++)
     // A = mix(1.,A0,1.-.5*float(i)/4.), // octave-dependent anisotropy
        v += layer(U)*s, U*=2., s/=2.;
    return v;
}

float mul_cascade(vec2 U) { // --- multiplicativ cascade
    float v = 1., A0=A;
    U += 100.;
    for (int i=0; i<5; i++)
     // A = mix(1.,A0,1.-.5*float(i)/4.), // octave-dependent anisotropy
        v *= 1.+layer(U), U*=2.;
    return v;
}

void main(void)
{
    vec2 u = gl_FragCoord.xy;
    vec2 R = resolution.xy,
         S = 8. / R.yy,
         U = ( 2.*u - R ) * S, I = floor(U);
    
    A = .5+.5*sin(time);   // anisotropy
  //A = mix(1.,A, dot(I,I));
  //A = abs( length(I)*2.-1.);
  //D = atan(U.y,U.x);      // prefered direction
    D = 2.*3.14 * cos(u.x/R.y) * cos(u.y/R.y);
    
 // float v = .5+.5*layer(U); O = vec4(v); return;
    float v = mul_cascade(U/8.) / 3.;
    

    glFragColor = v * vec4(1,1.2,1.7,1); // coloring
 }
