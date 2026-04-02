#version 420

// original https://www.shadertoy.com/view/ltcSzH

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Created by XORXOR, 2016
// Attribution-NonCommercial-ShareAlike 4.0 International (CC BY-NC-SA 4.0)
// 
// Thanks to iq's articles
// http://www.iquilezles.org/www/articles/distfunctions/distfunctions.htm
// and the Raymarching - Primitives sample
// https://www.shadertoy.com/view/Xds3zN

const int kNumSpheres = 20;

float hash1( float n )
{
    return fract( sin( n ) * 4121.15393 );
}

vec3 hash3( float n )
{
    return fract( sin( vec3( n, n + 1.0, n + 2.0 ) ) *
            vec3( 13.5453123, 31.1459123, 37.3490423 ) );
}

float sphere( vec3 p, float r )
{
    return length( p ) - r;
}

float smin( float a, float b, float k )
{
    float h = clamp( 0.5 + 0.5 *( b - a ) / k, 0.0, 1.0 );
    return mix( b, a, h ) - k * h * ( 1.0 - h );
}

float sdf( vec3 p )
{
    float d = 99999.0;
    vec3 t = vec3( 12923.73 + time );
    for ( int i = 0; i < kNumSpheres; i++ )
    {
        vec3 ps = vec3( 3.0 ) * cos( t * hash3( float( i ) ) );
        float ds = sphere( p - ps, mix( 0.7, 1.1, hash1( float( i ) ) ) );
        d = smin( d, ds, 0.85 );
    }
    return d;
}

float castRay( vec3 ro, vec3 rd )
{
    float t = 0.0;
    vec3 p;

    for ( int i = 0; i < 50; i++ )
    {
        p = ro + rd * t;
        float d = sdf( p );
        if ( d < 0.01 )
        {
            return t;
        }
        t += d;
    }

    return -1.0;
}

vec3 calcNormal( vec3 pos )
{
    vec3 eps = vec3( 0.001, 0.0, 0.0 );
    vec3 n = vec3(
            sdf( pos + eps.xyy ) - sdf( pos - eps.xyy ),
            sdf( pos + eps.yxy ) - sdf( pos - eps.yxy ),
            sdf( pos + eps.yyx ) - sdf( pos - eps.yyx ) );
    return normalize( n );
}

float calcShadow( vec3 ro, vec3 rd, float mint, float maxt )
{
    float t = mint;
    float res = 1.0;
    for ( int i = 0; i < 32; i++ )
    {
        float h = sdf( ro + rd * t );
        res = min( res, 7.0 * h / t );
        t += h;
        if ( ( h < 0.01 ) || ( t > maxt ) )
        {
            break;
        }
    }
    return clamp( res, 0.0, 1.0 );
}

mat3 setCamera( vec3 ro, vec3 ta )
{
    vec3 cw = normalize( ta - ro );
    vec3 cu = normalize( cross( cw, vec3( 0, 1, 0 ) ) );
    vec3 cv = normalize( cross( cu, cw ) );
    return mat3( cu, cv, cw );
}

void main(void)
{
    vec2 uv = ( gl_FragCoord.xy - resolution.xy * 0.5 ) / resolution.y;
    vec3 ro = vec3( 19.80, 0.0, -2.82 );
    vec3 ta = vec3( 0.0 );
    mat3 cm = setCamera( ro, ta );
    vec3 rd = cm * normalize( vec3( uv, 3.0 ) );

    vec3 col = vec3( 0.0 );
    float t = castRay( ro, rd );
    if ( t > 0.0 )
    {
        vec3 pos = ro + rd * t;
        vec3 n = calcNormal( pos );
        vec3 ref = reflect( rd, n );

        vec3 ldir = normalize( vec3( -0.5, 2.8, -5.0 ) );
        float dif = max( dot( n, ldir ), 0.0 );
        float spe = pow( clamp( dot( ref, ldir ), 0.0, 1.0 ), 32.0 );
        float sh = calcShadow( pos, ldir, 0.1, 8.0 );

        col += dif * sh * vec3( 0.7 );
        col += dif * sh * spe * vec3( 1.0 );
    }

    glFragColor = vec4( col, 1.0 );
}
