#version 420

// original https://www.shadertoy.com/view/ll2GWy

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Created by inigo quilez - iq/2015
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

void main(void)
{
    vec2 p = 256.0 * gl_FragCoord.xy/resolution.x + time;

    float an = smoothstep( -0.5, 0.5, cos(3.14159*time) );
    
    float x = 0.0;
    for( int i=0; i<7; i++ ) 
    {
        vec2 a = floor(p);
        vec2 b = fract(p);
        
        x += mod( a.x + a.y, 2.0 ) * 
            
            // the following line implements the smooth xor
            mix( 1.0, 1.5*pow(4.0*(1.0-b.x)*b.x*(1.0-b.y)*b.y,0.25), an );
        
        p /= 2.0;
        x /= 2.0;
    }
    
    glFragColor = vec4( x, x, x, 1.0 );
}
