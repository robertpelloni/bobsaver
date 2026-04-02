#version 420

// original https://www.shadertoy.com/view/3ts3WN

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// The MIT License
// Copyright © 2019 J. M.
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

// Basic domain coloring plot (https://en.wikipedia.org/wiki/Domain_coloring)
// of the inverse Gudermannian function w = gd^(-1)(z) (https://en.wikipedia.org/wiki/Gudermannian_function)

#define PI 3.14159265359
#define TWOPI 6.28318530718
#define SCALE 7.5 // plot scale
#define XY_SPACING 1.0 // Cartesian grid line spacing
#define R_SPACING 1.5 // polar grid line spacing

// modified version of Inigo Quilez's method at https://www.shadertoy.com/view/MsS3Wc
// using "rational smoothstep" from https://tpfto.wordpress.com/2019/03/28/on-a-rational-variant-of-smoothstep/
vec3 smooth_hue( float h )
{
    vec3 rgb = clamp( abs(mod(6.0 * h + vec3(0.0, 4.0, 2.0), 6.0) - 3.0) - 1.0, 0.0, 1.0);
    return rgb * rgb * rgb/(1.0 - 3.0 * rgb * (1.0 - rgb));
}

// modified DLMF coloring, adapted from https://www.shadertoy.com/view/WtXGWN
vec3 smooth_dlmf( float h )
{
    vec3 rgb = clamp( vec3(1., -1., -1.) * abs((vec3(8., 4., 8.) * mod(h, 1.0) - vec3(4.5, 1.5, 5.5))) + vec3(-1.5, 1.5, 2.5), 0.0, 1.0 );
    return rgb * rgb * rgb/(1.0 - 3.0 * rgb * (1.0 - rgb));
}

// Inverse Gudermannian function

vec2 invgd( in vec2 z )
{
    float sx = sin(z.x);
    float cy = cosh(z.y);
    return vec2(0.5 * log((cy + sx)/(cy - sx)), atan(sinh(z.y), cos(z.x)));
}

void main(void)
{
    vec2 z = SCALE * ((gl_FragCoord.xy/min(resolution.x, resolution.y)) - vec2(0.875, 0.5));
    z.x += time;
    
    vec2 w = invgd(z);
    float ph = atan(w.y, w.x);
    float lm = log(0.0001 + length(w));
    
    vec3 cd = smooth_dlmf(0.5 * (ph / PI));
    vec3 ch = smooth_hue(0.5 * (ph / PI));
    // transition between normal hue and DLMF coloring
    vec3 c = mix(cd, ch, 0.5 + 0.5 * cos(2.0 * time));

    float sat = abs(sin(TWOPI * lm/R_SPACING));
    float bri = pow(sin(TWOPI * w.x/XY_SPACING) * sin(TWOPI * w.y/XY_SPACING), 0.25);
    bri = max(1.0 - sat, bri);
    sat = sqrt(sat);

    glFragColor = vec4(bri * mix( vec3(1.0), c, sat), 1.0);
}
