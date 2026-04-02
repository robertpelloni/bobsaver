#version 420

// original https://www.shadertoy.com/view/Ms3SzB

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// inspired from Shane's ribbon variant of https://www.shadertoy.com/view/ls3XWM 

void main(void)
{
    float h = resolution.y;  vec2 U = 4.*(gl_FragCoord.xy+mouse.xy*resolution.xy)/h;                    // normalized coordinates
    vec2 K = ceil(U); U = 2.*fract(U)-1.;  // or K = 1.+2.*floor(U) to avoid non-fractionals
    float a = atan(U.y,U.x), r=length(U), v=0., A;                       // polar coordinates
    
    for(int i=0; i<7; i++)
        // if fractional, there is K.y turns to close the loop via K.x wings.
        v = max(v,   ( 1. + .8* cos(A= K.x/K.y*a + time) ) / 1.8  // 1+cos(A) = depth-shading
                   * smoothstep(1., 1.-120./h, 8.*abs(r-.2*sin(A)-.5))), // ribbon (antialiased)
        a += 6.28;                                                       // next turn

 
    glFragColor = v*vec4(.8,1,.3,1); glFragColor.g = sqrt(glFragColor.g);                              // greenify
  //glFragColor = v*(.5+.5*sin(K.x+17.*K.y+iDate.w+vec4(0,2.1,-2.1,0)));           // random colors
}

