#version 420

// original https://www.shadertoy.com/view/ltlfRf

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// reproducing http://blogs.discovermagazine.com/neuroskeptic/2017/12/08/curvature-blindness-illusion/

// All of the lines crossing the image are identical in shape, but half of them appear "zig-zagged" against the grey background.

#define S(v) smoothstep( 1.,-1., ( abs(v) - .07 ) * R.y/10.6 )  // antialiased thick curve

void main(void)
{
    vec2 R = resolution.xy;
    vec2 U = gl_FragCoord.xy;
    vec4 O = glFragColor;
    U = 5.3* ( U+U - R ) / R.y;
    O -= O;
    
    O += .45* step(-8.,U.y-U.x) + .55 * step(8.,U.y-U.x);       // background bands
    if (abs(U.y)>5.) return;
    
    float v = .3 + .4*mod(floor(U.x-.5*floor(mod(U.y,2.))),2.), // light/dark value along waves
         dy = .25*sin(3.14*U.x) -  ( 2.*fract(U.y)-1. );        // distance to sines
    O +=  S( dy )      * ( v - O );                             // pair of sines
    O +=  S( dy -.5 )  * ( v - O );

    glFragColor=O;
}
