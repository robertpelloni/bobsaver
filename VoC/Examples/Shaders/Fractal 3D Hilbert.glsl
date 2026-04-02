#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/tlf3zX

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// The MIT License
// Copyright © 2019 J. M.
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

// Display a 3D Hilbert curve (https://en.wikipedia.org/wiki/Hilbert_curve)

// colors

#define BG vec3(0.18, 0.28, 0.23)
#define COL vec3(0.12, 0.56, 1.0)

// Skilling's algorithm, https://doi.org/10.1063/1.1751381 and https://doi.org/10.1063/1.1751382
// see also http://www.inference.org.uk/bayesys/test/hilbert.c and compare with https://www.shadertoy.com/view/3tl3zl

vec3 hilbert( in int k, in int s )
{
    int bb = 1 << s, b = bb;
    ivec3 t = ivec3(k ^ (k >> 1));
    ivec3 hp = ivec3(0);
    
    for( int j = s - 1; j >= 0; j-- )
    {
        b >>= 1;
        hp += (t >> (2 * j + ivec3(2, 1, 0))) & b;
    }  

    for( int p = 2; p < bb; p <<= 1 )
    {
        int q = p - 1;

        if( (hp.z & p) != 0 ) hp.x ^= q;
        else hp.xz ^= (hp.x ^ hp.z) & q;

        if( (hp.y & p) != 0 ) hp.x ^= q;
        else hp.xy ^= (hp.x ^ hp.y) & q;

        if( (hp.x & p) != 0 ) hp.x ^= q;
    }
    
    return 2.0 * (vec3(hp)/float(bb - 1)) - 1.0;
}

// line segment distance

float segment(vec2 p, vec2 a,vec2 b) { 
    p -= a, b -= a;
    return length(p - b * clamp(dot(p, b) / dot(b, b), 0.0, 1.0));
}

// rotation matrix

#define rot(a) mat2(cos(a), -sin(a), sin(a), cos(a))
    
// 3D -> 2D projection

vec2 proj( in float p, in float c, in vec3 P )
{
    float q = -p * sqrt(1.0 - c * c);

    return mat3x2(-p, q, 0.0, c, p, q) * P;
}

// 3D curve drawing, adapted from https://www.shadertoy.com/view/4lyyWw by Fabrice Neyret

void main(void)
{
    float ep = 5.0/resolution.y;
    vec2 aspect = resolution.xy / resolution.y;
    vec2 uv = ( gl_FragCoord.xy / resolution.y ) - 0.5 * aspect;
    uv *= 3.2;
    
    int s = (int(floor(0.5 * time)) % 3) + 1; // iteration stage of Hilbert curve
    int n = 1 << (3 * s); // Hilbert curve points
    vec3 P, Pn;
    vec2 pb, p;
    float d = 100.0, dt;
    
    for (int i = 0; i < n; i++)
    {
        P = hilbert(i, s);
 
        P.xz *= rot(2.0 * time); // rotation
        p = proj(sqrt(0.5), 0.9, P); // screen projection

        if (i > 0)
        {
            dt = segment(uv, pb, p) * (( 5.0 - P.z )/9.0); // draw segment with thickening factor
            if (dt < d) { d = dt; Pn = P; } // keep nearest
        }
        
        pb = p;
    }
    
    float da = 0.5 + 0.5 * mix(0.8, 1.0, Pn.y); // darkening at the bottom
    glFragColor = vec4(mix(BG, mix(vec3(0.0), COL, da), smoothstep(ep, 0.0, d)), 1.0);
}
