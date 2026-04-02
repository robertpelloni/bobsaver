#version 420

// original https://www.shadertoy.com/view/4d23WG

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Created by inigo quilez - iq/2013
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

// line 13: pixel coordinates    
// line 15: c travels around the main cardiod c(t) = ½e^it - ¼e^i2t
// line 20: z = z² + c        
// line 21: trap orbit
// line 24: remap    
// line 26: color    

void main( void )
{
    vec2 z = 1.15*(-resolution.xy+2.0*gl_FragCoord.xy)/resolution.y;

    vec2 an = 0.51*cos( vec2(0.0,1.5708) + 0.1*time ) - 0.25*cos( vec2(0.0,1.5708) + 0.2*time );

    float f = 1e20;
    for( int i=0; i<128; i++ ) 
    {
        z = vec2( z.x*z.x-z.y*z.y, 2.0*z.x*z.y ) + an;
        f = min( f, dot(z,z) );
    }
    
    f = 1.0+log(f)/16.0;

    glFragColor = vec4(f,f*f,f*f*f,1.0);
}
