#version 420

// original https://www.shadertoy.com/view/fl2SDV

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// porting Own_Army5576's  https://www.desmos.com/calculator/hnsjwwp02s
// see https://old.reddit.com/r/desmos/comments/ovpnyg/desmos_challenge_12_mazes/h7k89oz/

// draw line segment https://www.shadertoy.com/view/llySRh
float D(vec2 p, vec2 a, vec2 b) { 
    p -= a, b -= a;
    float h = clamp(dot(p, b) / dot(b, b), 0., 1.);
    p -= b * h;
    return dot(p,p);
}
#define S(v) smoothstep( 9./R.y, 0., v )    

// draw poly-line.  NB: GLSL func can't have vec2[] parameter → macro
#define L( U, L, n, s )                                          \
    for( a = L[i=0] ; i < n ; a=b, i++ ) {                       \
        b = L[i];                                                \
        if (b.x==99.) a = L[++i], b = L[++i];                    \
        m = min(m, D(U,a*s,b*s) );                               \
    } 

// maze tile
vec2 L[] = vec2[] (
    vec2(5,-5),vec2(3,-5),vec2(3,-7),vec2(  1,-7),vec2(1,-9),vec2(9,-9),vec2(9,9),vec2(-9,9),vec2(-9,-9),vec2(-1,-9),vec2(-1,-5),vec2(1,-5),vec2(1,-3),vec2(99),
    vec2(3,-3),vec2(7,-3),vec2(7,-7),vec2(7,7),vec2(99),
    vec2(5,-9),vec2(5,-7),vec2(99),
    vec2(5,9),vec2(5,3),vec2(99),
    vec2(5,-1),vec2(5,1),vec2(3,1),vec2(3,7),vec2(99),
    vec2(1,9),vec2(1,5),vec2(99),
    vec2(-1,3),vec2(-1,7),vec2(99),
    vec2(-3,9),vec2(-3,5),vec2(-5,5),vec2(-5,1),vec2(-5,5),vec2(-7,5),vec2(-7,7),vec2(-5,7),vec2(99),
    vec2(-3,-1),vec2(-7,-1),vec2(-7,3),vec2(-7,-3),vec2(-5,-3),vec2(99),
    vec2(-7,-5),vec2(-3,-5),vec2(-3,-3),vec2(-3,-7),vec2(-7,-7),vec2(99),
    vec2(1,-3),vec2(3,-3),vec2(3,3),vec2(-3,3),vec2(-3,-3),vec2(-1,-3)
  );
// solved trajectory  
vec2 T[] = vec2[] ( 
   vec2(0,-9),vec2(0,-6),vec2(2,-6),vec2(2,-4),vec2(4,-4),vec2(6,-4),vec2(6,-6),vec2(6,-8),vec2(8,-8),vec2(8,-6),vec2(8,-4),vec2(8,-2),vec2(8,0),
   vec2(8,2),vec2(8,4),vec2(8,6),vec2(8,8),vec2(6,8),vec2(6,6),vec2(6,4),vec2(6,2),vec2(4,2),vec2(4,4),vec2(4,6),vec2(4,8),vec2(2,8),vec2(2,6),
   vec2(2,4),vec2(0,4),vec2(0,6),vec2(0,8),vec2(-2,8),vec2(-2,6),vec2(-2,4),vec2(-4,4),vec2(-4,2),vec2(-4,0),vec2(-6,0),vec2(-6,2),vec2(-6,4),
   vec2(-8,4),vec2(-8,2),vec2(-8,0),vec2(-8,-2),vec2(-8,-4),vec2(-8,-6),vec2(-8,-8),vec2(-6,-8),vec2(-4,-8),vec2(-2,-8),vec2(-2,-6),vec2(-2,-4),vec2(0,-4),vec2(0,-3) 
  );

void main(void) //WARNING - variables void ( out vec4 O, vec2 u ) need changing to glFragColor and gl_FragCoord.xy
{
    vec4 O = glFragColor;
    vec2 u = gl_FragCoord.xy;

    vec2  R = resolution.xy,
          U = 3.*( 2.*u - R ) / R.y, a,b;

    float s = .33+.67*exp2( mod(time,2.) ), // original: 1. + mod(time,2.);
          m =  99., l;
    
    int i,z,p = T.length(), n = int(26.5*(s-1.)+1.);
    for ( z=0; z < 3; s/=3., z++ ) {                    // fractal levels
        if (z==2) p = n;                                // full L0,L1, evol L2
        L( U, T, p, s);                                 // draw trajectory tile
    }
    l = m; s*=27.;
    
    for ( z=0; z < 6; s/=3., z++ )                      // fractal levels
        L( U, L, L.length(), s );                       // draw maze tile

    O = vec4(1);                                        // paint
    O -= m==l ? S( sqrt(m) - 20./R.y ) * vec4(0,1,1,0)
              : vec4( S( sqrt(m)));

    glFragColor = O;
}
