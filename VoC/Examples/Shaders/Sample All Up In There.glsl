#version 420

// original https://www.shadertoy.com/view/WlKyDt

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

        /////////////////////////////////////////////////////////////////
       //                                                            ////
      //  "All Up in There"                                         // //
     //                                                            //  //
    //  I'd been wanting to make a tunnel demo for a while and    //   //
   //  stumbled onto an organic shape that pairs nicely with     //    //
  //  the natural look of the voronoi.                          //    //
 //                                                            //     //
////////////////////////////////////////////////////////////////     //
//                                                            //    //
// Creative Commons Attribution-NonCommercial-ShareAlike      //   //
// 3.0 Unported License                                       //  //
//                                                            // //
// by Val "valalalalala" GvM 💃 2021                          ////
//                                                            ///
////////////////////////////////////////////////////////////////

vec2 hash22( in vec2 uv ) {
    vec3 q = fract( uv.xyx * vec3( 19.191, 53.733, 73.761 ) );
    q += dot( q, q + vec3( 41.557, 23.929, 37.983 ) );
    return fract( vec2( q.x * q.y, q.y * q.z ) );
}

vec2 hash( vec2 x ) {  return hash22( x );}

// iq

float noise( in vec2 p )
{
    vec2 i = floor( p );
    vec2 f = fract( p );
    
    vec2 u = f*f*(3.0-2.0*f);

    return mix( mix( dot( hash( i + vec2(0.0,0.0) ), f - vec2(0.0,0.0) ), 
                     dot( hash( i + vec2(1.0,0.0) ), f - vec2(1.0,0.0) ), u.x),
                mix( dot( hash( i + vec2(0.0,1.0) ), f - vec2(0.0,1.0) ), 
                     dot( hash( i + vec2(1.0,1.0) ), f - vec2(1.0,1.0) ), u.x), u.y);
}

/////

// from my https://www.shadertoy.com/view/wtKcRy
// alternative distance metrics

#define MANHATTAN
#define DOTTY_

// alternative voronoi combinations
#define FBM_
#define IFBM_

// for some reason... mix isn't working for me...
#define MIX(x,y,a)   ((1.-a) * x + y * a)
#define MIX2(x,y,a)  mix(x,y,a)
#define USE_MIX_INSTEAD_OF_IFS_NOT

////////////////////////////////////////////////////////////////

#define MAP_11_01(v)     ( v * .5 + .5 )

////////////////////////////////////////////////////////////////
// functions 

vec4 makeVoronoiPoint( in vec2 id, float time ) {
    vec2 n = hash22( id ) ;
    vec2 point = sin( n * time ) * .5 + .5;
    return vec4( point.xy, n.xy );
}

float voronoiDistanceMetric( in vec2 st ) {
    #ifdef MANHATTAN
    return abs( st.x ) + abs( st.y );
    #endif
    
    #ifdef DOTTY
    st = abs( st );
    return dot( st, st ) / ( st.x + st.y );
    #endif
   
    return length( st );
}

vec3 calculateVoronoiDistance( in vec2 st, in vec2 id, in vec2 neighbor, float time ) {
    vec4 voronoiPoint = makeVoronoiPoint( id + neighbor, time );
    st -= voronoiPoint.xy + neighbor;
    
    float d = voronoiDistanceMetric( st );

    return vec3( d, voronoiPoint.xy );
    return vec3( d, id );
}

