#version 420

// original https://www.shadertoy.com/view/Xl3XR4

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

#define SQRT_2 1.4142135623730951
#define HALF_PI 1.5707963267948966
#define QUARTER_PI 0.7853981633974483

#define CUBE_SIZE 0.5

vec2 opU( vec2 d1, vec2 d2 )
{
    return ( d1.x < d2.x ) ? d1 : d2;
}

mat3 transform( float a, out vec2 offset )
{
    float c = cos( a );
    float s = sin( a );
    vec2 v = CUBE_SIZE * SQRT_2 * abs( vec2( cos( a + QUARTER_PI ), sin( a + QUARTER_PI ) ) );
    offset.x = - min( abs( v.x ), abs( v.y ) );
    offset.y = max( v.x, v.y );
    if ( mod( a, HALF_PI ) > QUARTER_PI )
    {
        offset.x = - offset.x;
    }
    float n = floor( a / QUARTER_PI ) + 2.0;
    offset.x += CUBE_SIZE * 2.0 * floor( n / 2.0 );
    offset.x = mod( offset.x, 12.0 ) - 5.0;

    // rotation matrix inverse
    return mat3( c, 0, s,
                -s, 0, c,
                 0, 1, 0 );
}

float udRoundBoxT( vec3 p )
{
    float r = 0.1;
    return length( max( abs( p ) - vec3( CUBE_SIZE - r ), 0.0 ) ) - r;
}

float hash( float n )
{
    return fract( sin( n ) * 4121.15393 );
}

vec2 map( vec3 p )
{
    vec2 plane = vec2( abs( p.y ), 1.0 );

    vec2 offset = vec2( 0 );
    mat3 t = transform( time * 2.0, offset );
    vec3 q = t * ( p  - vec3( offset.x - 0.3, offset.y, -3.0 ) );
    vec2 box = vec2( udRoundBoxT( q ), 2.0 );

    mat3 t2 = transform( 4.0 + time * 2.5, offset );
    vec3 q2 = t2 * ( p  - vec3( offset.x + 0.1, offset.y, 1.0 ) );
    vec2 box2 = vec2( udRoundBoxT( q2 ), 3.0 );

    mat3 t3 = transform( 2.0 + time * 1.2, offset );
    vec3 q3 = t3 * ( p  - vec3( offset.x + 0.4, offset.y, -1.2 ) );
    vec2 box3 = vec2( udRoundBoxT( q3 ), 4.0 );

    mat3 t4 = transform( -1.3 + time * 1.75, offset );
    vec3 q4 = t4 * ( p  - vec3( offset.x + 0.3, offset.y, 2.3 ) );
    vec2 box4 = vec2( udRoundBoxT( q4 ), 5.0 );

    return opU( opU( box, opU( box2, opU( box3, box4 ) ) ),
                plane );
}

vec2 scene( vec3 ro, vec3 rd )
{
    float t = 0.1;
    for ( int i = 0; i < 64; i++ )
    {
        vec3 pos = ro + rd * t;
        vec2 res = map( pos );
        if ( res.x < 0.0005 )
        {
            return vec2( t, res.y );
        }
        t += res.x;
    }
    return vec2( -1.0 );
}

float calcShadow( vec3 ro, vec3 rd, float mint, float maxt )
{
    float t = mint;
    float res = 1.0;
    for ( int i = 0; i < 32; i++ )
    {
        vec2 h = map( ro + rd * t );
        res = min( res, 2.0 * h.x / t );
        t += h.x;
        if ( ( h.x < 0.001 ) || ( t > maxt ) )
        {
            break;
        }
    }
    return clamp( res, 0.0, 1.0 );
}

float calcAo( vec3 pos, vec3 n )
{
    float occ = 0.0;
    for ( int i = 0; i < 5; i++ )
    {
        float hp = 0.01 + 0.1 * float(i) / 4.0;
        float dp = map( pos + n * hp ).x;
        occ += ( hp - dp );
    }
    return clamp( 1.0 - 1.5 * occ, 0.0, 1.0 );
}

vec3 calcNormal( vec3 pos )
{
    vec3 eps = vec3( 0.001, 0.0, 0.0 );
    vec3 n = vec3(
            map( pos + eps.xyy ).x - map( pos - eps.xyy ).x,
            map( pos + eps.yxy ).x - map( pos - eps.yxy ).x,
            map( pos + eps.yyx ).x - map( pos - eps.yyx ).x );
    return normalize( n );
}

// http://www.iquilezles.org/www/articles/palettes/palettes.htm
vec3 palette( in float t, in vec3 a, in vec3 b, in vec3 c, in vec3 d )
{
    return a + b * cos( 6.28318 * ( c * t + d ) );
}

void main(void)
{
    vec2 uv = ( gl_FragCoord.xy - 0.5 * resolution.xy )/ resolution.y;
    vec3 eye = vec3( 0.0, 7.0, 20.0 );
    vec3 target = vec3( 0.0 );
    vec3 cw = normalize( target - eye );
    vec3 cu = cross( cw, vec3( 0.0, 1.0, 0.0 ) );
    vec3 cv = cross( cu, cw );
    mat3 cm = mat3( cu, cv, cw );
    vec3 rd = cm * normalize( vec3( uv, 6.0 ) );

    vec2 res = scene( eye, rd );

    vec3 col = vec3( 0.0 );
    if ( res.x >= 0.0 )
    {
        vec3 pos = eye + rd * res.x;
        vec3 n = calcNormal( pos );
        if ( res.y == 1.0 )
        {
            col = vec3( 0.2 + mod( floor( pos.x ) + floor( pos.z ), 2.0 ) );
        }
        else
        {
            col = palette( ( res.y - 1.0 ) / 4.0,
                     vec3( 0.5, 0.5, 0.5 ), vec3( 0.5, 0.5, 0.5    ),
                     vec3( 1.0, 1.0, 1.0 ), vec3( 0.0, 0.33, 0.67 ) );
        }

        vec3 ldir = normalize( vec3( 0.5, 2.8, 4.0 ) );
        float sh = calcShadow( pos, ldir, 0.01, 4.0 );
        float ao = calcAo( pos, n );
        col *= ( 0.2 + ao ) * ( 0.3 + sh );

        vec3 ref = reflect( rd, n );
        float refSh = calcShadow( pos, ref, 0.01, 4.0 );

        float dif = max( dot( n, ldir ), 0.0 );
        float spe = pow( clamp( dot( ref, ldir ), 0.0, 1.0 ), 15.0 );

        col *= ( 0.3 + dif ) * ( 0.5 + refSh );
        col += dif * sh *  spe * vec3( 1.0 );
    }

    glFragColor = vec4( col, 1.0 );
}
