#version 420

// original https://www.shadertoy.com/view/ls2XRh

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

mat2 mm2(in float a){float c = abs( cos(a) ), s = sin(a);return mat2(c,-s,s,c);}

float aspect;
const float pi = 3.14159265;
const float halfpi = pi * 0.5;
const float oneoverpi = 1.0 / pi;

float saturate( float a )
{
    return clamp( a, 0.0, 1.0 );
}

//
// Fractional Brownian Motion code by IQ.

float noise( float x, float y )
{
    return sin(1.5*x)*sin(1.5*y);
}

const mat2 m = mat2( 0.80,  0.60, -0.60,  0.80 );
float fbm4( float x, float y )
{
    vec2 p = vec2( x, y );
    float f = 0.0;
    f += 0.5000*noise( p.x, p.y ); p = m*p*2.02;
    f += 0.2500*noise( p.x, p.y ); p = m*p*2.03;
    f += 0.1250*noise( p.x, p.y ); p = m*p*2.01;
    f += 0.0625*noise( p.x, p.y );
    return f/0.9375;
}

//

//
// Fluctuation code based on http://glsl.heroku.com/e#9824.11

#define MAX_ITER 7
void main( void ) 
{
    aspect = resolution.x/resolution.y;

    float scale = 3.0;
    
    vec2 mainuv = ( gl_FragCoord.xy / resolution.xy );
    vec2 uv = mainuv * scale - scale * 0.5;
    uv.x = abs( uv.x );
    uv.x *= aspect;
    vec2 i = uv;
    float finalval = 0.0;
    float inten = 1.0;
    
    //float facet = atan( uv.x, uv.y );
    
    float lengthUV = length( uv );
    
    float scaledLength = lengthUV * 20.0;
    float core = time + fract( scaledLength ) * fract( -scaledLength );

    //uv = uv * mm2( scaledLength );
    
    for (int n = 0; n < MAX_ITER; n++) 
    {
        float s = 1.0 - saturate( float( n ) / float( MAX_ITER ) );
        float t = ( 1.0 - s );
        i = ( uv + vec2(
            atan( t - i.y, t + time ) + cos( t + i.y - core ), 
            sin( t - i.x + core ) + atan( t + i.x, t + time )
        )) - ( i - ( 1.0 / vec2( n + 1 ) ) );
        float val = dot( uv, i );
        finalval = max( finalval, ( lengthUV * 0.0001 / ( s * s ) ) / ( val * val * s ) );
    }
    
    finalval = saturate( finalval );
    
    float vignette = 1.0 - saturate( lengthUV * lengthUV * 0.11 );
    finalval *= vignette;
    
    finalval = max( finalval, 0.0 ) + 0.0025;
    finalval = min( finalval, 1.0 );

    vec3 finalColor = vec3(finalval);// * mix( vec3( 0.95, 0.97, 2.2 )
                           //         , vec3( 0.95, 0.97, 1.2 ), saturate( length( i ) ) );
    finalColor = pow( finalColor, vec3( 1.0 / 2.2 ) );
    glFragColor = vec4( finalColor, 1.0);
}
