#version 420

// original https://www.shadertoy.com/view/4dSXWt

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;

out vec4 glFragColor;

// Created by inigo quilez - iq/2014
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

// Bifurcation diagram for the Logistic Map, the classic example for the Chaos Theory

// f(x) = h·x·(1-x)
// f'(x) = h·(1-2x)
//
// Fixed points of f(x)
//
// f(x)=x --> x=0 and x=1-1/h
// |f'(0)|<1     --> h<1
// |f'(1-1/h)|<1 --> h<3
//
// Period 2 points of f(x)
//
// f(f(x))=x --> (f(f(x))-x)/(f(x)-x) --> x=
// |f(f(x))'|<1 --> h<1+sqrt(6)

void main( void )
{
    float e = 4.0/resolution.x;
    vec2 p = vec2(4.0,1.0)*gl_FragCoord.xy/resolution.xy;

    float x = 0.5;

    // remove the line below to get rid of the transient state
    //for( int i=0; i<200; i++ ) x = p.x*x*(1.0-x);

    // plot the attractor    
    float f = 0.0;
    for( int i=0; i<512; i++ )
    {
        x = p.x*x*(1.0-x);
        f += 0.1*exp(-200000.0*(p.y-x)*(p.y-x));
    }
    
    f = 1.0 - f;

    // fixed points
    float al = 0.5 + 0.5*cos(time*6.2831);
    f *= al + (1.0-al)*smoothstep(0.0,1.5*e,abs(p.x-1.0));
    f *= al + (1.0-al)*smoothstep(0.0,1.5*e,abs(p.x-3.0));
    f *= al + (1.0-al)*smoothstep(0.0,1.5*e,abs(p.x-3.4495));
    
    glFragColor = vec4( f, f, f, 1.0 );
}
