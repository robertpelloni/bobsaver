#version 420

// original https://www.shadertoy.com/view/Mlf3zl

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Created by inigo quilez - iq/2015
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

//
// Computes the curvature of a parametric curve f(x) as 
//
// c(f) = |f'|^3 / | f' x f''|
//
// More info here: https://en.wikipedia.org/wiki/Curvature)
//

//----------------------------------------

float a,b,c;
vec2 m,n;

// curve
vec2 mapD0(float t)
{
    return a*cos(t+m)*(b+c*cos(t*7.0+n));
}
// curve derivative (velocity)
vec2 mapD1(float t)
{
    return -7.0*a*c*cos(t+m)*sin(7.0*t+n) - a*sin(t+m)*(b+c*cos(7.0*t+n));
}
// curve second derivative (acceleration)
vec2 mapD2(float t)
{
    return 14.0*a*c*sin(t+m)*sin(7.0*t+n) - a*cos(t+m)*(b+c*cos(7.0*t+n)) - 49.0*a*c*cos(t+m)*cos(7.0*t+n);
}

//----------------------------------------

float cross( in vec2 a, in vec2 b ) { return a.x*b.y - a.y*b.x; }

float curvature( float t )
{
    vec2 r1 = mapD1(t); // first derivative
    vec2 r2 = mapD2(t); // second derivative
    return pow(length(r1),3.0) / length(cross(r1,r2));
}

//-----------------------------------------

vec2 sdSegment( in vec2 p, in vec2 a, in vec2 b )
{
    vec2 pa = p - a, ba = b - a;
    float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
    return vec2( length( pa - ba*h ), h );
}

vec2 graph( vec2 p )
{
    float dt = 6.2831/256.0;
    float t = 0.0;

    float mint = 1e10;
    
    vec2  xb = mapD0(t);
    
    float d = length( p - xb );
    
    t += dt;
    for( int i=0; i<256; i++ )
    {
        vec2 xc = mapD0(t);
        float k = curvature(t);
        vec2 ds = sdSegment( p, xb, xc );
        if( ds.x < d ) 
        { 
            d = ds.x;
            mint = (t-dt + dt*ds.y ); 
        }
        t += dt;
        xb = xc;
    }
    
    return vec2( d, mint );
}

void main(void)
{
    a = 0.85 + 0.1*cos(5.0+0.7*time);
    b = 0.60 + 0.1*cos(4.0+0.5*time);
    c = 0.40 + 0.1*cos(1.0+0.3*time);
    m = cos( 0.11*time + vec2(2.0,0.0) );
    n = cos( 0.17*time + vec2(3.0,1.0) );

    float px = 2.0/resolution.y;
    vec2 p = (-resolution.xy+2.0*gl_FragCoord.xy)/resolution.y;
    
    vec2  d = graph( p );
    float c = curvature( d.y );
        
    // background (distance)
    vec3 col = vec3(0.3);
    col *= 1.0 - 0.1*smoothstep(-0.3,0.3,sin( 120.0*d.x ));
    col *= 1.0 - 0.4*d.x;

    // curve (curvature)
    vec3 cc = clamp( 0.25 + 0.75*cos( -clamp(3.0*c,0.0,2.0) + 1.0 + vec3(0.0,1.5,2.0) ), 0.0, 1.0 );
    col = mix( col, cc, 1.0 - smoothstep(1.0*px, 3.0*px, d.x ) );
    
    glFragColor = vec4( col, 1.0 );
}
