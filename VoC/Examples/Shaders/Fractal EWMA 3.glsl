#version 420

// original https://www.shadertoy.com/view/4sjXDK

// Fractal rendering using the exponentially weighted moving average of z squared normalized

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

vec2 cinv( vec2 z)  { float d = dot(z,z); return vec2( z.x, -z.y ) / d; }
vec2 csqr( vec2 a ) { return vec2(a.x*a.x-a.y*a.y, 2.0*a.x*a.y ); }

vec2 p;
float bailout = 1e12;
float k = .03;

vec2 f1( vec2 x ){return csqr(x) + p  ;}//Mandelbrot
vec2 f2( vec2 x ){return cinv(x+p)+ x-p  ;}

vec2 f( vec2 x ){float t = 0.5+0.5*cos(0.1*time);return (f1(x)*t+f2(x)*(1.0-t));}

void main( void )
{
    p = 2.*(-resolution.xy+2.0*gl_FragCoord.xy)/resolution.y;

    vec2 z = p;
    vec2 zn = csqr(z)/dot(z,z);
    
    for( int i=0; i<60; i++ ) 
    {                   
        
        z=f(z);
        if(dot(z,z)>bailout){
            float k1 = pow(bailout/dot(z,z),.125)*k;
            zn = (1.-k1)*zn+k1*csqr(z)/dot(z,z);
            break;}
        zn = (1.-k)*zn+k*csqr(z)/dot(z,z);
    }
    
    float f = (1.-exp(-.5*dot(z,z)));
    vec3 color=2.*f*abs(vec3(zn.x*f,zn.x*zn.y,zn.y*zn.y));
    glFragColor = vec4(color,1.0);
}
