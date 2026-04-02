#version 420

// original https://www.shadertoy.com/view/tlyXzW

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// -----------------------------------------------------------------------------------
//
// Carlos Ureña, Apr,2018
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
//
// -----------------------------------------------------------------------------------

const int   n_aa  = 3 ;
const float pi    = 3.1415927 ;
const float xfrec = 3.0 ;

// ----------------------------------------------------------------
// ISLAMIC STAR PATTERN related functions

// parameters and pre-calculated constants
const float
    sqr2       = 1.41421356237, // square root of 2
    sqr3       = 1.73205080756, // square root of 3.0
    sqr2_inv   = 1.0/sqr2 ,
    sqr3_inv   = 1.0/sqr3 ,
    cos30      = 0.86602540378, // cos(30 degrees)
    sin30      = 0.50000000000, // sin(30 degrees)
    l          = 5.5,          // length of triangle in NDC (mind --> 1.0)
    l_inv      = 1.0/l ,       // length inverse
    line_w     = 0.03,         // line width for basic symmetry lines render
    sw         = 0.020 ;       // stripes half width for islamic star pattern

const vec2
    u        = 1.0*vec2( 1.0, 0.0  ) ,          // grid basis: U vector
    v        = 0.5*vec2( 1.0, sqr3 ) ,          // grid basis: V vector
    u_dual   = 1.0*vec2( 1.0, -sqr3_inv ) ,     // dual grid basis: U vector
    v_dual   = 2.0*vec2( 0.0,  sqr3_inv ) ,     // dual grid basis: V vector
    tri_cen  = vec2( 0.5, 0.5*sqr3_inv ) ;      // triangle center

// -----------------------------------------------------------------------------------
// point orbit transformation parameters
int
    nMirrorOdd = 0 ,
    nMirror    = 0 ,
    nGridX     = 0 ,
    nGridY     = 0 ;

// -------------------------------------------------------------------------------
// mirror reflection of 'p' around and axis through 'v1' and 'v2'
// (only for points to right of the line from v1 to v2)
//
vec2 Mirror( vec2 p, vec2 v1, vec2 v2 )
{
     vec2   s = v2-v1 ,
           n = normalize(vec2( s.y, -s.x )) ;
    float  d = dot(p-v1,n) ;

    if ( 0.0 <= d )
    {
       nMirrorOdd = 1-nMirrorOdd ;
       nMirror = nMirror+1 ;
       return p-2.0*d*n ;
    }
    else
       return p ;
}
// -------------------------------------------------------------------
// Signed perpendicular distance from 'p' to line through 'v1' and 'v2'

float SignedDistance( vec2 p, vec2 v1, vec2 v2 )
{
     vec2   s = v2-v1 ,
           n = normalize(vec2( s.y, -s.x )) ;
    return dot(p-v1,n) ;
}
// -------------------------------------------------------------------
// un-normalized signed distance to line

float UnSignedDistance( vec2 p, vec2 v1, vec2 v2 )
{
     vec2   s = v2-v1 ,
           un = vec2( s.y, -s.x ) ;
    return dot(p-v1,un) ;
}
// -------------------------------------------------------------------
// Signed perpendicular distance from 'p' to polyline from 'v1'
// to 'v2' then to 'v3'

float DoubleSignedDistance( vec2 p, vec2 v1, vec2 v2, vec2 v3 )
{

    vec2  dir1 = v2 + normalize(v1-v2),
          dir3 = v2 + normalize(v3-v2);
    vec2  vm   = 0.5*(dir1+dir3) ;
    float dm   = UnSignedDistance( p, v2, vm ) ;

    if ( dm >= 0.0 )
           return SignedDistance( p, v1, v2 ) ;
       else
        return SignedDistance( p, v2, v3 ) ;
}
// -------------------------------------------------------------------------------
// Takes 'p0' to the group's fundamental region, returns its coordinates in that region

vec2 p6mm_ToFundamental( vec2 p0 )
{
    nMirrorOdd = 0 ;
    nMirror    = 0 ;

    // p1 = fragment coords. in the grid reference frame

    vec2 p1 = vec2( dot(p0,u_dual), dot(p0,v_dual) );

    // p2 = fragment coords in the translated grid reference frame

    vec2 p2 = vec2( fract(p1.x), fract(p1.y) ) ;

    nGridX = int(p1.x-p2.x) ; // largest integer g.e. to p1.x
    nGridY = int(p1.y-p2.y) ; // largest integer g.e. to p2.x

    // p3 = barycentric coords in the translated triangle
    // (mirror, using line x+y-1=0 as axis, when point is right and above axis)

    vec2 p3 = Mirror( p2, vec2(1.0,0.0), vec2(0.0,1.0) );

    // p4 = p3, but expressed back in cartesian coordinates

    vec2 p4 = p3.x*u + p3.y*v ;

    // p7 = mirror around the three lines through the barycenter, perp. to edges.

    vec2 p5 = Mirror( p4, vec2(0.5,0.0), tri_cen );
    vec2 p6 = Mirror( p5, vec2(1.0,0.0), tri_cen );
    vec2 p7 = Mirror( p6, tri_cen, vec2(0.0,0.0) );

    return p7 ;
}

// --------------------------------------------------------------------
// A possible distance function

float DistanceFunc( float d )
{
   return 1.0-smoothstep( line_w*0.5, line_w*1.5, d );
}

// -------------------------------------------------------------------------------
// Point color for basic symmetry lines in (r,g,b)

