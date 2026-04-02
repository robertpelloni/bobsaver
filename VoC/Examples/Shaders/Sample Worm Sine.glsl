#version 420

// original https://www.shadertoy.com/view/Nlsczj

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define S(v) smoothstep(1.5,0., v )

void main(void)
{
    vec2  R = resolution.xy,
          U = ( 2.*gl_FragCoord.xy - R ) / R.y;
    float x =  3.5*U.x, t = time,
          v = U.y +.2 - .1*sin(3.14*( x+t ) ),
          s = U.y -.1 + .2*sin(3.14*2./3.*( x + .5* sin ( 3.14/3.*( x + 3.*t ) ) ) );
          
    glFragColor =             .5  * S( v/fwidth(v) ) 
        + vec4(0,1,1,0) * S( abs(s)/fwidth(s) -1. );
}
