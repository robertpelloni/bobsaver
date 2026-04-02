#version 420

// original https://www.shadertoy.com/view/3tsBDX

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Trying to build stacked crosssectional plates of animated 3d noise, to mimic this work: 
//https://jacobjoaquin.tumblr.com/post/188120374046/jacobjoaquin-volumetric-noise-20190225
//
// Using the noise algorithm from this shader by iq: https://www.shadertoy.com/view/4sfGzS
// then making it have octaves.
//
// TODO: Make the plates square and isometric.
// TODO: Fix the noise so that builds in from both up as well as down.
// TODO: Correctly just overlay the colours of each upper disc on the lower discs, if the upper pixel is not transparent.  Need to model alpha.
// TODO: don't calculate a noise value that is going to be thrown away!
// DONE: add contour border colour to separate the layers of noise, and then make them opaque.
//         - sort of.  Not sure of simulating blend mode blend and just overlaying the pixels.

// DONE: add border colour to the rim of each plate (discs, for now), then make them otherwise transparent.

//license from the noise sketch: https://www.shadertoy.com/view/4sfGzS
// The MIT License
// Copyright © 2013 Inigo Quilez
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

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

//===============================================================================================
//===============================================================================================
//===============================================================================================

float hash(vec3 p)  // replace this by something better
{
    p  = fract( p*0.3183099+.1 );
    p *= 17.0;
    return fract( p.x*p.y*p.z*(p.x+p.y+p.z) );
}

float noise( in vec3 x )
{
    vec3 i = floor(x);
    vec3 f = fract(x);
    f = f*f*(3.0-2.0*f);
    
    return mix(mix(mix( hash(i+vec3(0,0,0)), 
                        hash(i+vec3(1,0,0)),f.x),
                   mix( hash(i+vec3(0,1,0)), 
                        hash(i+vec3(1,1,0)),f.x),f.y),
               mix(mix( hash(i+vec3(0,0,1)), 
                        hash(i+vec3(1,0,1)),f.x),
                   mix( hash(i+vec3(0,1,1)), 
                        hash(i+vec3(1,1,1)),f.x),f.y),f.z);
}

//===============================================================================================
//===============================================================================================
//===============================================================================================
//===============================================================================================
//===============================================================================================

const mat3 m = mat3( 0.00,  0.80,  0.60,
                    -0.80,  0.36, -0.48,
                    -0.60, -0.48,  0.64 );

float octaveNoise(in vec2 realuv, in float time){
    float f = 0.0;
    
    //scale
    vec2 uv = realuv * 8.0;
    
    mat2 m = mat2( 1.6,  1.2, -1.2,  1.6 );
    
    f  = 0.7 * noise( vec3(uv, time*0.6)  ); 
    
    uv = m*uv;    
    f += 0.3 * noise( vec3(uv, time*0.2+100.)  ); 

    return 0.5 + 0.5*f;
}

float findEdgeOfNoise(in float n, in float a, in float b, in float borderWidth){
    float f1 = smoothstep( a, b, n);
    float f2 = smoothstep( b, b+borderWidth, n);
    return f1 - f2;
}

float circleMask(in float r, in vec2 realuv){
    vec2 squishedUV = (realuv-vec2(0, .5))*vec2(1., 2);
    float distToCentre =1.- length(squishedUV - vec2(1.,0.50));
    return smoothstep(r, r+0.003, distToCentre);
}

float circleBorderMask(in float r, in vec2 realuv){
    vec2 squishedUV = (realuv-vec2(0, .5))*vec2(1., 2);
    float distToCentre =1.- length(squishedUV - vec2(1.,0.50));
    return 1.-smoothstep(0., 0.005, abs(r- distToCentre));
}

void main(void)
{
    bool doSecondColour = false;
    bool doPlateBorders = true;
    
    vec2 p = gl_FragCoord.xy / resolution.xy;

    vec2 realuv = p*vec2(resolution.x/resolution.y,1.0);
    

    float discRadius =0.65;
    int numLayers = 20;
    float layerSpacing = 0.5 / float(numLayers);
    float time = time;
    
    vec3 col = vec3(0.);
    for(int i =0; i < numLayers; i++){
        vec3 plateCol = vec3(0.);
        vec2 plateOffset = vec2(0., 0.45-layerSpacing * float(i));

        vec2 apparentUV = realuv.xy + plateOffset;
        float apparentTime = time*1. + 0.3 * float(i);
        
        //generate noise, find the stepped body of it, find the edge of it.
        float f = octaveNoise(apparentUV, apparentTime);    
        float n1 = smoothstep( 0.79, 0.791, f);
        float n2 = smoothstep( 0.62, 0.625, f);
        
        
        float nBorder = findEdgeOfNoise(f, 0.782, 0.79, 0.001);
        float nBorder2 = findEdgeOfNoise(f, 0.62, 0.625, 0.001);
        
        float discMaskV = circleMask(discRadius, realuv + plateOffset);
        
        // Mask the noise by the shape of the disk (and set alpha to 40%)
        plateCol.xy += 1. * n1 * discMaskV;
        
        if (doSecondColour){
            plateCol.xz += 1. * (1. - n2) * discMaskV;
        }

        // Add a circular border/rim to each plate
        // First, delete whatever was underneath - hacky.  just blend a top plate with black
        if (doPlateBorders){
            col *= 1. - vec3(circleBorderMask(discRadius, realuv + plateOffset));
            plateCol += 0.2 * vec3(circleBorderMask(discRadius, realuv + plateOffset));
        }

        // Add black border around noise
        col *= 1. - nBorder* discMaskV;
        if (doSecondColour){
            // Add black border around second colour of noise
            col *= 1. - nBorder2* discMaskV;
        }

        //TODO: we want to draw the colours of this plate over the top of existing colours not add.  However, we need to track pixel alpha for that, too.
        // Put the plate colour over the existing colours
        col += plateCol;
    }
    
     glFragColor = vec4(col, 1.0);
}
