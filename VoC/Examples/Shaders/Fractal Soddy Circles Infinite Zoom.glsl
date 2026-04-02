#version 420

// original https://www.shadertoy.com/view/ddyGRd

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

struct Circle
{
    vec2 p;
    float r;
};

// inversions use the unit circle
Circle invert( Circle c )
{
    return Circle( c.p/(dot(c.p,c.p) - c.r*c.r), c.r/(dot(c.p,c.p) - c.r*c.r) );
}
vec2 invert( vec2 p )
{
    return p/dot(p,p);
}

vec3 color( float i )
{
    return sin( i + vec3(0,2,4) )*.4 + .6;
}

//aa,bb,cc counterclockwise
int soddy( vec2 p, inout Circle aa, inout Circle bb, inout Circle cc )
{
    // rotate so that a.y == b.y
    vec2 dif = bb.p - aa.p;
    mat2 m = mat2( dif.x, -dif.y, dif.y, dif.x ) / length( dif );
    Circle a = Circle( m * aa.p, aa.r );
    vec2 d = a.p + vec2( a.r, 0. ); // d = point of inversion (where a, b meet)
    a.p -= d;
    Circle b = Circle( m * bb.p - d, bb.r );
    Circle c = Circle( m * cc.p - d, cc.r );
    p = m * p - d;
    
    Circle invC = invert( Circle( c.p, c.r ) );
    Circle invE = Circle( invC.p + vec2(0., invC.r*2.), invC.r );
    Circle e = invert( invE );    
    Circle ee = Circle( inverse( m ) * ( e.p + d ), e.r );
    
    if ( invert(p).y < invC.p.y )
        return -1; // p is not between aa,bb,cc
    if ( distance( invert(p), invE.p ) < invE.r )
        return 0;
    if ( invert(p).y >= invE.p.y ) cc = ee;
    else if ( invert(p).x > invC.p.x ) aa = ee;
    else bb = ee;
    return 1;
}

int go( vec2 p, Circle a, Circle b, Circle c )
{    
    int ct = 4;
    
    while ( ct <= 30 )
    {
        int sod = soddy( p, a, b, c );
        if ( sod == -1 )
            return -1;
        if ( sod == 0 )
            return ct;            
        ct += sod;
    }
    
    return -1;
}

vec2 cos_sin( float angle )
{
    return vec2( cos( angle ), sin( angle ) );
}

const float PHI = .5 + sqrt( 1.25 );
const float ITERATION_SCALE = PHI + sqrt( PHI ); // 2.89005...

void main(void)
{
    vec2 p = (gl_FragCoord.xy*2.-resolution.xy)/resolution.y;
    
    float zoom_factor = time * 3.;
    float algo_zoom = floor( zoom_factor );
    zoom_factor = fract( zoom_factor );
    
    p *= pow( 1./ITERATION_SCALE, zoom_factor ) * .4;
    
    float start = -algo_zoom;
    
    vec2 a = cos_sin( (-algo_zoom + 0.) * 2.2370357592874117 ) * pow( ITERATION_SCALE, 0. );
    vec2 b = cos_sin( (-algo_zoom + 1.) * 2.2370357592874117 ) * pow( ITERATION_SCALE, 1. );
    vec2 c = cos_sin( (-algo_zoom + 2.) * 2.2370357592874117 ) * pow( ITERATION_SCALE, 2. );
    
    float ra = (distance(b, a) + distance(a, c) - distance(c, b)) / 2.;
    float rb = (distance(c, b) + distance(b, a) - distance(a, c)) / 2.;
    float rc = (distance(a, c) + distance(c, b) - distance(b, a)) / 2.;
    
    
    int hit = -4;
    if ( distance( p, a ) < ra )      hit = 3;
    else if ( distance( p, b ) < rb ) hit = 2;
    else if ( distance( p, c ) < rc ) hit = 1;
    else hit = go( p, Circle( a, ra ), Circle( b, rb ), Circle( c, rc ) );
    
    
    glFragColor = vec4(0,0,0,1);
    if ( hit < 0 )
        return;
    glFragColor = vec4( color( (float(hit) - start)*0.5 ), 1. );
}
