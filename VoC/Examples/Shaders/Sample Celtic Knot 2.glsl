#version 420

// original https://www.shadertoy.com/view/ld2BDy

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define S(l,r,e)  smoothstep( 4./R.y, 0., abs(l-r) -e )            // base thick ring antialiased

#define D(U,r,z) ( l=length(U) , a = atan((U).x,(U).y),    \
                   S(l,r,.08 )  * vec4( vec3(1.-S(l,r,.03)) , z )) // band pattern (col,Z) 

#define Z         (-.105 + cos( a ) ) * (1. - .05*T )              // Z arc + Z knot modulation

#define T         sin( -3.*a )                                     // Z modulation for knot

#define M(a)      O =  a.w > O.w ? a : O ;                 \
                  U *= mat2(-.5,-.866,.866,-.5);                   // Z-buffer draw + rotate

#define B         M( D( U +vec2(0,d), r , Z ) )                    // draw arc
                       

void main(void)
{
    vec2 U=gl_FragCoord.xy;
    vec2 R =  resolution.xy;
    U = ( U+U -R ) / R.y; U.y += .2;
    float l,a, d=.6, r=.8;

    vec4 O=glFragColor;    
    O-=O; 
    O.rgb += .5; // comment if you prefer black background
    
    M( D(U,.6,.5+.5*T) );    // ring
    B; B; B;                 // 3 arcs
    glFragColor=O;
}
