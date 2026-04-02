#version 420

// original https://www.shadertoy.com/view/XfB3Ww

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define S smoothstep
#define R min(I.x, I.y)
#define I resolution.xy
#define d( p, l ) S( l / R, 0., abs( p ) )
#define rot(a) mat2( cos(a), sin(a), -sin(a), cos(a) )
#define rot2( a ) cos(a + sin(a*.5) * .9) / .9
#define h( u ) fract( dot( u.yxx * .123, sign( u.yxx ) + 23.456 ) * 123.456 )
#define n normalize

float tex( vec2 u ){
    float r = h( abs( round( u / -.2 ) - 20. ) );
    u = mod( u + .1, .2 ) - .1, 
    u *= rot( round( r ) * 1.57 ),
    u -= sign( u.x + u.y ) * .1;
    float g = length(u)-.1;
    
    g += max(
        abs( u.x ) - .1,
        abs( u.y ) - .1
    ) * 1.5;
    
    return d( g, 18. );
}

float df( vec3 p ){
    
    //vec2 q = p.xy - rot2( p.z );
    vec2 q = p.xy;
    
    q.x += rot2(p.z);
    
    return 1. - max(
        abs( q.x ) - .5,
        abs( q.y ) - .5
    );
}

vec3 l(in vec3 b) {
  vec2 a = vec2(.5, -.5);
  return n(a.xyy * df(b + a.xyy * 5e-4) + a.yyx * df(b + a.yyx * 5e-4) +
                   a.yxy * df(b + a.yxy * 5e-4) + a.xxx * df(b + a.xxx * 5e-4));
}

float m( vec3 p ){
    vec3 c;

    vec3 q = p;
    q.z += rot2( p.y );

    
    
    return max( l(p).x, 0. ) * tex( p.yz ) * step( abs(q.y)-1.3, 0. ) +
        max( -l(p).x, 0. ) * tex( p.yz ) * step( abs(q.y)-1.3, 0. ) +
        max( l(p).y, 0. ) * tex( p.xz ) +
        max( -l(p).y, 0. ) * tex( p.xz );
}

void main(void)
{
    vec2 V = gl_FragCoord.xy;

    vec2 u = ( V * 2. - I ) / R;
    
    vec3 c, p, o = vec3( 0., 0., -1. ), lk, r;

    
    float t, d, i;

    o.z += time * 1.5;
    
    o.x -= rot2( o.z );
    
    
    lk = o + vec3(0.0, 0.0, 1.);
    lk.x -= rot2( lk.z );
    
    vec3 fo = n(lk-o);
    vec3 rt = n(vec3(fo.z, 0., -fo.x )); 
    vec3 up = cross(fo, rt);

    /*
        [
            right.x, up.x, -forward.x, p.x,
            right.y, up.y, -forward.y, p.y,
            right.z, up.z, -forward.z, p.x,
        ]
 
    */
    
    r = n(fo + u.x*rt + u.y*up);
    
    while( i++ < 64. )
        p = o + r * t,  
        d = df( p ),
        t += d;
    
    if( d < 1e-3 )
        c += m(p);

    glFragColor = c.rbgg;
}