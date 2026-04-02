#version 420

// original https://www.shadertoy.com/view/WtlXRf

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/******************************************************************************
Copyright (c) 2019 TooMuchVoltage Software Inc.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

******************************************************************************/

/******************************************************************************

Hit me up!

Twitter: twitter.com/toomuchvoltage
Facebook: fb.com/toomuchvoltage
YouTube: youtube.com/toomuchvoltage
Website: www.toomuchvoltage.com

******************************************************************************/

float dopplerEffect (in vec2 uv)
{
    float pendulumFactor = 8.0 * sin (time);
    float fringeFactor = 0.5 * sin (time);
    
    float offset = 0.0;
    for (int i = 0; i < 3; i++)
    {
        // % needs GLSL 3.0
        float newOffset = fract (float(i)/2.0) == 0.0 ? sin(length(uv + offset * pendulumFactor) + time) : cos(length(uv + offset * fringeFactor) + time);
        offset = (newOffset + 1.0) * 0.5;
    }
    return offset;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy/resolution.xy) * 80.0 - 40.0;
    glFragColor = vec4(vec3 (dopplerEffect (uv)),1.0);
}
