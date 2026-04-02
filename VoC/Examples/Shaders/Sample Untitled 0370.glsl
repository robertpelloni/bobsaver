#version 420

//Modified from: https://www.shadertoy.com/view/MslGD8

// Created by inigo quilez - iq/2013
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

#extension GL_OES_standard_derivatives : enable

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec2 hash( vec2 p ) { p=vec2(dot(p,vec2(127.1,311.7)),dot(p,vec2(269.5,183.3))); return fract(sin(p)*18.5453); }

// return distance, and cell id
vec2 voronoi( in vec2 x )
{
    vec2 n = floor( x );
    vec2 f = fract( x );

    vec3 m = vec3(0.25);
    const int r = 1;
    for( int j=-r; j<=r; j++ )
    for( int i=-r; i<=r; i++ )
    {
        vec2  g = vec2( float(i), float(j) );
        vec2  o = hash( n + g );
        vec2  r = g - f + (0.5+0.5*sin(time+6.2831*o));
    float d = dot( r, r );
        if( d<m.x )
            m = vec3( d, o );
    }

    return vec2( sqrt(m.x), m.x+m.z );
}

void main()
{
    vec2 p = gl_FragCoord.xy/max(resolution.x,resolution.y);
    vec2 ip = (14.0+6.0*sin(0.2*time))*p;
    // computer voronoi patterm
    vec2 c = voronoi( ip );

    // colorize
    vec3 col = 0.5 + 0.5*cos( c.y*6.2831 + vec3(0.0,1.0,2.0) );    
    col += vec3(0.005/fract(ip),0.0);
    glFragColor = vec4( col, 1.0 );
}
