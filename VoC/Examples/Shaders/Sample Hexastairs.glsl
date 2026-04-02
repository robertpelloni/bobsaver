#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/3sGfWm

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// using "hexa world" https://shadertoy.com/view/tsKBDD

#define H(I)   fract(1e4*sin(1e4*length(vec2(I))))         // cheap hash
//#define H(I) hash(uvec3(I.xy,0))                         // the one used in "hexa world": integer hash from https://www.shadertoy.com/view/XlXcW4

void main(void)
{
    vec2 R = resolution.xy, 
         U = 12.* gl_FragCoord.xy / R.y + time;

    U *= mat2(1,0,.5,.87);                                 // parallelogram frame
    vec3  V = vec3( U, U.y-U.x +3. );                      // 3 axial coords
    ivec3 I = ivec3(floor(V)), J;
          I += I.yzx;
          J = ( I % 3 ) / 2;                               // J.xy = hexagon face
    I.x += 4; I /= 3;                                      // I.xy = hexagon id
    int  k = int( 4.* H(I) ),                              // rand values per hexagon
         c = J.x + 2* J.y;                                 // int face id
    V = mod( V + vec3( I.y, I.y+I.x, I.x ), 2. );          // local coords
    
                                                           // --- make tiling pattern
    if (k==3) k = c+2;                                     // draw plain cubes
    else {
        float s=1.;
        V = k==1 ? V.yzx                                   // random rotation
          : k==2 ? s=-s, V = V.yxz : V;
        s *= mod(8.*V.y,2.)-1.;                           // strip slope  for stairs. Side dents below
        k += abs( 2.*V.x-V.y +(abs(s)-9.)/8. ) > 1. ? 2 : s < 0. ? 1 : 0; // draw stairs
    }
    glFragColor = vec4(k%3)/2.;
}
