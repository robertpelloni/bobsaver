#version 420

// original https://www.shadertoy.com/view/XlK3DD

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define V1 float
#define V2 vec2
#define V3 vec3
#define V4 vec4

#define T time
#define R resolution.xy
#define D ( 1. / R )

V1 amp = .50;
V1 count = 4.;
V4 rct = V4( -6.28, -3., 2. * 6.28, 5. );

V2 cvt( V2 p ) { return rct.xy + ( p * D ) * rct.zw; }

V1 fct( V1 x, int id, float count ) {
    
    return
        id < 2
            ? id < 1
                ? +0.5 + amp * cos( 30. * x * sin( .15 * T ) ) * exp( -.125 * x * x )
                : -0.5 + amp * sin( 30. * x * cos( .17 * T ) ) * exp( -.125 * x * x )
            : id < 3
                ? -2.0 + amp * (
                    cos( 30. * x * sin( .15 * T ) ) * exp( -.125 * x * x ) -
                    sin( 30. * x * cos( .17 * T ) ) * exp( -.125 * x * x ) )
                : +1.5 + amp *
                    ( + cos( 30. * x * sin( .15 * T ) ) * exp( -.125 * x * x ) ) *
                    ( + sin( 30. * x * cos( .17 * T ) ) * exp( -.125 * x * x ) );
}

V4 plt( V2 p, int id, float count ) {
    
    V1 f0 = fct( p.x ,id, count );
    
    V2 df = V2( D.x, .125 * ( fct( p.x + 4. * D.x, id, count ) - fct( p.x - 4. * D.x, id, count ) ) ),
       dy = V2( 0, p.y - f0 ),
       p1 = p - V2( p.x, f0 ) - df * dot( df, dy ) / dot( df, df );
    
    V1 l = length( p1 );
    
    return smoothstep( 1., 0., l * .1 * R.y ) * (
        id < 2
            ? id < 1
                ? V4( 1., 0., 0.,  1. )
                : V4( 0., 1., 0.,  1. )
            : id < 3
                ? V4( 1., 1., 0.,  1. )
                : V4( .5, .75, 1.,  1. )
        );
}

void main(void) { //WARNING - variables void ( out V4 o, V2 i ) { need changing to glFragColor and gl_FragCoord.xy
    
    vec2 i = cvt( gl_FragCoord.xy );
    
    vec4 o = plt( i, 0, count );
        
    for( int j = 1; j < int( count ); ++ j ) {
        
        o += plt( i, j, count );
    }

    glFragColor = o;
}
