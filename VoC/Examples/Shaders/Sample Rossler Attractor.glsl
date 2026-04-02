#version 420

// original https://www.shadertoy.com/view/wtS3zz

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// The MIT License
// Copyright © 2019 J. M.
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

// Plotting the Rössler attractor (https://en.wikipedia.org/wiki/R%C3%B6ssler_attractor) by integrating the ODEs

// colors

#define BG vec3(0.18, 0.28, 0.23)
#define COL vec3(0.86, 0.15, 0.27)

// maximum number of steps

#define MAXSTEPS 950

// ODE for Rössler attractor

vec3 rhs( float t, vec3 p )
{
    float x = p.x, y = p.y, z = p.z;
    const float a = 0.25, b = 0.2, c = 4.6; // parameters
    
    return vec3(-y - z, b + y * (x - c), x + a * z);
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
    float ep = 40.0/resolution.y;
    vec2 aspect = resolution.xy / resolution.y;
    vec2 uv = ( gl_FragCoord.xy / resolution.y ) - 0.5 * aspect;
    uv = 35.0 * uv + vec2(0.0, 5.5); // shift and scale to fit in window
    
    vec3 P = vec3(0.0, 0.0, 1.0); // initial conditions
    float t = 0.0, tmax = 60.0; // integration interval
    
    vec3 Pn, Pt, P1;
    vec2 pb, p;
    float d = 1.0e3, dt;
    
    float h = tmax/float(MAXSTEPS); // step size
    
    for (int i = 0; i <= MAXSTEPS; i++)
    {
        if (i > 0) // explicit midpoint method, https://en.wikipedia.org/wiki/Midpoint_method
        {
            P1 = P + 0.5 * h * rhs(t, P);
            P += h * rhs(t + 0.5 * h, P1);
            t += h;
        }
 
        Pt = P;
        Pt.xz *= rot(2.2 * time); // rotation
        p = proj(sqrt(0.5), 0.8, Pt); // screen projection

        if (i > 0)
        {
            dt = segment(uv, pb, p) * (( 35.0 - Pt.z )/45.0); // draw segment with thickening factor
            if (dt < d) { d = dt; Pn = Pt; } // keep nearest
        }
        
        pb = p;
    }
    
    float da = 0.5 + 0.5 * mix(0.8, 1.0, Pn.y); // darker at the bottom
    glFragColor = vec4(mix(BG, mix(vec3(0.0), COL, da), smoothstep(ep, 0.0, d)), 1.0);
}
