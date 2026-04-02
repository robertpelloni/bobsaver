#version 420

// original https://www.shadertoy.com/view/ttVSDW

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// The MIT License
// Copyright © 2020 Inigo Quilez
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

// This is my own take on al13n's perturbation idea in this
// shader https://www.shadertoy.com/view/XtdBR7, but using a
// more simple and direct method; instead of linearizing the
// Taylor expansion I simply directly track the delta growth
// under the z²+c iteration.
//
// The trick is that if the reference orbit is in the interior
// of the M-set, it won't diverge and numbers will stay sane.
// Then, the nearby points of the plane will produce orbits that
// will deviate from the reference orbit just a little, little
// enough that the difference can be expressed with single
// precision floating point numbers. So this code iterates the
// reference orbit Zn and also the current orbit Wn in delta form:
//
// Given
//
// Zn and Wn = Zn + ΔZn
// 
// Then
//
// Zn+1 = f(Zn) = Zn² + C
// Wn+1 = f(Wn) = f(Zn+ΔZn) = (Zn+ΔZn)² + C + ΔC = 
//              = Zn² + ΔZn² + 2·Zn·ΔZn + C+ΔC = 
//              = Zn+1 + ΔZn·(ΔZn + 2·Zn) + ΔC = 
//              = Zn+1 + ΔZn+1
//
// So, what we need to iterate is
//
// ΔZn+1 = (ΔZn² + ΔC) + 2·Zn·ΔZn  --> hopefully small valued 
//  Zn+1 = ( Zn² +  C)             --> periodic orbit, doesn't diverge

vec2 cmul(vec2 a, vec2 b) { return vec2(a.x*b.x-a.y*b.y, a.x*b.y+a.y*b.x); }

float mandelbrot(vec2 c)
{
    float n = -1.0;
    vec2 z = vec2(0.0);
    for( int i=0; i<6000; i++ )
    {
        z = cmul(z,z) + c;
        if( dot(z,z)>4.0 ) { n=float(i); break; }
    }
    return n;
}

float mandelbrot_perturbation( vec2 c, vec2 dc )
{
    vec2 z  = vec2(0.0);
    vec2 dz = vec2(0.0);
    float n = -1.0;
    for( int i=0; i<6000; i++ )
    {
        dz = cmul(2.0*z+dz,dz) + dc;
        z  = cmul(z,z)+c; // this could be precomputed for the whole image
        
        // instead of checking for Wn to escape...
        // if( dot(z+dz,z+dz)>4.0 ) { n=float(i); break; }
        // ... we only check ΔZn, since Zn is periodic and can't escape
        if( dot(dz,dz)>4.0 ) { n=float(i); break; }
    }
    return n;
}

#define AA 1

void main(void)
{
    // input
    float time = time+0.2;
    
    //float s = (mouse*resolution.xy.z<0.001) ? -cos(time*2.0)*1.8 : (2.0*mouse*resolution.xy.x-resolution.x) / resolution.y;
    float s = -cos(time*2.0)*1.8;
    
    vec3 col = vec3(0.0);
    #if AA>1
    for( int m=0; m<AA; m++ )
    for( int n=0; n<AA; n++ )
    {
        vec2 p = (2.0*(gl_FragCoord.xy+vec2(float(m),float(n))/float(AA))-resolution.xy)/resolution.y;
    #else
        vec2  p = (2.0*gl_FragCoord.xy-resolution.xy)/resolution.y;
    #endif
    
        // viewport
        float zoom; vec2 c;
        if( sin(time)>0.0 ) { zoom=1.5e-6; c=vec2(-1.1900443,0.3043895); }
        else                { zoom=1.0e-6; c=vec2(-0.7436441,0.1318255); }

        // mandelbrot    
        vec2 dc = p*zoom;
        float l = (p.x<s) ? mandelbrot_perturbation(c, dc) : 
                            mandelbrot(c + dc);
        // color
        col += (l<0.0) ? vec3(0.0) : 0.5 + 0.5*cos( pow(zoom,0.22)*l*0.05 + vec3(3.0,3.5,4.0));

        // reference orbit
        if( length(p)<0.02 ) col = vec3(1.0,0.0,0.0);

        // separator
        if( abs(p.x-s)<2.0/resolution.y) col = vec3(1.0);
    #if AA>1
    }
    col /= float(AA*AA);
    #endif
    
    // output    
    glFragColor = vec4(col,1.0);
}
