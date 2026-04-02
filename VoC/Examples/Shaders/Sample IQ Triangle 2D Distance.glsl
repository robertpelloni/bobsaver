#version 420

// original https://www.shadertoy.com/view/XsXSz4

uniform float time;
uniform vec2 resolution;

out vec4 glFragColor;

// Created by inigo quilez - iq/2014
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

// squared distance to a segment (and orientation)
vec2 sSqdSegment( in vec2 a, in vec2 b, in vec2 p )
{
    vec2 pa = p - a;
    vec2 ba = b - a;
    float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
    return vec2( dot( pa-ba*h, pa-ba*h ), pa.x*ba.y-pa.y*ba.x );
}

// signed distance to a 2D triangle
float sdTriangle( in vec2 v1, in vec2 v2, in vec2 v3, in vec2 p )
{
    vec2 d = min( min( sSqdSegment( v1, v2, p ), 
                       sSqdSegment( v2, v3, p )), 
                       sSqdSegment( v3, v1, p ));

    return -sqrt(d.x)*sign(d.y);
}

void main( void )
{
    vec2 p = (2.0*gl_FragCoord.xy-resolution.xy)/resolution.y;

    vec2 v1 = cos( time + vec2(0.0,1.57) + 0.0 );
    vec2 v2 = cos( time + vec2(0.0,1.57) + 2.0 );
    vec2 v3 = cos( time + vec2(0.0,1.57) + 4.0 );

    float d = sdTriangle( v1, v2, v3, p );

    vec3 col = vec3(1.0) - sign(d)*vec3(0.1,0.4,0.7);
    col *= 1.0 - exp(-2.0*abs(d));
    col *= 0.8 + 0.2*cos(120.0*d);
    col = mix( col, vec3(1.0), 1.0-smoothstep(0.0,0.02,abs(d)) );

    glFragColor = vec4(col,1.0);
}
