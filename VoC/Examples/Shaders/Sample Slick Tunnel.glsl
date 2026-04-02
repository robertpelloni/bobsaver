#version 420

// original https://www.shadertoy.com/view/wsS3Dh

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define STEPS 500
#define FAR   20.
#define EPS  1e-3
// Uncomment for a hexagon, rather than a box.
//#define HEX

mat2 rot( float a )
{

    return mat2( cos( a ), -sin( a ),
                 sin( a ),  cos( a )
                );

}

vec3 twiZ( vec3 p, float f )
{

    float a = p.z * 0.6 * f;

    p.yx = cos( a ) * p.yx + sin( a ) * vec2( -p.x, p.y );

    return p;

}

float vmax(vec2 v)
{

    return max(v.x, v.y);

}

float fBox2Cheap(vec2 p, vec2 b)
{

     return vmax(abs(p)-b);

}

float sdHexPrism( vec3 p, vec2 h )
{

    const vec3 k = vec3(-0.8660254, 0.5, 0.57735);
    p = abs(p);
    p.xy -= 2.0*min(dot(k.xy, p.xy), 0.0)*k.xy;
    vec2 d = vec2( length(p.xy-vec2(clamp(p.x,-k.z*h.x,k.z*h.x), h.x))*sign(p.y-h.x), p.z-h.y );

    return min(max(d.x,d.y),0.0) + length(max(d,0.0));

}

float path( float z )
{

    vec2 mou = mouse*resolution.xy.xy / resolution.y;
    return ( 1.5 * sin( z ) * 1.2 * cos( z ) );

}

vec2 map( vec3 p )
{

    vec2 spe = vec2( length( p -
                            vec3( 0.3 * -path( p.z ),
                                 0,
                                 1.5 + time
                                )
                           ) - 0.2, 0.0 );

    vec3 tem = p;

    p.x += path( p.z );
    tem.x += path( p.z );
    tem = twiZ( p, 1.0 );

    float hex = sdHexPrism( tem, vec2( 1, time + 8.7 ) );

    float box = fBox2Cheap( p.xy, vec2( 3 ) );
    float boxO = fBox2Cheap( tem.xy, vec2( 1 ) );

    #ifdef HEX
    vec2 tun = vec2 ( max( -hex, box ), 1.0 );
    
    #else
    vec2 tun = vec2 ( max( -boxO, box ), 1.0 );
    
    #endif

    if( spe.x < tun.x ) tun = spe;

    return tun;

}

vec3 norm( vec3 p )
{

    vec2 e = vec2( 1e-3, 0 );

    return normalize( vec3( map( p + e.xyy ).x - map( p - e.xyy ).x,
                              map( p + e.yxy ).x - map( p - e.yxy ).x,
                              map( p + e.yyx ).x - map( p - e.yyx ).x
                            )
                      );

}

float ray( vec3 ro, vec3 rd, out float d )
{

    float t = 0.0;

    for( int i = 0; i < STEPS; ++i )
    {

        vec3 p = ro + rd * t;

        d = 0.5 * map( p ).x;

        if( d < EPS || t > FAR ) break;

        t += d;

    }

    return t;

}

vec3 sha( vec3 ro, vec3 rd )
{

    float d = 0.0, t = ray( ro, rd, d );

    vec3 p = ro + rd * t;
    vec3 n = norm( p );
    vec3 lig = normalize( vec3( 0, 0, -time - 1.1 ) );
    lig.x -= 0.3 * path( lig.z );
    lig = normalize( lig );
    vec3 ref = reflect( rd, n );

    float amb = 0.5 + 0.5 * n.y;
    float dif = max( 0.0, dot( lig, n ) );
    float spe = pow( clamp( dot( ref, lig ), 0.0, 1.0 ), 16.0 );

    vec3 col = vec3( 0.3 );
    col += 0.2 * amb;
    col += 0.2 * dif;
    col += 5.0 * spe;

    col *= 8.0 * 0.025 * t * t;
    
    if( map( p ).y == 0.0 )
    col.r += 0.3;
    
    //col *= sqrt( col );

    return col;

}

void main(void)
{

    vec2 uv = ( -resolution.xy + 2.0 * gl_FragCoord.xy ) / resolution.y;

    vec2 mou = mouse*resolution.xy.xy / resolution.y;

    vec3 ro = vec3( 0, 0, 0.9 + time );
    ro = twiZ( ro, 1.0 );
    ro.x -= 0.3 * path( ro.z );

    vec3 rd = normalize( vec3( uv, 1 ) );
    rd = twiZ( rd, 1.0 );
    rd.x -= 0.3 * path( ro.y);

    float d = 0.0, t = ray( ro, rd, d );
    vec3 p = ro + rd * t;
    vec3 n = norm( p );

    vec3 col = d < EPS ? sha( ro, rd ) : vec3( 1 );

    rd = normalize( reflect( rd, n ) );
    ro = p + rd;

    if( d < EPS ) col += sha( ro, rd );

    glFragColor = vec4( col, 1 );

}
