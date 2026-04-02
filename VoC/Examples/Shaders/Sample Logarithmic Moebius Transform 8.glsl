#version 420

// original https://www.shadertoy.com/view/WtlyWs

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// variant of https://shadertoy.com/view/3llcDl
// inspired by https://www.facebook.com/eric.wenger.547/videos/2727028317526304/

void main(void) {

    vec2 R = resolution.xy,  I,
         U = (2.*gl_FragCoord.xy - R) / R.y,                                // normalized coordinates
         z = U - vec2(-1,0);  U.x -= .5;                      // Moebius transform
    U *= mat2(z,-z.y,z.x) / dot(U,U);
              
                  // offset   spiral, zoom   phase            // spiraling
    U =   log(length(U+=.5))*vec2(.5, -.5) + time/8.
        + atan(U.y, U.x)/6.2832 * vec2(6, 1);        
                                   // n  
    U *= 3./vec2(2,1); z = fwidth(U);
    U = fract(U)*5.; I = floor(U); U = fract(U);              // subdiv big square in 5x5
    I.x = mod( I.x - 2.*I.y , 5.);                            // rearrange
    U.x += float(I.x==1.||I.x==3.); U.y += float(I.x<2.);     // recombine big tiles
    float id = -1.;
    if (I.x!=4.) U /= 2.,                                     // but small times
        id = mod(floor(I.x/2.)+I.y,5.);
    U = abs(fract(U)*2.-1.); float v = max(U.x,U.y);          // dist to border
    glFragColor =   smoothstep(.7,-.7, (v-.95)/( abs(z.x-z.y)>1.?.1:z.y*8.))  // draw AA tiles
        * (id<0.?vec4(1): .6 + .6 * cos( id  + vec4(0,23,21,0)  ) );// color
}
