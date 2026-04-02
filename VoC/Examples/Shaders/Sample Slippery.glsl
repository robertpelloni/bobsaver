#version 420

// original https://www.shadertoy.com/view/wsyyRw

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define rot(a)     mat2( cos(a+vec4(0,11,33,0)) )                    // rotation                  
#define S(v)       smoothstep( 2.,-2., R.y*(v) )                     // AA
#define B(U,L,l)   t = min( t, max( abs((U).x)-L , abs((U).y)-l ) ), // box

void main(void) {
    vec4 O = glFragColor;
    vec2 u = gl_FragCoord.xy;

    vec2  R = resolution.xy,
          U = .9*( u+u - R ) / R.y;
    U.y += .3;
    float t = 6.283/6., T = 8.*time,
          d = length(U)*cos( mod( atan(U.x,U.y),  t+t ) -t );  // --- red triangle
    O = mix( vec4(d<.5), vec4(1,0,0,1), S( abs(d-.5) - .1 ) );
    
    if ( abs(U.y+.2) < .2)                                     // --- S
        d = U.x -.15*cos(18.*U.y+T) -.15-.5*U.y,
        O -=   S(  abs(d+.3 ) +.3*U.y )
             + S(  abs(d+U.y) +.3*U.y );
    
    U -= vec2( .15*cos(T), .1 );                              // --- car
    U *= rot(.2*sin(T) );
    U.x = abs(U.x);
    B(U,.18,.06)                                              // body
    B(U - vec2(.13,-.06), .02,.05 )                           // wheels
    B(U - vec2(  0 ,.15), .12,.015)                           // roof
    U *= rot(.3); B(U - vec2(.15,.06), .015,.06 )             // window sides
    O -= S(t);

    glFragColor = O;
}
