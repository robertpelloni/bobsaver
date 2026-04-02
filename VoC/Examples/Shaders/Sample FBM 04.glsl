#version 420

// original https://www.shadertoy.com/view/4sVfzd

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float hash( vec2 a )
{

    return fract( sin( a.x * 3433.8 + a.y * 3843.98 ) * 45933.8 );

}

float noise( vec2 uv )
{
    
    vec2 lv = fract( uv );
    lv = lv * lv * ( 3.0 - 2.0 * lv );
    vec2 id = floor( uv );
    
    float bl = hash( id );
    float br = hash( id + vec2( 1, 0 ) );
    float b = mix( bl, br, lv.x );
    
    float tl = hash( id + vec2( 0, 1 ) );
    float tr = hash( id + vec2( 1 ) );
    float t = mix( tl, tr, lv.x );
    
    float c = mix( b, t, lv.y );
    
    return c;

}

float fbm( vec2 uv )
{
    
    vec2 mou = mouse*resolution.xy.xy / resolution.y;

    float f = noise( uv * 4.0 );
    f += noise( uv * 8.0 ) * 0.5;  
    f += noise( uv * 16. ) * 0.25; 
    f += noise( uv * 32. ) * 0.125; 
    f += noise( uv * 64. ) * 0.0625;
    f /= 2.0;
    
    return f;

}

void main(void)
{
    
    vec2 uv = (2.*gl_FragCoord.xy - resolution.xy ) / resolution.y;
    vec2 mou = mouse*resolution.xy.xy / resolution.y;
    vec2 q = vec2( 0.0 );
    vec2 r = vec2( 0.0 );
    
    float tim = time * 0.2;
    
    float a = fbm( uv + fbm( uv + mod( tim, 200.0 ) + fbm( uv ) ) );
    float b = fbm( uv + vec2( mou ) + fbm( uv + mod( tim, 200.0 ) + fbm( uv ) ) );
    
    vec3 col = vec3( a );
    
    //vec3 col = vec3( mix( r.y, q.x, c ) );
    
    // Output to screen
    glFragColor = vec4(col,1.0);
}
