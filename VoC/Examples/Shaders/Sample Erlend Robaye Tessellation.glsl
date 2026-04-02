#version 420

// original https://www.shadertoy.com/view/4cX3DM

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const vec3 COLOR0 = vec3( 0.00, 0.00, 0.00 );
const vec3 COLOR1 = vec3( 0.93, 0.37, 0.00 );
const vec3 COLOR2 = vec3( 1.00, 1.00, 1.00 );

// controls geometry of tesselation
const float TRIANGLE_SIZE = .08;
const vec2 P1 = vec2( 1.05, .35 );

// "size" of the arrows
//const float TESSELATION_SCALE = 10.;

// constants
const vec2 O = vec2( 0., 0. );
const vec2 A = vec2( 2., 0. );
const vec2 C = vec2( 1., sqrt(3.)/3. );
const vec2 D = vec2( 1., sqrt(3.) );
const vec2 P2 = vec2( TRIANGLE_SIZE, sqrt(3.) * TRIANGLE_SIZE );
const vec2 P3 = vec2( P2.x, 0. );

const float PI = acos(0.) * 2.;
mat2 rot( float a ) { return mat2( cos(a), sin(a), -sin(a), cos(a) ); }

bool isClockwise( vec2 a, vec2 b, vec2 c )
{
    b -= a;
    c -= a;
    return b.x*c.y < b.y*c.x;
}

float signedDistToLine( vec2 p, vec2 line0, vec2 line1 )
{
    p -= line0;
    vec2 n = normalize( line1 - line0 );
    return n.y * p.x - n.x * p.y;
}

// returns either p or the mirror image of p across line(a,b)
vec2 fold( vec2 p, vec2 a, vec2 b )
{    
    p -= a;
    b -= a;
    if ( b.x * p.y < b.y * p.x )
        return p + a;
    vec2 v = dot( p, b ) / dot( b, b ) * b;
    return 2.*v - p + a;
}

vec3 combine( vec3 color0, vec3 color1, float d, float featherAmt )
{
    //const float FEATHER = .04;
    return mix( color0, color1, smoothstep( -featherAmt, featherAmt, d ) );
}

// input `p`: coordinate inside 1/3 of an equilateral triangle
// input `featherAmt`: controls blurriness/antialiasing
//
//                                                   P1'  
//                                                  --*
//                            (1, sqrt(3)/3)    ----   \      Note:
//                                          C---        \     P1', P2', P3' are
//                                       /  || \         \    P1, P2, P3 rotated 
//                                    /     ||    \       \   120 degrees about C
//                                 /        | |      \     \
//                              /           | |         \   \
//                           /              |  |           \ \
//            P2          /                 |  |              \            P3'
//             *-------/-----------------------*               \ \        *
//             |    /                       |   P1              \   \   /
//             | /                          |                    \     \
//            /|                            |                     \  /    \
//         O---*----------------------------*----------------------*---------A
//       (0,0) P3                          (1,0)                   P2'       (2,0)
// 
vec3 baseTriangle( vec2 p, float featherAmt )
{
    //if ( featherAmt > .05 ) return vec3( 0., 1., 0. ); // returns a good approximation of the code below
    
    vec3 col;
    if ( p.x > P1.x + .05 )
    {
        p = rot(PI*-2./3.) * (p-C) + C;
        col = combine( vec3( 0., 1., 0. ), vec3( 0., 0., 1. ), min( signedDistToLine( p, P2, P1 ), signedDistToLine( p, P3, P2 ) ), featherAmt );           ;
    }
    else
    {    
        col = vec3( 0., 1., 0. );
        col = combine( col, vec3( 1., 0., 0. ), signedDistToLine( p, P2, P3 ), featherAmt );
        col = combine( col, vec3( 1., 0., 0. ), min( signedDistToLine( p, C, P1 ), signedDistToLine( p, P1, P2 ) ), featherAmt );
    }
    
    // when featherAmt is large, we'll just use an even mix of all 3 colors (vec3(1./3.))
    const float FILTER_THRESHOLD_LO = .8;
    const float FILTER_THRESHOLD_HI = 4.0;    
    float fog = clamp( (1./featherAmt - 1./FILTER_THRESHOLD_LO) / (1./FILTER_THRESHOLD_HI - 1./FILTER_THRESHOLD_LO), 0., 1. );    
    col = mix( col, vec3( 1./3. ), fog );
    return col;
}

// combines 3 baseTriangle()s
vec3 equilateralTriangle( vec2 p, float featherAmt )
{
    if ( isClockwise( O, C, p ) && isClockwise( C, A, p ) )
        return baseTriangle( p, featherAmt );
    if ( p.x < 1. )
        return baseTriangle( rot(PI*2./3.) * (p-C) + C, featherAmt ).gbr;
    return baseTriangle( rot(PI*-2./3.) * (p-C) + C, featherAmt ).brg;
}

// combines 2 equilateralTriangle()s
vec3 parallelogram( vec2 p, float featherAmt )
{
    return equilateralTriangle( fold( p, D, A ), featherAmt );
}

vec3 erlendRobayeArrowTessellation( vec2 p, float featherAmt ) // tesselates the plane
{
    const mat2 SKEW = mat2( A.x, 0., .5*A.x, D.y );
    vec2 uv = inverse( SKEW ) * p; // skewed grid (uv coordinates for the "base" parallelogram)
    p = SKEW * fract( uv ); // unskew grid (convert back to model coordinates)
    
    vec2 cell = floor( uv );
    float colorSwap = mod( cell.x - cell.y, 3. );
    
    vec3 col = parallelogram( p, featherAmt ); // col's components indicate how much of COLOR0, COLOR1, COLOR2 to use
    col = colorSwap == 0. ? col : colorSwap == 1. ? col.brg : col.gbr; // comment this line to see the cells (parallelograms)
    
    return col.r * COLOR0 + col.g * COLOR1 + col.b * COLOR2;
}

void main(void)
{
    bool useMouse = !(mouse*resolution.xy.x == 0. && mouse*resolution.xy.y == 0.);
    vec2 mousePos = vec2(0.3); //mouse*resolution.xy.xy / resolution.xy;

    vec2 p = (gl_FragCoord.xy*2. - resolution.xy) / resolution.y;
    p += vec2( .5, 0. ); // offset tunnel from center
    
    vec2 uv = vec2( atan( p.y, p.x ) / (2. * PI) + .5, log( length( p ) ) ); // tunnel effect
    uv += time * vec2( .01, -.3 ); // movement
    
    float TESSELATION_SCALE = useMouse ? floor( mousePos.x * mousePos.x * 100. + 1. ) : 10.;
    //float BASE_FEATHER_AMOUNT = useMouse ? mousePos.y * 10. : 1.8;
    float BASE_FEATHER_AMOUNT = 1.8;
    
    float feather = BASE_FEATHER_AMOUNT / resolution.y * TESSELATION_SCALE / length( p );
    glFragColor = vec4( erlendRobayeArrowTessellation( uv * vec2( 6., 1. ) * TESSELATION_SCALE, feather ), 1. );
}