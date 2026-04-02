#version 420

// original https://www.shadertoy.com/view/mdVcWD

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// The MIT License
// Copyright © 2023 Pascal Gilcher
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

//
// Efficient implementation of the original Peano Curve / Peano Monofractal
// discovered by Guiseppe Peano in 1890
//
// In literature, all space filling curves are sometimes referred to as Peano curves,
// such as the Hilbert curve or the Z-Curve.
//

#define LEVELS 7 

//top down is a bit harder to wrap my head around, 
//but the order reversal of the indices is easier this way
int peano(ivec2 p, int level)
{
    int i = 0;
    for(int b = int(round(pow(3.0, float(level)))); b > 0; b /= 3) //b = blocksize
    {
        ivec2 t = p / b;        
        int ti = 3 * t.x + t.y + (t.x * 2 & 2) * (1 - t.y);         //the 3x3 snake       
        i = i * 9 + ti;                                             //add current octave to total      

        p -= b * t;                                                 //p %= blocksize       
                                                                    
        if(t.y == 1) p.x = b - p.x - 1;                             //flip sub-blocks so next subfractals connect  
        if(t.x == 1) p.y = b - p.y - 1;       
    }
    
    return i;
}

//thanks IQ
vec3 hsv2rgb(in vec3 c)
{
    vec3 rgb=clamp(abs(mod(c.x*6.0+vec3(0.0,4.0,2.0),6.0)-3.0)-1.0, 0.0, 1.0 );
    return c.z*mix(vec3(1.0),rgb,c.y);
}

vec3 gradient(float t) 
{
    float h = 0.6666 * (1.0 - t*t);
    float s = 0.75;
    float v = 1.0 - 0.9*(1.0 - t) * (1.0 - t);
    return hsv2rgb(vec3(h,s,v));    
}

void main(void)
{   
    uint N = uint(round(pow(3.0, float(LEVELS)))) ; 
    
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    uv = uv * 2.0 - 1.0;    
    
    float r = max(0.0, 1.0 - dot(uv, uv) * 0.3);   
    glFragColor = vec4(r);      
     
    uv.x *= resolution.x / resolution.y;
    uv *= 1.3;
    
    float fade = max(abs(uv.x), abs(uv.y)) - 1.0;
    
    glFragColor *= fade / (0.005 + fade);
     
    if(abs(uv.x) < 1.0 && abs(uv.y) < 1.0)
    {
        uv = uv * 0.5 + 0.5;
        ivec2 pos = ivec2(uv * float(N));
        
        uint mode = uint(time*0.125) % 3u;
        
        int i = peano(pos, LEVELS);        
        float t = float(i) / float(N * N);
        t = fract(t - time * 0.125);
        glFragColor = vec4(gradient(t), 1.0);        
    }  
}
