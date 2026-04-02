#version 420

// original https://www.shadertoy.com/view/Nsd3RH

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float circle( vec2 tr , float r ) {
    float v = abs( r - tr.y ) ;
    return 1.0 - smoothstep( 0.0 , 0.005 , v ) ;
}

#define PI 3.14159265

float angle( vec2 uv ) {
    vec2 id = vec2( 1.0 , 0 ) ;
    float a = acos( dot( uv , id ) / ( length( uv ) * length( id ) ) ) ;
    if ( uv.y < 0.0 ) a = 2.0 * PI - a ;
    return a ;
}

void main(void) {
    // Normalized pixel coordinates
    vec2 uv = ( gl_FragCoord.xy - 0.5 * resolution.xy) / resolution.y ;
    // polar coordinates
    vec2 tr = vec2( angle( uv ) , length( uv ) ) ;
    
    float c = 0.0 ;
    
    // haha this is a terrible idea
    const float N = 1200.0 ;
    
    for ( float i = 0.0 ; i > -N ; i -- ) {
        float T = time + i * 0.003 ;
        float radius = ( 0.35 // base
                     + ( 0.08 * sin( T * 1.5  ) ) ) // in/out
                     * ( 1.0 + 0.15 * sin( tr.x  * 10.0 - ( T * 5.0 ) ) ) ; // wobbles
        c = max( c , circle( tr , radius ) + i / N ) ;
    }
    
    vec3 col = vec3(
        sin( tr.x + time            ) / 2.5 + 0.8 ,
        sin( tr.x + time + PI / 0.8 ) / 2.5 + 0.8 ,
        sin( tr.x + time + PI / 1.5 ) / 2.5 + 0.8
    ) * c ;
    
    //col = vec3( angle( uv ) / 4.0 ) ;

    // Output to screen
    glFragColor = vec4( col , 1.0 ) ;
}
