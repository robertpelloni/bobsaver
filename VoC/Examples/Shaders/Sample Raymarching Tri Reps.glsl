#version 420

// original https://www.shadertoy.com/view/mdKBzd

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define I resolution
#define PI 3.1415926
#define rot( r ) mat2(cos(r), sin(r), -sin(r), cos(r) )
#define T(a) fract(time * a) * PI * 4.
#define v( a ) clamp( a, 0., 1. )

// smax
float sm(float a, float b, float c) {
  float d = clamp(.5 + .5 * (-b + a) / c, 0., 1.);
  return -(mix(-b, -a, d) - c * d * (1. - d));
}

float mExp( vec2 p1, vec2 p2, in vec2 uv ){
    return ( uv.y - p2.y ) * ( p1.x - p2.x ) -( ( uv.x - p2.x ) * ( p1.y - p2.y ) );
}
// IQ
float tri( in vec2 p, in float r, int invert )
{
    if( invert == 1 )
        p.y *= -1.;
        
    const float k = sqrt(3.0);
    p.x = abs(p.x) - r;
    p.y = p.y + r/k;
    if( p.x+k*p.y>0.0 ) p = vec2(p.x-k*p.y,-k*p.x-p.y)/2.0;
    p.x -= clamp( p.x, -2.0*r, 0.0 );
    return -length(p)*sign(p.y);
}

vec2 rep( inout vec2 p, vec2 size)
{

    vec2 h = size * .5;
    vec2 cell = floor((p + h) / size);
    
    p = mod(p + h, size) - h;
    
    return cell;
}

float frame( vec3 p, float h2, int inv ){
    return sm(
        max(
            tri( p.xz, .4, inv ),
            abs( p.y ) - h2
        ),
        -max(
            tri( p.xz, .3, inv ),
            abs( p.y ) - h2
        ),
        .03
    );
}

float cu( vec3 p, float h1, float h2, int inv ){

    return min(
        sm(
            tri( p.xz, .2, inv ),
            abs( p.y ) - h1,
            .05
        ),
        frame( p, h2, inv )
    );
}

float c1( vec3 p ){

    p.y += cos( p.x - T( .125 ) ) * .1;
    p.y += sin( p.z - T( .125 ) ) * .1;
    
    p.xy *= rot( PI * .05 ),
    p.yz *= rot( PI * -.3 );
    p.z -= time * .3;
    
    vec2 cell = rep( p.xz, vec2( .85, 1.05 ) );

    p.y += cos( abs( cell.x ) - T( .125 ) ) * .05;
    p.y += sin( abs( cell.y ) - T( .125 ) ) * .05;

    bool b = mod( cell.y, 1. ) == 0.;

    return cu( p, b ? .1 : .2,  b ? .2 :.1, 0 );
}

float c2( vec3 p ){

    p.y += cos( p.x - T( .125 ) ) * .1;
    p.y += sin( p.z - T( .125 ) ) * .1;
    
    p.xy *= rot( PI * .05 ),
    p.yz *= rot( PI * -.3 );
    
    p.z -= time * .3;
    
    vec3 p2 = p;
    
    // p2.z *= -1.;
    p2.x += 0.43;
    p2.z += .48;
    

    vec2 row = rep( p2.xz, vec2( .85, 1.05 ) );
    
    p2.y += cos( abs( row.x ) - T( .125 ) ) * .05;
    p2.y += sin( abs( row.y ) - T( .125 ) ) * .05;
    
    
    bool b2 = mod( row.x, 2. ) == 0.;
    
    return cu( p2, b2 ? .2 : .1,  b2 ? .1 :.2, 1 );
}

float df( vec3 p ){
    
    return min( c1( p ), c2( p ) );
}

// calcNormal (IQ)
vec3 nrm(in vec3 b) {
  vec2 a = vec2(1, -1) * .5773;
  return normalize(a.xyy * df(b + a.xyy * 5e-4) + a.yyx * df(b + a.yyx * 5e-4) +
                   a.yxy * df(b + a.yxy * 5e-4) + a.xxx * df(b + a.xxx * 5e-4));
}

vec3 tex( vec3 p ){
    p.xy *= rot( PI * -.1 );
    p.x = mod( p.x, 4. ) - 3.;
    float a = abs( p.x ) - 2.;
    return vec3( cos( p.z / 2. + .5 ) * a, cos( a ) * sin( a ), cos( a ) );
}

float S( vec3 p, vec3 ca, vec3 r, float q ){
    return v( pow( dot( nrm( p ), normalize( normalize( ca ) - r ) ), q ) );
}

void main(void)
{
    vec4 U = vec4(0.0);
    vec2 V = gl_FragCoord.xy;
    
    // Normalized pixel coordinates (from 0 to 1)
    vec2 u = ( V * 2. - I.xy ) / min( I.x, I.y );
    
    vec3 c, p, o = vec3( 0., 0., -2. ), r = vec3( u * .9, 1. ), ca = vec3( 0., .7, 0. );
    
    
    float t, d, i, g = 1. - smoothstep( 0., 1.2, length( u * vec2( .6, 1. ) ) - .1 );
    
    c += vec3( 1, 2, 3 ) * .1 * g;
    
    for( ; i < 64.; i++ )
        p = o + r * t,
        d = df( p ),
        //ca.x = sin( p.x + cos( p.y ) ) * .1,
        t += d * .66667;
    
    if( d < 1e-3 ){
        
        ca.x += cos( T( .125 ) ) * .5;
        ca.z += sin( T( .125 ) ) * .5;
        
        float dif = max(dot(ca, nrm(p) ), 0.0);

        c += pow( dif, 2. ) * vec3( .1, .3, .4 );
        
        // c += tex( reflect( nrm( p * .1 ), vec3( p.z / 2. + .5 ) ) ) * pow( dif, 12. );

        // spot
        ca.z += .5;
        float ss = S( p, ca, r, 5. );
        ss *= g;
        c += clamp( ss, 0., .3 );
        
        vec3 a = vec3( 0., .5, 0. );
        a.x += cos( T( .125 ) );
    
        float sss = S( p, a, r, 17. );
        sss *= dif;
        c += clamp( vec3( sin( T( .125 ) ), 1, 3 ) * .555 * sss, 0., .7 );
        
    }
    
    c = clamp( c, 0., .8 );

    
    
    c = mix(
        c,
        vec3( 0. ),
        smoothstep( 0., 1.6, length( u * vec2( .5, 1. ) + vec2( 0., .1 ) ) - .01 ) * cos( time * .25 )
    );
    
    // Output to screen
    U = vec4(c,1.0);
    
    glFragColor = U;
}