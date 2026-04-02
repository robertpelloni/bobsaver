#version 420

// original https://www.shadertoy.com/view/wtXGRS

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// The MIT License
// Copyright © 2019 J. M.
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

// density plotter (https://www.shadertoy.com/view/WtX3RS) experiment

// XY range of the display.
#define DISP_SCALE 8.0

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

// modified MATLAB hot colormap

vec3 myhot( float t )
{
     return clamp(vec3(3.0, 3.0, 4.0) * t - vec3(0.0, 1.1, 2.9), 0.0, 1.0);
}

// noise functions adapted from Inigo Quilez (https://www.shadertoy.com/view/lsl3RH)
// with (some) tweaks

const mat2 m = mat2( 0.36,  0.93, -0.93,  0.36 );

float noise( in vec2 p )
{
    return sin(0.62 * p.x) * cos(1.38 * p.y);
}

float fbm4( vec2 p )
{
    float f = 0.0;
    f += 0.5000 * noise( p ); p = m * p * 1.62;
    f += 0.2500 * noise( p ); p = p * m * 1.62;
    f += 0.1250 * noise( p ); p = m * p * 1.62;
    f += 0.0625 * noise( p );
    return clamp(0.5 * f, 0.0, 1.0);
}

float f(vec2 p)
{
      return sin(p.x + sin(p.y)); // base function
}

void main(void)
{
        vec2 aspect = resolution.xy / resolution.y;
        vec2 uv = ( gl_FragCoord.xy / resolution.y ) - 0.5 * aspect;
        uv *= DISP_SCALE;
        
        vec3 col = myhot(rescale(f(uv + time + (2.2 + 0.3 * time * vec2(1.6, 0.4)) * fbm4(uv - 0.007 * fract(time))), vec2(-1.0, 1.0)));

        glFragColor = vec4( vec3(col), 1.0 );
}
