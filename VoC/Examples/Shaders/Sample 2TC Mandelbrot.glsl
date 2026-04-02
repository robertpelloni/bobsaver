#version 420

// original https://www.shadertoy.com/view/lllGWH

uniform float time;
uniform vec2 resolution;

out vec4 glFragColor;

// Mandelbrot set zoom, with smooth coloring (Douady-Hubbard)

// Created by inigo quilez - iq/2015
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

void main()
{
    vec2 c = vec2(-.745,.186) + 2.5 * (gl_FragCoord.xy/resolution.y-.5)*pow(.01,1.+cos(.2*time)), z=c*.0;
    
    float n = 0.;

    for( int i=0; i<256; i++ )
    {
        z = vec2( z.x*z.x - z.y*z.y, 2.*z.x*z.y ) + c;

        if( dot(z,z)>65536. ) break;

        n++;
    }
    
    glFragColor = .5 + .5*cos( vec4(3,4,11,0) + .05*
                                (n - log2(log2(dot(z,z)))) );
}
