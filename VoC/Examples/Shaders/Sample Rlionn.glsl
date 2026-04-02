#version 420

// original https://www.shadertoy.com/view/MsjSRh

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float BaseIterations = 25.0;
const float BaseAngleCorrected = 1.0 / BaseIterations * 6.2831 * 0.25;

float aspect;

mat2 mm2(in float a){float c = abs( cos(a) ), s = sin(a);return mat2(c,-s,s,c);}

float PI = 3.14159265;

float saturate( float a )
{
    return clamp( a, 0.0, 1.0 );
}

//
// Fractional Brownian Motion code by IQ.

float noise( in vec2 x )
{
    return sin(1.5*x.x)*sin(1.5*x.y);
}

const mat2 m = mat2( 0.80,  0.60, -0.60,  0.80 );
float fbm4( vec2 p )
{
    float f = 0.0;
    f += 0.5000*noise( p ); p = m*p*2.02;
    f += 0.2500*noise( p ); p = m*p*2.03;
    f += 0.1250*noise( p ); p = m*p*2.01;
    f += 0.0625*noise( p );
    return f/0.9375;
}

//

float bendmind( inout vec2 uv )
{
    float mainval = 0.0;
    for(float i=0.;i<BaseIterations;i++)
    {
        float ref = ( cos( time * 0.25 + atan( uv.x, uv.y ) ) );
        
        float val = ref * fbm4( uv + time * 0.25 );

        mainval = max( mainval, 0.00001 / ( val * val ) );
        
        uv *= mm2( ( 1.0 + cos( time * 0.5 ) * 0.5 ) * BaseAngleCorrected );
    } 
    
    return mainval; 
}

void main(void)
{
    aspect = resolution.x/resolution.y;

    float scale = 3.0;
    
    vec2 mainuv = ( gl_FragCoord.xy / resolution.xy );
    vec2 uv = mainuv * scale - scale * 0.5;
    uv.x *= aspect;
    uv.x = abs( uv.x );
    
    float lengthUV = length( uv );
    float vignette = 1.0 - pow( saturate( lengthUV * 0.9 ), 2.0 );
    float vignetteThird = saturate( lengthUV * 3.0 );
    vignette *= vignetteThird;
    
    uv += lengthUV * 0.5;

    vec3 col = vec3( 0.0 );
    float mainval = vignette > 0.001 ? saturate( bendmind( uv ) ) * vignette : 0.0;
    
    mainval = max( mainval, 0.0 ) + 0.0025;
    mainval = min( mainval, 1.0 );

    glFragColor = vec4( vec3( pow( mainval, 1.0 / 2.2 ) ), 1.0 );
}
