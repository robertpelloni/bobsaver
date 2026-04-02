#version 420

// original https://www.shadertoy.com/view/Wtl3zS

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// The MIT License
// Copyright © 2019 J. M.
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

// Use a (complex) Möbius transformation to distort a set of hexagonally packed disks

#define IS3 1.0/sqrt(3.0)

// some colors
#define C1 vec3(0.18, 0.31, 0.31)
#define C2 vec3(0.1, 0.8, 0.6)

// XY range of the display.
#define DISP_SCALE 4.0 

// from Fabrice Neyret, 
#define cis(a) vec2( cos(a), sin(a) )
#define cmul(A,B) ( mat2( A, -(A).y, (A).x ) * (B) )
#define cdiv(A,B) ( cmul( A, vec2( (B).x, -(B).y ) ) / dot(B, B) )

// Möbius transformation parametrized by its fixed points g1, g2 and pole zi, https://en.wikipedia.org/wiki/M%C3%B6bius_transformation#Poles_of_the_transformation

vec2 moebius( in vec2 g1, in vec2 g2, in vec2 zi, in vec2 z )
{
    return cdiv(cmul(g1 + g2 - zi, z) - cmul(g1, g2), z - zi);
}

// generate hexagonally packed disks

float hexpack(vec2 p)
{
      float sc = 6.0 * DISP_SCALE / resolution.y;
      float x = p.x, y = p.y * IS3;

      float u = mod(x - y, 1.0), v = mod(2.0 * y, 1.0);
      float qf = 4.0 * (u + v) * (u + v) - 4.0 * u * v - 1.0;
      float qu = 4.0 * (1.0 - 2.0 * u - v);
      float qv = 4.0 * (1.0 - u - 2.0 * v);
    
      return min(min(smoothstep(0.0, sc, qf), smoothstep(0.0, sc, qu + qf)),
                 min(smoothstep(0.0, sc, qv + qf), smoothstep(0.0, sc, 4.0 + qu + qv + qf)));
}

void main(void)
{
        vec2 aspect = resolution.xy / resolution.y;
        vec2 uv = ( gl_FragCoord.xy / resolution.y ) - 0.5 * aspect;
        uv *= DISP_SCALE;
        
        // specify the fixed points; vary the pole's position
        vec3 col = mix(C2, C1, hexpack(moebius(vec2(1.0, 1.0), -vec2(1.0, 1.0), vec2(8.0, 6.0) * cis(time), uv)));

        glFragColor = vec4( col, 1.0 );
}
