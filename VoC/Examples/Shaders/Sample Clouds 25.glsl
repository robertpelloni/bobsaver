#version 420

// original https://www.shadertoy.com/view/XdVBWR

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define STEPS        64
#define FAR         10.
#define PI acos( -1.0 )

float hash( float n )
{

    return fract( sin( n ) * 45843.349 );
    
}

float noise( in vec3 x )
{

    vec3 p = floor( x );
    vec3 k = fract( x );
    
    k *= k * k * ( 3.0 - 2.0 * k );
    
    float n = p.x + p.y * 57.0 + p.z * 113.0; 
    
    float a = hash( n );
    float b = hash( n + 1.0 );
    float c = hash( n + 57.0 );
    float d = hash( n + 58.0 );
    
    float e = hash( n + 113.0 );
    float f = hash( n + 114.0 );
    float g = hash( n + 170.0 );
    float h = hash( n + 171.0 );
    
    float res = mix( mix( mix ( a, b, k.x ), mix( c, d, k.x ), k.y ),
                     mix( mix ( e, f, k.x ), mix( g, h, k.x ), k.y ),
                     k.z
                     );
    
    return res;
    
}

float fbm( in vec3 p )
{

    float f = 0.0;
    f += 0.5000 * noise( p ); p *= 2.02;
    f += 0.2500 * noise( p ); p *= 2.03;
    f += 0.1250 * noise( p ); p *= 2.01;
    f += 0.0625 * noise( p );
    f += 0.0125 * noise( p );
    return f / 0.9375;
    
}

float map( vec3 p )
{

    //return p.y + 1.0 * fbm( p + time * 0.2 );
    //return 0.4 - length( p ) * fbm( p + time );
    
    p.z -= time;
    
    float f = fbm( p + time * 0.1 );
    
    return f;
    
}

float ray( vec3 ro, vec3 rd, out float den )
{

    float t = 0.0, maxD = 0.0; den = 0.0;
    
    for( int i = 0; i < STEPS; ++i )
    {
        
        vec3 p = ro + rd * t;
    
        den = map( p );
        maxD = maxD < den ? den : maxD;
        
        if( maxD > 0.99 || t > FAR ) break;
        
        t += 0.05;
    
    }
    
    den = maxD;
    
    return t;

}

vec3 shad( vec3 ro, vec3 rd, vec2 uv )
{

    float den = 0.0;
    float t = ray( ro, rd, den );
    
    vec3 p = ro + rd * t;

    vec3 col = mix( mix( vec3( 0.7 ), vec3( 0.2, 0.5, 0.8 ), uv.y ), mix( vec3( 0 ), vec3( 1 ), den ), den );
    //vec3 col = mix( vec3( 1 ), colB, den );
    
    return col;

}

void main(void)
{
    
    vec2 uv = ( -resolution.xy + 2.0 * gl_FragCoord.xy ) / resolution.y;

    vec2 mou = mouse*resolution.xy.xy / resolution.xy;
    
    vec3 ro = 3.0 * vec3( sin( mou.x * 2.0 * PI ), 0.0, cos( -mou.x * 2.0 * PI ) );
    vec3 ww = normalize( vec3( 0 ) - ro );
    vec3 uu = normalize( cross( vec3( 0, 1, 0 ), ww ) );
    vec3 vv = normalize( cross( ww, uu ) );
    vec3 rd = normalize( uv.x * uu + uv.y * vv + 1.5 * ww );
    
    float den = 0.0, t = ray( ro, rd, den );
    
    vec3 col = shad( ro, rd, uv );
    
    // Output to screen
    glFragColor = vec4(col,1.0);
}
