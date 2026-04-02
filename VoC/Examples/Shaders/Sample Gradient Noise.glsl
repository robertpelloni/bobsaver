#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/WtsGz2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// The MIT License
// Copyright © 2019 J. M.
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

// An experimental implementation of gradient noise
// still being actively modified and tweaked

// XY range of the display.

#define DISP_SCALE 8.0 

// modified MATLAB bone colormap

vec3 nbone( float t )
{
     return 0.875 * t + 0.125 * clamp(vec3(4.0, 3.0, 3.0) * t - vec3(3.0, 0.0, 1.0), 0.0, 1.0);
}

// permutation polynomial

int permp (int i1, int i2)
{
      int t = (i1 + i2) & 255;
        
      return ((112 * t + 153) * t + 151) & 255;
}

// generate gradients per cell and take their dot product

float grd( ivec2 il, vec2 x )
{
    int id = (65 * permp(permp(0, il.y), il.x)) % 1021;
    
    vec2 gs = vec2(2 - abs(4 - ((id - ivec2(4, 6)) & 7)));
    
    return dot(clamp(gs, -1.0, 1.0), x);
}

float noisen( in vec2 p )
{
    ivec2 i = ivec2(floor( p ));
    ivec2 r = ivec2(1, 0);
    vec2 f = fract( p );
    vec2 h = vec2(1.0, 0.0);
    
    // vec2 u = f * f * (3.0 - 2.0 * f); // uncomment to use cubic version
    vec2 u = f * f * f * ((6.0 * f - 15.0) * f + 10.0); // quintic version

    return mix(mix(grd(i, f), grd(i + r, f - h), u.x),
               mix(grd(i + r.yx, f - h.yx), grd(i + r.xx, f - h.xx), u.x), u.y);
}

// Inigo Quilez's example gradient noise, https://www.shadertoy.com/view/XdXGW8

vec2 hash( vec2 x )
{
    const vec2 k = vec2( 0.3183099, 0.3678794 );
    x = x * k + k.yx;
    return 2.0 * fract( 16.0 * k * fract( x.x * x.y * (x.x + x.y)) ) - 1.0;
}

float noise( in vec2 p )
{
    vec2 i = floor( p );
    vec2 f = fract( p );
    vec2 h = vec2(1.0, 0.0);
    
    // vec2 u = f * f * (3.0 - 2.0 * f); // original
    // for a straight comparison, modified to use a quintic as well, per Perlin
    vec2 u = f * f * f * ((6.0 * f - 15.0) * f + 10.0);

    return mix( mix( dot( hash( i ), f ), 
                     dot( hash( i + h ), f - h ), u.x),
                mix( dot( hash( i + h.yx ), f - h.yx ), 
                     dot( hash( i + h.xx ), f - h.xx ), u.x), u.y);
}

void main(void)
{
        vec2 aspect = resolution.xy / resolution.y;
        vec2 uv = ( gl_FragCoord.xy / resolution.y ) - 0.5 * aspect;
        uv = DISP_SCALE * uv + time;
    
        vec2 p = gl_FragCoord.xy / resolution.xy;
    
        float f = 0.0;
    
        if( p.y < 0.5 ) // show IQ version
        {
            // left: noise    
            if( p.x < 0.6 )
            {
                f = noise( 4.0 * uv );
            }
            // right: fractal noise (4 octaves)
            else    
            {
                uv *= 2.0;
                mat2 m = mat2( 1.6,  1.2, -1.2,  1.6 );
                f  = 0.5000 * noise( uv ); uv *= m;
                f += 0.2500 * noise( uv ); uv *= m;
                f += 0.1250 * noise( uv ); uv *= m;
                f += 0.0625 * noise( uv );
            }
        } else { // show experimental version
            // left: noise    
            if( p.x < 0.6 )
            {
                f = noisen( 4.0 * uv );
            }
            // right: fractal noise (4 octaves)
            else    
            {
                uv *= 2.0;
                mat2 m = mat2( 1.6,  1.2, -1.2,  1.6 );
                f  = 0.5000 * noisen( uv ); uv *= m;
                f += 0.2500 * noisen( uv ); uv *= m;
                f += 0.1250 * noisen( uv ); uv *= m;
                f += 0.0625 * noisen( uv );
            }
        }

        f = 0.5 + 0.5 * f;
        // draw borders
        f *= smoothstep( 0.0, 0.005, abs(p.x - 0.6) ) * smoothstep( 0.0, 0.005, abs(p.y - 0.5) );

        glFragColor = vec4( nbone(f), 1.0 );
}
