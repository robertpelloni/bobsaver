#version 420

// original https://www.shadertoy.com/view/Mls3W8

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main( void )
{
        
    float f = 1.,g = 1.,t = time;
    vec2 p = 2.*gl_FragCoord.xy/resolution.y-1.5,z = p,k = vec2(cos(t),sin(3.2*t));

    
    for( int i=0; i<32; i++ ) 
    {
                   
        z = vec2( z.x*z.x-z.x*z.y, z.x/z.y ) - p*k;
        f = min( f, abs(dot(z-p,z-k) ));
        g = min( g, dot(z,z));
    }
    
    f = log(f)/9.;

    glFragColor = abs(vec4(log(g)/8.,f*f,f*f*f,1.));
}