vec3 calculateVoronoiPoint( in vec2 st, in vec2 id, float time ) {
    vec3 voronoi_n1_n1 = calculateVoronoiDistance( st, id, vec2( -1., -1. ), time );
    vec3 voronoi_n1_n0 = calculateVoronoiDistance( st, id, vec2( -1., -0. ), time );
    vec3 voronoi_n1_p1 = calculateVoronoiDistance( st, id, vec2( -1., +1. ), time );
    vec3 voronoi_n0_n1 = calculateVoronoiDistance( st, id, vec2( -0., -1. ), time );
    vec3 voronoi_n0_n0 = calculateVoronoiDistance( st, id, vec2( -0., -0. ), time );
    vec3 voronoi_n0_p1 = calculateVoronoiDistance( st, id, vec2( -0., +1. ), time );
    vec3 voronoi_p1_n1 = calculateVoronoiDistance( st, id, vec2( +1., -1. ), time );
    vec3 voronoi_p1_n0 = calculateVoronoiDistance( st, id, vec2( +1., -0. ), time );
    vec3 voronoi_p1_p1 = calculateVoronoiDistance( st, id, vec2( +1., +1. ), time );

    vec3 closest = vec3( 1e33 );
#ifdef USE_MIX_INSTEAD_OF_IFS
    closest = MIX( closest, voronoi_n1_n1, step( voronoi_n1_n1.x, closest.x ) );
    closest = MIX( closest, voronoi_n1_n0, step( voronoi_n1_n0.x, closest.x ) );
    closest = MIX( closest, voronoi_n1_p1, step( voronoi_n1_p1.x, closest.x ) );
    closest = MIX( closest, voronoi_n0_n1, step( voronoi_n0_n1.x, closest.x ) );
    closest = MIX( closest, voronoi_n0_n0, step( voronoi_n0_n0.x, closest.x ) );
    closest = MIX( closest, voronoi_n0_p1, step( voronoi_n0_p1.x, closest.x ) );
    closest = MIX( closest, voronoi_p1_n1, step( voronoi_p1_n1.x, closest.x ) );
    closest = MIX( closest, voronoi_p1_n0, step( voronoi_p1_n0.x, closest.x ) );
    closest = MIX( closest, voronoi_p1_p1, step( voronoi_p1_p1.x, closest.x ) );
#else
    if ( voronoi_n1_n1.x < closest.x ) closest = voronoi_n1_n1;
    if ( voronoi_n1_n0.x < closest.x ) closest = voronoi_n1_n0;
    if ( voronoi_n1_p1.x < closest.x ) closest = voronoi_n1_p1;
    if ( voronoi_n0_n1.x < closest.x ) closest = voronoi_n0_n1;
    if ( voronoi_n0_n0.x < closest.x ) closest = voronoi_n0_n0;
    if ( voronoi_n0_p1.x < closest.x ) closest = voronoi_n0_p1;
    if ( voronoi_p1_n1.x < closest.x ) closest = voronoi_p1_n1;
    if ( voronoi_p1_n0.x < closest.x ) closest = voronoi_p1_n0;
    if ( voronoi_p1_p1.x < closest.x ) closest = voronoi_p1_p1;
#endif
    return closest;
}

float vornoing( in vec2 uv, float scale, float time ) {
    uv *= scale;
    
    vec2 st = fract( uv );
    vec2 id = uv - st;

    vec3 closest = calculateVoronoiPoint( st, id, time );
    return closest.x;
}

float voronoi( vec2 uv, float time ) {
    float s = 1.;
    #ifdef FBM
    return .0
        + .1 * vornoing( uv + 33. * s,  1., time )
        + .2 * vornoing( uv + 17. * s,  3., time )
        + .3 * vornoing( uv +  9. * s,  7., time )
        + .4 * vornoing( uv +  5. * s, 13., time )
    ;
    #endif

    #ifdef IFBM
    return .0
        + .4 * vornoing( uv + 33. * s,  1., time )
        + .3 * vornoing( uv + 17. * s,  3., time )
        + .2 * vornoing( uv +  9. * s,  7., time )
        + .1 * vornoing( uv +  5. * s, 13., time )
    ;
    #endif

    return vornoing( uv, 7., time );
}

vec3 voronoi( vec3 p, float time ) {
    return vec3(
        voronoi( MAP_11_01( p.yz ), time ),
        voronoi( MAP_11_01( p.zx ), time ),
        voronoi( MAP_11_01( p.xy ), time )
    );
}

////

#if 1

const int CHARACTERS[14] = int[14](31599,9362,31183,31207,23524,29671,29679,30994,31727,31719,1488,448,2,3640);

float digitIsOn( int digit, vec2 id ) {   
    if ( id.x < .0 || id.y < .0 || id.x > 2. || id.y > 4. ) return .0;
    return floor( mod( float( CHARACTERS[ int( digit ) ] ) / pow( 2., id.x + id.y * 3. ), 2. ) );
}

