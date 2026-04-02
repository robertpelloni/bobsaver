#version 420

// original https://www.shadertoy.com/view/3tSXRG

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/***********************************************************

   Ohhhhhhhhhh Canada!!!
   Presenting: Maple LeaSDF v2.0
   An SDF of a maple leaf! :)
   With AO and some direct lighting... 

   Covered under the MIT license:

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

   Hit me up! :)
   Twitter: twitter.com/toomuchvoltage
   Facebook: fb.com/toomuchvoltage
   YouTube: youtube.com/toomuchvoltage
   Mastodon: https://mastodon.gamedev.place/@toomuchvoltage
   Website: www.toomuchvoltage.com

************************************************************/

#define M_PI 3.1415926535
#define DRAW_DISTANCE 55.0
#define THICKNESS 0.15

float opSmoothUnion( float d1, float d2, float k )
{
    float h = clamp( 0.5 + 0.5*(d2-d1)/k, 0.0, 1.0 );
    return mix( d2, d1, h ) - k*h*(1.0-h);
}

float sdTriPrism(vec3 p, vec2 h)
{
    vec3 q = abs(p);
    return max(q.z-h.y,max(q.x*0.866025+p.y*0.5,-p.y)-h.x*0.5);
}

float sdBox (vec3 p, vec3 b)
{  
    vec3 d = abs(p) - b;
    return length(max(d,0.0)) + min(max(d.x,max(d.y,d.z)),0.0);
}

float petiole (vec3 p, vec3 b)
{
    p.x = -abs(p.x); // x and z symmetry
    p.z = -abs(p.z);
    
    vec3 d = abs(p) - b;
    float boxDf = length(max(d,0.0)) + min(max(d.x,max(d.y,d.z)),0.0);
    vec2 norm1 = normalize (vec2 (1.0, -0.05));
    return max(boxDf, -(dot (p.xy, norm1) - b.x * 0.2)); // Add slant... (cutting with planes)
}

float leafMiddle (vec3 p, vec3 b)
{
    p.x = -abs(p.x); // x and z symmetry
    p.z = -abs(p.z);
    
    vec3 d = abs(p) - b;
    float boxDf = length(max(d,0.0)) + min(max(d.x,max(d.y,d.z)),0.0);
    vec2 norm1 = normalize (vec2 (1.0, 0.2));
    vec2 norm2 = normalize (vec2 (-1.0, -1.5));
    float boxCutDf = max(boxDf, -(dot (p.xy, norm1) + b.x * 0.6)); // Add slant... (cutting with planes)
    float boxCutSnippedDf = max(boxCutDf, -(dot(p.xy, norm2) + b.y * 0.5)); // Add snip...
    float joinedWithTip = opSmoothUnion (sdTriPrism((p + vec3 (0.0, -0.8, 0.0)), vec2 (0.57, THICKNESS)), boxCutSnippedDf, 0.05); // Add tip
    float planeSlicer = p.z+THICKNESS; // Smooth out the surface
    return max (joinedWithTip, -planeSlicer);
}

float leafMiddleFatter (vec3 p, vec3 b)
{
    p.x = -abs(p.x); // x and z symmetry
    p.z = -abs(p.z);
    
    vec3 d = abs(p) - b;
    float boxDf = length(max(d,0.0)) + min(max(d.x,max(d.y,d.z)),0.0);
    vec2 norm1 = normalize (vec2 (1.0, 0.07));
    vec2 norm2 = normalize (vec2 (-1.0, -1.5));
    float boxCutDf = max(boxDf, -(dot (p.xy, norm1) + b.x * 0.85)); // Add slant... (cutting with planes)
    float boxCutSnippedDf = max(boxCutDf, -(dot (p.xy, norm2) + b.y * 0.5)); // Add snip...
    float joinedWithTip = opSmoothUnion (sdTriPrism((p + vec3 (0.0, -0.7, 0.0)), vec2 (0.43, THICKNESS)), boxCutSnippedDf, 0.05); // Add tip
    float planeSlicer = p.z+THICKNESS; // Smooth out the surface
    return max (joinedWithTip, -planeSlicer);
}

float leafSide (vec3 p)
{
    float rotCos, rotSin;
    mat4 rotMat;
    
    // Rotate to the side...
    rotCos = cos(-0.25 * M_PI);
    rotSin = sin(-0.25 * M_PI);
    rotMat[0] = vec4 ( rotCos, rotSin, 0.0, 0.0);
    rotMat[1] = vec4 (-rotSin, rotCos, 0.0, 0.0);
    rotMat[2] = vec4 ( 0.0   ,    0.0, 1.0, 0.0);
    rotMat[3] = vec4 ( 0.75  ,   -0.7, 0.0, 1.0);
    
    vec3 newP = (inverse (rotMat) * vec4 (p, 1.0)).xyz;

    float sd1 = leafMiddleFatter (newP, vec3 (0.5, 0.9, THICKNESS));
    
    return sd1;
}

