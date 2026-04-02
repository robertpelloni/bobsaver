#version 420

// original https://www.shadertoy.com/view/4dBfWK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// reference image: https://twitter.com/martinstaylor/status/894512566629740544

void main(void)
{
    vec2 U=gl_FragCoord.xy;
    U *= 4./ resolution.y;                        // normalized coordinates *4
    
    vec2 S = mod(U,2.)  -1.,                       // 2x2 cells
         L = fract( U )*2. -1.,                    // local centered cell coordinates
         A = abs(L),                               // cell symmetry
         V = abs(A-.5);                            // cell corners coordinates + symmetry
    
    vec4 O=glFragColor;
    O -= O;
    
    if ( A.x < .5 ) O = vec4(.9,.9,1.5,0);         // vertical bands 
    
    if ( A.y < .5 ) O = vec4(.5,.6,1,0);           // horizontal bands

#if 1                 // decoration. Not required for illusion
    float v = .5,
          l = length(V), 
          m = min(A.x,A.y), M = max(A.x,A.y);
    O *= v;
    if( l < .48 || m > .15 ) O /= v;               // exterior side decoration
    if (     A.x+A.y < .6 && abs(l-.62) < .02      // axial decoration
         ||  M > .8 && m < .05 )   O += .5;
#endif 
            
    if (V.x+V.y < .25)                             // the illusion key: corner diamonds
        L = V * sign(L.x*L.y*S.y),
        O = vec4( L.x > L.y ); // *.125+.5;
    glFragColor=O;
}
