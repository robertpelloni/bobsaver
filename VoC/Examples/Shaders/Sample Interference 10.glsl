#version 420

// original https://www.shadertoy.com/view/ttXGWf

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// The MIT License
// Copyright © 2019 J. M.
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

// simulated interference patterns

//some constants

#define PI 3.14159265359

// XY range of the display.

#define DISP_SCALE 8.0

// custom colormap

vec3 marine( float t )
{
     return vec3(max(3.0 * t + 3.0, 19.0 * t - 5.0)/18.0, max(10.0 * t, 18.0 * t - 4.0)/15.0, min(3.0 * t + 1.0, t + 2.0)/3.0);
}

// function for simulated interference pattern

float interf(vec2 p)
{
      float t = 4.0 * time; // phase
      vec2 p1 = vec2(-4.0, 0.0), p2 = vec2(4.0, 0.0); // sources
    
      if (mouse*resolution.xy.xy != vec2(0.0))
      {
          p2 = DISP_SCALE * ( mouse*resolution.xy.xy - 0.5 * resolution.xy) / resolution.y; // move one source
      }

      return cos(2.0 * PI * distance(p, p1) - t) + cos(2.0 * PI * distance(p, p2) - t);
}

void main(void)
{
        vec2 aspect = resolution.xy / resolution.y;
        vec2 uv = ( gl_FragCoord.xy / resolution.y ) - 0.5 * aspect;
        uv *= DISP_SCALE;
        
        float z = interf(uv);
        glFragColor.rgb = marine(0.25 * (z + 2.0));
    
        // gradient using forward differences
        float h = 0.5 * DISP_SCALE/resolution.y;
        vec2 grad = z - vec2(interf(uv + vec2(h, 0.0)), interf(uv + vec2(0.0, h)));

        // lighting angles for shading
        float th = 0.75 * PI, ph = 0.25 * PI;
        
        // shading factor
        glFragColor.rgb *= 1.0 - 0.25 * (1.0 + cos(ph) * dot(vec2(cos(th), sin(th)), grad)/(pow(h, 1.4) + length(grad)));

        glFragColor.a = 1.0;
}
