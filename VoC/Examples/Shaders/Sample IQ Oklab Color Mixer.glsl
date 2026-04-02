#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/ttcyRS

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// The MIT License
// Copyright © 2020 Inigo Quilez
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

// Optimized linear-rgb color mix in oklab space, useful
// when our software operates in rgb space but we still
// we want to have intuitive color mixing - note the
// unexpected purples introduced when blending in rgb
// space (right columns) vs the intuitive transitions
// produced by the oklab color space (left columns).
//
// Now, when mixing linear rgb colors in oklab space, the
// linear transform from cone to Lab space and back can be
// omitted, saving three 3x3 transformation per blend!
//
// oklab was invented by Björn Ottosson: https://bottosson.github.io/posts/oklab
//
// More oklab on Shadertoy: https://www.shadertoy.com/view/WtccD7

vec3 oklab_mix( vec3 colA, vec3 colB, float h )
{
    // https://bottosson.github.io/posts/oklab
    const mat3 kCONEtoLMS = mat3(                
         0.4121656120,  0.2118591070,  0.0883097947,
         0.5362752080,  0.6807189584,  0.2818474174,
         0.0514575653,  0.1074065790,  0.6302613616);
    const mat3 kLMStoCONE = mat3(
         4.0767245293, -1.2681437731, -0.0041119885,
        -3.3072168827,  2.6093323231, -0.7034763098,
         0.2307590544, -0.3411344290,  1.7068625689);
                    
    // rgb to cone (arg of pow can't be negative)
    vec3 lmsA = pow( kCONEtoLMS*colA, vec3(1.0/3.0) );
    vec3 lmsB = pow( kCONEtoLMS*colB, vec3(1.0/3.0) );
    // lerp
    vec3 lms = mix( lmsA, lmsB, h );
    // cone to rgb
    return kLMStoCONE*(lms*lms*lms);
}

//====================================================

// example colors
const vec3 kCols[6] = vec3[6]( 
    vec3(1.00,1.00,1.00), vec3(0.00,0.00,1.00),
    vec3(0.00,0.00,1.00), vec3(1.00,0.70,0.01),
    vec3(0.91,0.14,0.01), vec3(0.01,0.20,1.00) );
    
void main(void)
{
    // normalized pixel coordinates (from 0 to 1)
    vec2 p = gl_FragCoord.xy/resolution.xy;

    // choose colors to lerp
    int id = int(floor(p.x*6.0));
    int ba = id & 6; // yes, AND!
    vec3 colA = kCols[ba+0];
    vec3 colB = kCols[ba+1];
    
    // linear interpolation, left oklab, right rgb
    vec3 col = ((id&1)==0) ? oklab_mix( colA, colB, p.y ) :
                                   mix( colA, colB, p.y );
                                   
    // black separators
    col *= smoothstep(0.01,0.015,abs(fract(p.x*6.0+0.5)-0.5));
    
    // linear to gamma
    col = pow( col, vec3(0.4545) );

    // output
    glFragColor = vec4( col, 1.0 );
}
