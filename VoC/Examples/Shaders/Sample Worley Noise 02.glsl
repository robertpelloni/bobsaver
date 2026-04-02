#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/ttf3R2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// The MIT License
// Copyright © 2019 J. M.
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

// Yet another Worley noise implementation.
// A little bit of something old, something new, and something borrowed.

// XY range of the display.

#define DISP_SCALE 6.0 

// rescaling functions

float logistic(float x)
{
      float ex = exp(-abs(x));
      return ((x >= 0.0) ? 1.0 : ex)/(1.0 + ex);
}

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

vec3 bone( float t )
{
     return 0.875 * t + 0.125 * clamp(vec3(4.0, 3.0, 3.0) * t - vec3(3.0, 1.0, 0.0), 0.0, 1.0);
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

// return the two closest distances for Worley noise
// type controls the type of metric used

vec2 worley(int type, vec2 p)
{
    vec2 dl = vec2(20.0);
    ivec2 iv = ivec2(floor(p));
    vec2 fv = fract(p);
    
    for (int j = -1; j <= 1; j++)
        for (int i = -1; i <= 1; i++)
        {
            // seeding
            int s = permp(permp(0, iv.y + j), iv.x + i); LCG(s);
            
            for (int m = 0; m < 2; m++) // two points per cell
            {
                // generate feature points within the cell
                LCG(s); float sy = lr(s);
                LCG(s); float sx = lr(s);
                
                vec2 tp = vec2(i, j) + vec2(sx, sy) - fv;
                float c = 0.0;
                if (type == 1) c = dot(tp, tp); // Euclidean metric
                if (type == 2) c = abs(tp.x) + abs(tp.y); // Manhattan metric
                if (type == 3) c = max(abs(tp.x), abs(tp.y)); // Chebyshev metric
                
                float m1 = min(c, dl.x); // ranked distances
                dl = vec2(min(m1, dl.y), max(m1, min(max(c, dl.x), dl.y)));
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
    
        vec2 w = worley(int(0.1 * time) % 3 + 1, uv + time);

        // split image adapted from Inigo Quilez; https://www.shadertoy.com/view/ll2GD3
        float ry = gl_FragCoord.y / resolution.y;
        vec3                  col = bone(rescale(w.x, vec2(0.0, 1.0)));
        if ( ry > (1.0/3.0) ) col = bone(rescale(length(w)/(w.y + w.x) - w.x, vec2(0.0, 1.4)));
        if ( ry > (2.0/3.0) ) col = bone(rescale((2.1 * w.y * w.x)/(w.y + w.x) - w.x, vec2(0.0, 0.3)));

        // borders
        col *= smoothstep( 0.5, 0.48, abs(fract(3.0 * ry) - 0.5) );

        glFragColor = vec4( vec3(col), 1.0 );
}
