#version 420

// original https://www.shadertoy.com/view/tlcfzH

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// The MIT License
// Copyright © 2020 Inigo Quilez
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

// Fork of original work here: https://www.shadertoy.com/view/tldSRj
//
// A wave based noise, similar to gabor and all its variants but much
// simplified, originially explored in shadertoy by user robobo1221
// in this shader: https://www.shadertoy.com/view/wttSRj
//
// It is comparable in speed to traditional gradient noise (if the
// architecture supports fast sin/cos, like GPUs do anyways), but
// slower than value noise of course. The advantage is that it's
// infinitely derivable. It can also be easily animated by moving
// the waves over time or rotating the gradients, which is fun.
//
// But the main advantage is that it can generate a wormy look, as
// in robobo1221's original shader, by changing the constant in 
// line 52 to be closer to 1.75 .

// Value    Noise 2D, Derivatives: https://www.shadertoy.com/view/4dXBRH
// Gradient Noise 2D, Derivatives: https://www.shadertoy.com/view/XdXBRH
// Value    Noise 3D, Derivatives: https://www.shadertoy.com/view/XsXfRH
// Gradient Noise 3D, Derivatives: https://www.shadertoy.com/view/4dffRH
// Value    Noise 2D             : https://www.shadertoy.com/view/lsf3WH
// Value    Noise 3D             : https://www.shadertoy.com/view/4sfGzS
// Gradient Noise 2D             : https://www.shadertoy.com/view/XdXGW8
// Gradient Noise 3D             : https://www.shadertoy.com/view/Xsl3Dl
// Simplex  Noise 2D             : https://www.shadertoy.com/view/Msf3WH
// Wave     Noise 2D             : https://www.shadertoy.com/view/tldSRj

// Like sin() but repeats every 2.0 instead of 2.0*pi, and almost as smooth.
// This is mostly here so CPU versions of this can be a bit faster.
float sway(float x)
{
    float f = fract(x);
    return (f*f*(12.0-8.0*f) - 2.0) * (floor(fract(x*0.5)*2.0) - 0.5);
}

// You should replace this hash by one that you like and meets
// your needs. This one is here just as example and should not
// be used in production.
//vec2 g( vec2 n ) { return sin(n.x*n.y*vec2(12., 17.)+vec2(1.,2.)); }
vec2 g( vec2 n ) { return sin(n.x*n.y*vec2(12.5, 17.)+vec2(1.375,0.625)); }
//vec2 g( vec2 n ) { return sin(n.x*n.y+vec2(0,1.571)); } // if you want the gradients to lay on a circle

float noise(vec2 p)
{
    vec2 i = floor(p);
    vec2 f = fract(p);
    //// Uncomment the line below to see worm-y shapes. Adjust 1.75 as desired.
    //p *= 1.75;
    f = f*f*(3.0-2.0*f);
    return mix(mix(sway(dot(p,g(i+vec2(0,0)))),
                      sway(dot(p,g(i+vec2(1,0)))),f.x),
               mix(sway(dot(p,g(i+vec2(0,1)))),
                      sway(dot(p,g(i+vec2(1,1)))),f.x),f.y);
}

void main(void)
{
    vec2 p = gl_FragCoord.xy / resolution.xy;

    vec2 uv = p*vec2(resolution.x/resolution.y,1.0);

    float f = 0.0;
    
    // left: noise    
    if( p.x<0.2 )
    {
        f = noise( 24.0*uv );
    }
    // right: fractal noise (4 octaves)
    else    
    {
        uv *= 8.0;
        mat2 m = mat2( 1.6,  1.2, -1.2,  1.6 );
        f  = 0.5000*noise( uv ); uv = m*uv;
        f += 0.2500*noise( uv ); uv = m*uv;
        f += 0.1250*noise( uv ); uv = m*uv;
        f += 0.0625*noise( uv ); //uv = m*uv;
    }

    f = 0.5 + 0.5*f;
    
    f *= smoothstep( 0.0, 0.005, abs(p.x-0.2) );    
    
    glFragColor = vec4( f, f, f, 1.0 );
}