float MapleLeaSDF (vec3 p)
{
    p.x = abs(p.x); // x and z symmetry
    p.z = -abs(p.z);

    float sd1 = leafMiddle (p, vec3 (0.75, 1.1, THICKNESS));
    
    float sd2 = leafSide(p);
    
    float leafTop = opSmoothUnion (sd1, sd2, 0.1); // Smooth crevices
    
    float leafBase = sdTriPrism(p + vec3 (0.0, 1.2, 0.0), vec2 (1.0, THICKNESS));
    vec2 norm1 = normalize (vec2 (0.1, 1.0));
    float leafBaseCut = max(leafBase, -(dot (p.xy, norm1) + 1.6));
    
    float leafTotal = opSmoothUnion (min(leafTop, leafBaseCut), petiole (p + vec3 (0.0, 1.4, 0.0), vec3 (0.05, 1.0, THICKNESS)), 0.1);
    
    float planeSlicer = p.z+THICKNESS; // Smooth out the surface
    return max (leafTotal, -planeSlicer);
}

vec4 scene (vec3 p)
{
    float leaf = MapleLeaSDF (p);
    float bg = -sdBox (p - vec3 (0.0, 2.56, 0.0), vec3 (5.0));
    float retDist = min(leaf, bg);
    if ( retDist == leaf )
        return vec4 (retDist, vec3 (1.0, 0.0, 0.0));
    else
        return vec4 (retDist, vec3 (1.0, 1.0, 1.0));
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.xy * 2.0 - 1.0;
    uv.y *= 0.6;
    
    float distToLeaf = 4.0 + sin(time);
    vec3 curEye = vec3 (sin(time) * distToLeaf, -1.4 + sin(time), cos(time) * distToLeaf);
    vec3 sampleLook = -normalize (curEye);
    
    vec3 side = cross (vec3 (0.0, -1.0, 0.0), sampleLook);
    vec3 up = cross (side, sampleLook);
    if ( dot (up, vec3 (0.0, 1.0, 0.0)) < 0.0 ) up = -up;
    
    vec3 sampleDir = normalize (sampleLook + side * uv.x + up * uv.y);
    vec3 samplePt = curEye + sampleDir;
    float finalColor = 0.0;

    for (float jj = 0.0; jj != 1.0; jj += 0.0)
    {
        vec4 curDistColor = scene (samplePt);
        if (abs(curDistColor.r) < 0.001)
        {
            float gradD = 0.01;
            float gradX = scene (samplePt + vec3 ( gradD, 0.0, 0.0)).r - scene (samplePt - vec3 ( gradD, 0.0, 0.0)).r;
            float gradY = scene (samplePt + vec3 ( 0.0, gradD, 0.0)).r - scene (samplePt - vec3 ( 0.0, gradD, 0.0)).r;
            float gradZ = scene (samplePt + vec3 ( 0.0, 0.0, gradD)).r - scene (samplePt - vec3 ( 0.0, 0.0, gradD)).r;

            vec3 ourNorm = normalize (vec3 (gradX, gradY, gradZ));
            vec3 toEyeNorm = normalize (curEye - samplePt);
            float atten = 5.0/length (curEye - samplePt);
            vec3 color = vec3 (atten * dot (ourNorm, toEyeNorm) * curDistColor.gba); // Diffuse light from the viewer
            
            float AOTerm = 0.0;
            AOTerm += scene (samplePt + 0.01 * ourNorm).r / 0.01;
            AOTerm += scene (samplePt + 0.02 * ourNorm).r / 0.02;
            AOTerm += scene (samplePt + 0.03 * ourNorm).r / 0.03;
            AOTerm += scene (samplePt + 0.1 * ourNorm).r / 0.1;
            AOTerm += scene (samplePt + 0.15 * ourNorm).r / 0.15;
            AOTerm += scene (samplePt + 0.2 * ourNorm).r / 0.2;
            AOTerm /= 6.0;
            color *= AOTerm;
            
            glFragColor = vec4(pow(color, vec3(1.0/2.2)), 1.0); // Gamma correct before output
            return ;
        }
        samplePt += curDistColor.r*sampleDir;
        if ( length (samplePt - curEye) > DRAW_DISTANCE ) break;
    }

    glFragColor = vec4(0.0);
}