float digitSign( float v, vec2 id ) {
    return digitIsOn( 10 - int( ( sign( v ) - 1. ) * .5 ), id );
}

int digitCount( float v ) {
    return int( floor( log( max( v, 1. ) ) / log( 10. ) ) );
}

float digitFirst( vec2 uv, float scale, float v, int decimalPlaces ) {
    vec2 id = floor( uv * scale );

    if ( .0 < digitSign( v, id ) ) return 1.;
    v = abs( v );
    
    int digits = digitCount( v );
    float power = pow( 10., float( digits ) );
    
    float offset = floor( .1 * scale );
    id.x -= offset;
    
    float n;
    for ( int i = 0 ; i < 33 ; i++, id.x -= offset, v -= power * n, power /= 10. ) {
        n = floor( v / power );
        if ( .0 < digitIsOn( int( n ), id ) ) return 1.;   
        if ( i == digits ) {
            id.x -= offset;
            if ( .0 < digitIsOn( int( 12 ), id ) ) return 1.;
        }  
        if ( i >= digits + decimalPlaces ) return .0;    
    }  
    return .0;
}

float digitFirst( vec2 uv, float scale, float v ) {
    return digitFirst( uv, scale, v, 3 );
}

vec3 digitIn( vec3 color, vec3 fontColor, vec2 uv, float scale, float v ) {
    float f = digitFirst( uv, scale, v );
    return mix( color, fontColor, f );
}

vec3 digitIn( vec3 color, vec2 uv, float scale, float v ) {
    return digitIn( color, vec3(1.), uv, scale, v );
}

#endif

///////////////////////////////////////////////////////////////////
// scene controls

////////////////////////////////////////////////////////////////
// handy constants

#define ZED   .0
#define TAU   6.283185307179586

////////////////////////////////////////////////////////////////
// ray marching

#define STEPS 55
#define CLOSE .001
#define FAR   55.
#define EPZ   vec2( ZED, CLOSE )

////////////////////////////////////////////////////////////////

#define FROM_SCREEN(uv)  ( ( 2. * uv - resolution.xy ) / resolution.y )

#define TRIG(a)    vec2( cos( a  * TAU ), sin( a * TAU ) )
#define MIN3(v)    min( v.x, min( v.y, v.z ) )
#define MAX3(v)    max( v.x, max( v.y, v.z ) )
#define SUM3(v)    ( v.x + v.y + v.z )
#define AVG3(v)    ( SUM3(v)/3. )
#define SUM2(v)    ( v.x + v.y )
#define MODO(v,f)  ( mod( v + .5 * f, f ) - .5 * f )
#define RGB        vec3

////////////////////////////////////////////////////////////////

float getDistance( vec3 p, vec3 a ) {
    p.x/=.66;
    float n = noise( p.xy );
    
    p.z += n * 4.4;
    vec2 t = TRIG( p.z );
    vec2 c = TRIG( p.z * .33 ) * .33;
    float r = SUM2( abs( t ) ) * .1 + .33;
    float cylinder = length( p.xy - c ) - r;
    float tunnel = -cylinder;
    
    float fudge = .7;
    return tunnel * fudge;
}

////////////////////////////////////////////////////////////////

float march( vec3 a, vec3 ab ) {
    float d = .0;
    for ( int i = 0 ; i < STEPS ; i++ ) {
        vec3 b = a + d * ab;
        float n = getDistance( b, a );
        d += n;
        if ( abs( n ) < CLOSE || d > FAR ) break;
    }
    return d;
}

vec3 getDistances( vec3 a, vec3 b, vec3 c, vec3 q ) {
    return vec3( getDistance( a,q ), getDistance( b,q ), getDistance( c,q ) );
}

vec3 getNormal( vec3 p,vec3 a ) {
    return normalize( getDistance( p, a ) - 
        getDistances( p - EPZ.yxx, p - EPZ.xyx, p - EPZ.xxy, a )
    );
}

////////////////////////////////////////////////////////////////

