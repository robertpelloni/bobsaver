#version 420

// original https://www.shadertoy.com/view/Md2yWR

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// "A Spiral of Circles" by Krzysztof Narkowicz @knarkowicz

const float MATH_PI    = float( 3.14159265359 );

void Rotate( inout vec2 p, float a ) 
{
    p = cos( a ) * p + sin( a ) * vec2( p.y, -p.x );
}

float saturate( float x )
{
    return clamp( x, 0.0, 1.0 );
}

void main(void)
{    
    vec2 uv = gl_FragCoord.xy / resolution.xy;    
    vec2 p;
    p.x = ( 2.0 * ( gl_FragCoord.x / resolution.x ) - 1.0 ) * 1000.0;
    p.y = ( -2.0 * ( gl_FragCoord.y / resolution.y ) + 1.0 ) * 1000.0 * ( resolution.y / resolution.x );
    
    float sdf = 1e6;
    float dirX = 0.0;
    for ( float iCircle = 1.0; iCircle < 16.0 * 4.0 - 1.0; ++iCircle )
    {
        float circleN = fract( ( iCircle / ( 16.0 * 4.0 - 1.0 ) ) );
        float t = fract( circleN + time * 0.2 );
        
        float offset = -180.0 - 330.0 * t;
        float angle  = fract( iCircle / 16.0 + time * 0.01 + circleN / 8.0 );
        float radius = mix( 1.0 - saturate( 1.2 * ( 1.0 - abs( 2.0 * t - 1.0 ) ) ), 1.0, 50.0 ) - 1.0;
        
        vec2 p2 = p;
        Rotate( p2, angle * 2.0 * MATH_PI );
        p2 += vec2( -offset, 0.0 );
        
        float dist = length( p2 ) - radius;
        if ( dist < sdf )
        {
            dirX = p2.x / radius;
            sdf     = dist;
        }
    }
    
    vec3 colorA = vec3( 24.0, 30.0, 28.0 );
    vec3 colorB = vec3( 249.0, 249.0, 249.0 );
    
    vec3 abberr = colorB;
    abberr = mix( abberr, vec3( 205.0, 80.0, 28.0 ), saturate( dirX ) );
    abberr = mix( abberr, vec3( 38.0, 119.0, 208.0 ), saturate( -dirX ) );
    
    colorB = mix( colorB, abberr, smoothstep( 0.0, 1.0, saturate( ( sdf + 5.0 ) * 0.1 ) ) );
    
    vec3 color = mix( colorA, colorB, vec3( 1.0 - smoothstep( 0.0, 1.0, sdf * 0.3 ) ) );
    glFragColor = vec4( color / 255.0, 1.0 );
}