vec4 p6mm_SimmetryLines( vec2 p_ndc )
{

    vec2 pf = p6mm_ToFundamental( p_ndc );

    float d1 = abs(pf.y),
          d2 = abs(pf.x-0.5),
          d3 = abs( SignedDistance( pf, tri_cen, vec2(0.0,0.0) ) );

    vec4 res = vec4( 0.0, 0.0, 0.0, 1.0 ) ;

    res.r = DistanceFunc(d2);
    res.g = DistanceFunc(d1);
    res.b = DistanceFunc(d3);

    return res ;
}

// ---------------------------------------------------------------------
// Stripe half width for star pattern

vec4 Stripe( float d )
{
   if ( d > sw*0.85 )
     return vec4( 0.0,0.0,0.0,1.0 );
   else
     return vec4(1.0,1.0,1.0,1.0)  ;
}

// ---------------------------------------------------------------------
// Color for islamic star pattern

vec4 p6mm_pattern( vec2 p )
{
    vec2 pf = p6mm_ToFundamental( p );

    //return p6mm_SimmetryLines( p ) ;
    vec2 c  = tri_cen ;

    // constants defining the stripes
    float
        f   = 0.30 ,
        fs1 = 0.14 ,
        s1  = fs1*c.x,
        s2  = 0.5*s1 ;

    // stripes vertexes
    vec2
        // upper strip
        u1 = vec2( f*c.x, 0.0 ) ,
        u2 = vec2( c.x, (1.0-f)*c.y ),

        // lower strip
        l1 = vec2( c.x, s1+s2 ),
        l2 = vec2( c.x-s2, s1 ),
        l3 = vec2( sqr3*s1, s1 ),

        // right strip
        r1 = vec2( c.x-s1, (1.0-fs1)*c.y ),
        r2 = vec2( c.x-s1, s2 ) ,
        r3 = vec2( c.x-s1-s2, 0.0 ),

        // origin star strip
        mm = vec2( s1*(sqr3-1.0/3.0), s1*(1.0-sqr3_inv) );

    // signed and unsigned distances to stripes:

    float
        d1s = SignedDistance( pf, u1, u2 ) ,
        d2s = DoubleSignedDistance( pf, l1, l2, l3 ) ,
        d3s = DoubleSignedDistance( pf, r1, r2, r3 ) ,
        d4s = DoubleSignedDistance( pf, u1, mm, l3 ) ,
        d1  = abs( d1s ),
        d2  = abs( d2s ),
        d3  = abs( d3s ),
        d4  = abs( d4s );

    // stripes inclusion
    bool in1, in2, in3, in4 ;

    if ( nMirrorOdd == 0 )
    {
        in1 = (d1 < sw) && ! (d2 < sw) && ! (d4 < sw);
        in2 = (d2 < sw) && ! (d3 < sw);
        in3 = (d3 < sw) && ! (d1 < sw);

        in4 = (d4 < sw) && ! (d2 < sw);
    }
    else
    {
        in1 = (d1 < sw) && ! (d3 < sw) ;
        in2 = (d2 < sw) && ! (d1 < sw) && ! (d4 < sw);;
        in3 = (d3 < sw) && ! (d2 < sw);

        in4 = (d4 < sw) && ! (d1 < sw);
    }

    vec4 col ;

    // compute final color

    if ( in1 )
        col = Stripe( d1 ) ;
    else if ( in2 )
        col = Stripe( d2 ) ;
    else if ( in3 )
        col = Stripe( d3 ) ;
    else if ( in4 )
        col = Stripe( d4 ) ;
    else if ( d2s < 0.0 && d3s < 0.0 )
        col = vec4( 0.0, 0.4, 0.0, 1.0 ) ;
    else if ( d1s < 0.0 && d2s < 0.0 || d1s <0.0 && d3s < 0.0 )
        col = vec4( 0.1, 0.1, 0.1, 1.0 );
    else if ( d1s < 0.0 || d2s < 0.0 )
        col = vec4( 0.0, 0.4, 0.9, 1.0 );
    else
        col = vec4( 0.6, 0.0, 0.0, 1.0 ) ;

    return col ;
}
//-------------------------------------------------------------------------------------
bool lastInFundamental()
{
     return nGridX ==0  && nGridY == 0 && nMirrorOdd == 0 && nMirror == 0  ;
}
//-------------------------------------------------------------------------------------
vec4 p6mm_patterns_sum( vec2 p )
{

    const float t   = 30.0 ; // time units for each rotation (period)
    float       a   = (time*2.0*pi)/t,
                ca  = cos(a),
                sa  = sin(a),
                s   = 3.5 + 3.0*sin( time/2.0 );
    mat2        rot = mat2( ca, -sa, sa, ca );
    vec2        d   = 0.001*vec2( time, 0.2*time );

    return p6mm_pattern( s*rot*(d+p) );
}

//-------------------------------------------------------------------------------------
vec4 AA_pixel_color( in vec2 pixel_coords )
{
    vec4        sum    = vec4( 0.0, 0.0, 0.0, 1.0 );
    const float n      = float(n_aa);
    const vec2  c      = vec2( 0.5, 0.5 );
    float       scale  = xfrec/resolution.x ;

    for( int i = 0 ; i < n_aa ; i++ )
    for( int j = 0 ; j < n_aa ; j++ )
    {
       vec2 samplep = pixel_coords + 1.0001*(c+vec2(i,j)/n) ;
       sum = sum + p6mm_patterns_sum( scale*(samplep-0.5*resolution.xy) ); ;
    }
    return sum/(n*n);
}

//-------------------------------------------------------------------------------------
void main(void)
{
    glFragColor = AA_pixel_color( gl_FragCoord.xy ) ;
    //glFragColor = p6mm_pattern( 0.001*gl_FragCoord.xy );
}