// zab,xZup,yXz | zxy:ab,zup,xz
mat3 makeCamera( vec3 a, vec3 b, float roll ) {
    vec3 up = vec3( TRIG( roll ).yx, ZED );
    vec3 z = normalize( b - a );
    vec3 x = normalize( cross( z, up ) );
    vec3 y = normalize( cross( x, z ) );
    return mat3( x, y, z );
}

////////////////////////////////////////////////////////////////

float checked( vec2 uv, float scale ) {
    vec2 st = floor( uv * scale );
    return mod( st.x + st.y, 2. );
}

vec3 texaco( vec2 uv ) {
    return mix( vec3( .7, .7, .9 ), vec3( .9, .9, .7 ), checked( uv, 33. ) );
}

#define SALMON_PINK     RGB( 1.0, .55, .60 )
#define BRINK_PINK      RGB( 1.0, .34, .45 )
#define HOT_PINK        RGB( 1.0, .40, .70 )
#define BUBBLEGUM_PINK  RGB( 1.0, .80, .80 )
#define RUDDY_PINK      RGB( .83, .57, .57 )
            
vec3 colorHit( vec3 p, vec3 a ) {
    vec3 n = getNormal( p, a );
    
    vec3 q = abs( n );
    
    float l1 = pow( min( q.x, q.y ), .02 );
    float l2 = pow( MAX3( q ), .44 );
    float l3 = .2 + pow( MIN3( q ), .11 );
    vec3 light = vec3( l1, l2, l3 ) * normalize( vec3( .3, .8, .5 ) ) * .77;
    float l = SUM3( light );

    ////
    
    #if 0
        n = pow( abs(n), vec3( 4. ) );
        n /= SUM3( n ); // pseudo normalize
    
        vec3 tX = texaco( MAP_11_01( p.yz ) );
        vec3 tY = texaco( MAP_11_01( p.xz ) );
        vec3 tZ = texaco( MAP_11_01( p.xy ) );
        vec3 color = ( n.x * tX + n.y * tY + n.z * tZ );
    #else
        vec3 color = voronoi( p * 2.77,  time );
        float m = 1. * ( cos( time * .66 ) * .5 + .5 );
        color = mix(
            BRINK_PINK,
            SALMON_PINK,
            pow( MIN3( color ) / 3.3, m )
        );
    #endif

    return l * color;
}

vec3 colorMiss( in vec2 uv ) {
    return .4 * texaco( MAP_11_01( uv * .5 ) );
}

void main(void) {
    vec2 uv = FROM_SCREEN( gl_FragCoord.xy );
    float view = 4.;
    float zoom = 2.;
    
    ////////////////////////////////////////////////////////////////
    
    bool mouseDown = false;//mouse*resolution.xy.z > .0;
    float roll = 0.0; //mouseDown ? .0 : 2.2 * cos( time * .11 );
    
    vec2 ms =  vec2(0.0);//mouse*resolution.xy.xy / resolution.xy * 1. - .5;
    
    vec2 t = view * TRIG( ms.x );
    float by = view * sin( TAU * ms.y * .66 );
    
    vec3 a = vec3( .0, .0, time  );
    vec3 b = a + vec3( -t.y, by, t.x );      
    
    vec3 ab = normalize( makeCamera( a, b, roll ) * vec3( uv, zoom ) );
    
    ////////////////////////////////////////////////////////////////

    float d = march( a, ab );
    float hit = step( d, FAR );

    vec3 p = hit * ( a + ab * d );
    
    ////////////////////////////////////////////////////////////////
    
    vec3 color = mix( colorMiss( uv ), colorHit( p, a ), hit );
    
    ////////////////////////////////////////////////////////////////
    
    float diz = d / FAR;
    float foginess = pow( diz, .233 ) * hit;
    vec3 fog = vec3( .22, .22, .4 );
    color = mix( color, fog, foginess );
    color *= 1.-pow(diz,.33);

    #if 0
    color = digitIn( color, uv - vec2(.8,.8), 44., ms.x );
    color = digitIn( color, uv - vec2(.8,.6), 44., ms.y );
    #endif
    
    ////////////////////////////////////////////////////////////////
    
    glFragColor = vec4( color, 1. );
}

// EOF
////////////////////////////////////////////////////////////////
