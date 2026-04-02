#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/3ls3RX

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// The MIT License
// Copyright © 2019 J. M.
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

// Demonstrating an experimental 3D Worley noise implementation.
// A little bit of something old, something new, and something borrowed.

// XY range of the display.

#define DISP_SCALE 6.0 

// rescaling functions

float rescale(float x, vec2 range)
{
      float a = range.x, b = range.y;
      return (x - a)/(b - a);
}

float rescale(float x, vec2 r1, vec2 r2)
{
      float a = r1.x, b = r1.y;
      float c = r2.x, d = r2.y;
      return c + (d - c) * ((x - a)/(b - a));
}

// modified MATLAB bone colormap

vec3 lake( float t )
{
     return vec3((2.0 * t + 1.0)/3.0, min(4.0 * t, 2.0 * t + 1.0)/3.0, min(0.8 * t + 0.5, 1.0 - 0.1 * t));
}

// simple LCG

#define LCG(k) k = (65 * k) % 1021
#define lr(k) float(k)/1021.

// permutation polynomial

int permp (int i1, int i2)
{
      int t = (i1 + i2) & 255;
        
      return ((112 * t + 153) * t + 151) & 255;
}

// return the two closest distances for 3D Worley noise
// type controls the type of metric used

vec2 worley(int type, vec3 p)
{
    vec2 dl = vec2(20.0);
    ivec3 iv = ivec3(floor(p));
    vec3 fv = fract(p);
    
    int j = 0; // initialization for Knuth's "algorithm L"
    ivec3 di = ivec3(1), ki = -di;
    ivec4 fi = ivec4(0, 1, 2, 3);
    
    // instead of writing a triply nested loop (!!)
    // generate the indices for the neighbors in Gray order (Knuth's "algorithm L")
    // see section 7.2.1.1 of TAOCP, Volume 4A or https://doi.org/10.1145/360336.360343
    
    for (int k = 0; k < 27; k++) // loop through all neighbors
    { 
         // seeding
        int s = permp(permp(permp(0, iv.z + ki.z), iv.y + ki.y), iv.x + ki.x); LCG(s);
            
         for (int m = 0; m < 2; m++) // two points per cell
             {
                // generate feature points within the cell
                LCG(s); float sz = lr(s);
                LCG(s); float sy = lr(s);
                LCG(s); float sx = lr(s);
                
                vec3 tp = vec3(ki) + vec3(sx, sy, sz) - fv;
                float c = 0.0;
                if (type == 1) c = dot(tp, tp); // Euclidean metric
                if (type == 2) c = abs(tp.x) + abs(tp.y) + abs(tp.z); // Manhattan metric
                if (type == 3) c = max(abs(tp.x), max(abs(tp.y), abs(tp.z))); // Chebyshev metric
                
                float m1 = min(c, dl.x); // ranked distances
                dl = vec2(min(m1, dl.y), max(m1, min(max(c, dl.x), dl.y)));
             }
        
        // updating steps for Knuth's "algorithm L"
        j = fi[0]; fi[0] = 0; ki[2 - j] += di[j];
        if ((ki[2 - j] & 1) == 1) {
            di[j] = -di[j];
            fi[j] = fi[j + 1]; fi[j + 1] = j + 1;
        }
    }
    
    if (type == 1) dl = sqrt(dl); // don't forget to root at the end for Euclidean distance
        
    return dl;
}

void main(void)
{
        vec2 aspect = resolution.xy / resolution.y;
        vec2 uv = ( gl_FragCoord.xy / resolution.y ) - 0.5 * aspect;
        uv *= DISP_SCALE;
        uv += time;
    
        vec2 w = worley(int(0.05 * time) % 3 + 1, vec3(uv, -0.2 * time));

        // split image adapted from Inigo Quilez; https://www.shadertoy.com/view/ll2GD3
        float ry = gl_FragCoord.y / resolution.y;
        vec3                  col = lake(rescale(w.x, vec2(0.0, 1.0)));
        if ( ry > (1.0/3.0) ) col = lake(rescale(length(w.xy)/(w.y + w.x) - w.x, vec2(0.0, 1.4)));
        if ( ry > (2.0/3.0) ) col = lake(rescale((2.0 * w.y * w.x)/(w.y + w.x) - w.x, vec2(0.0, 0.3)));

        // borders
        col *= smoothstep( 0.5, 0.48, abs(fract(3.0 * ry) - 0.5) );

        glFragColor = vec4( vec3(col), 1.0 );
}
