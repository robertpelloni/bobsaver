#version 420

// original https://www.shadertoy.com/view/XsfcWs

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define DIM 1024.0

float red( in float i, in float j ) {
    i *= 1.5;    
    j = resolution.y - j;
        float s = 3. / ( j + 200. );
        float y = ( j + sin(( i * i + ( j - 700. ) * ( j - 700. ) * 5. ) / 100. / DIM + 1.5 * time ) * 35. ) * s;
        return ( mod( floor( ( i + DIM ) * s + y), 2. ) + mod( floor( ( DIM * 2. - i ) * s + y ), 2. ) ) * 127.;
}
float green( in float i, in float j ) {
    i *= 1.5;    
    j = resolution.y - j;    
        float s = 3. / ( j + 200. );    
    float y = ( j + sin( ( i * i + ( j - 700. ) * ( j - 700. ) * 5. ) / 100. / DIM + 1.5 * time ) * 35. ) * s;
    return ( mod( floor( 5. * ( ( i + DIM ) * s + y ) ), 2. ) + mod( floor( 5. * ( ( DIM * 2. - i ) * s + y ) ), 2. ) ) * 127.;    
}
float blue( in float i, in float j ) {
    i *= 1.5;    
    j = resolution.y - j;    
        float s = 3. / ( j + 200. );    
    float y = ( j + sin( ( i * i + ( j - 700. ) * ( j - 700. ) * 5. ) / 100. / DIM + 1.5 * time ) * 35. ) * s;
    return ( mod( floor( 29. * ( ( i + DIM ) * s + y ) ), 2. ) + mod( floor( 29. * ( ( DIM * 2. - i ) * s + y ) ), 2. ) ) * 127.;
}

void main(void)
{
    float x = gl_FragCoord.xy[0];
    float y = gl_FragCoord.xy[1];    
    glFragColor = vec4( red( x, y )/255., green( x, y )/255., blue( x, y )/255., 1. );    
}
