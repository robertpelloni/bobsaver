#version 420

// original https://www.shadertoy.com/view/MsSXDK

// Mandelbrot rendering using the exponentially weighted moving average of z squared normalized

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

vec2 csqr( vec2 a ) { return vec2(a.x*a.x-a.y*a.y, 2.0*a.x*a.y ); }

void main( void )
{
    vec2 p = .5*(-resolution.xy+2.0*gl_FragCoord.xy)/resolution.y-.5;

    vec2 z = p;
    vec2 zn = csqr(z)/dot(z,z);
    
    for( int i=0; i<60; i++ ) 
    {                   
        z = csqr(z) + .9*sin(time*.1)*z + p;    
         if(dot(z,z)>1e12){
            float k = .125*pow(1e12/dot(z,z),.125)*.2;
            zn = (1.-k)*zn+(k)*csqr(z)/dot(z,z);
            break;}
        zn = .98*zn+.02*csqr(z)/dot(z,z);
    }
    
    float f = (1.-exp(-.5*dot(z,z)));
    vec3 color=2.*f*abs(vec3(zn.x*f,zn.x*zn.y,zn.y*zn.y));
    glFragColor = vec4(color,1.0);
}
