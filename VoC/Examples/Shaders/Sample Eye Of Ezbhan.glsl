#version 420

// original https://www.shadertoy.com/view/td3Xzr

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define THETA 2.399963229728653 //THETA is the golden angle in radians: 2 * PI * ( 1 - 1 / PHI )
vec2 spiralPosition(float t)
{
    float angle = t * THETA - time * .001; 
    float radius = ( t + .5 ) * .5;
    return vec2( radius * cos( angle ) + .5, radius * sin( angle ) + .5 );
}

void main(void)
{
    vec2 uv = ( gl_FragCoord.xy - .5 * resolution.xy ) / resolution.y * 1024.;
    float a = 0.;
    float d = 50.;
    for(int i = 0; i < 256; i++)
    {
        vec2 pointDist = uv - spiralPosition( float(i) ) * 6.66;
        a += atan( pointDist.x, pointDist.y );
        d = min( dot( pointDist, pointDist ), d );
    }
    d = sqrt( d ) * .02;
    d = 1. - pow( 1. - d, 32. );
    a += sin( length( uv ) * .01 + time * .5 ) * 2.75;
    vec3 col  = d * (.5 + .5 * sin( a + time + vec3( 2.9, 1.7, 0 ) ) );
    //col   = d * smoothstep( .75, 1.0, vec3( .5 + .5 * sin( a + time * -1. ) ) );
    glFragColor = vec4( col, 1. );
}
