#version 420

// original https://www.shadertoy.com/view/Wt2SRm

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/***********************************************************

   A world entirely made out of a scalar field!
   The whole thing is one giant fluffy scattering cloud-type thing! :)

   Trees are fractal trees made with splitting stem cells...

   The grass is something I invented called melon grass!
   It's four ellipsoids each contributing a thin slice to make a grass patch.
   Three versions of the patch are repeated indefinitely across the plains.
   Each patch orientates at its origin against the sinusoidal height field.

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
#define CORE_RADIUS 0.1
#define FLUFF_RADIUS 1.2
#define FLUFF_POWER 0.1 * min (1.0 - max (sin(time), 0.0), 0.9)
#define DRAW_DISTANCE 15.0

// Blue noise...
float _2dNoise (vec2 forPos)
{
    float noiseVal = 0.0;//texture (iChannel0, forPos).r;
    return 0.9 + noiseVal * 0.1;
}

/******************* FRACTAL TREES USING SPLITTING STEMS **********************/
float circle(vec2 uv, vec2 center, float rad, float fluffRad)
{
    vec2 diffVec = uv - center;
    float distSq = dot(diffVec, diffVec);
    float rSq = rad * rad;
    float rTSq = rad + fluffRad;
    rTSq *= rTSq;
    if ( distSq < rSq )
        return 1.0;
    else if ( distSq < rTSq )
        return clamp (1.0 - pow((distSq - rSq)/(fluffRad * fluffRad), FLUFF_POWER), 0.0, 1.0);
    else
        return 0.0;
}

float splitCell(vec2 uv, float inpTime, float spread)
{
    if ( inpTime < 0.0 || inpTime > M_PI ) return 0.0;
    float timeProg = clamp(inpTime, 0.0, M_PI * 0.5);
    float timeProg2 = clamp(inpTime - M_PI * 0.5, 0.0, M_PI * 0.5);
    float sinTimeProg = sin(timeProg);
    float sinTimeProg2 = sin(timeProg2);
    float res1 = max(circle(uv, vec2 (sinTimeProg2, sinTimeProg) * spread, CORE_RADIUS, FLUFF_RADIUS), circle (uv, vec2 (sinTimeProg2, -sinTimeProg) * spread, CORE_RADIUS, FLUFF_RADIUS));
    float res2 = max(circle(uv, vec2 (-sinTimeProg2, sinTimeProg) * spread, CORE_RADIUS, FLUFF_RADIUS), circle (uv, vec2 (-sinTimeProg2, -sinTimeProg) * spread, CORE_RADIUS, FLUFF_RADIUS));
    return max (res1, res2);
}

float splitCell2(vec2 uv, float inpTime, float spread)
{
    if ( inpTime < M_PI )
        return splitCell (uv, inpTime, spread);
    else if ( inpTime < M_PI * 2.0 )
    {
        float res1 = splitCell (uv + vec2 ( spread,  spread), inpTime - M_PI, spread * 0.5);
        float res2 = splitCell (uv + vec2 ( spread, -spread), inpTime - M_PI, spread * 0.5);
        float res3 = splitCell (uv + vec2 (-spread,  spread), inpTime - M_PI, spread * 0.5);
        float res4 = splitCell (uv + vec2 (-spread, -spread), inpTime - M_PI, spread * 0.5);
        return max (max (res1, res2), max (res3, res4));
    }
    else if ( inpTime < M_PI * 3.0 )
    {
        float curMaxRes = 0.0;
        for (int i = 0; i != 4; i++)
        {
            vec2 subOffset = vec2 (spread);
            if ( i == 1 ) subOffset *= vec2 (1.0, -1.0);
            else if ( i == 2 ) subOffset *= vec2 (-1.0, 1.0);
            else if ( i == 3 ) subOffset *= vec2 (-1.0, -1.0);
            float res1 = splitCell (uv + vec2 ( spread,  spread) + subOffset * 0.5, inpTime - M_PI * 2.0, spread * 0.25);
            float res2 = splitCell (uv + vec2 ( spread, -spread) + subOffset * 0.5, inpTime - M_PI * 2.0, spread * 0.25);
            float res3 = splitCell (uv + vec2 (-spread,  spread) + subOffset * 0.5, inpTime - M_PI * 2.0, spread * 0.25);
            float res4 = splitCell (uv + vec2 (-spread, -spread) + subOffset * 0.5, inpTime - M_PI * 2.0, spread * 0.25);
            curMaxRes = max (max (max (res1, res2), max (res3, res4)), curMaxRes);
        }
        return curMaxRes;
    }
    else
        return 0.0;
}

float fractalTree (vec3 inpCoord)
{
    if ( inpCoord.y > M_PI * 3.0 ) return 0.0;
    else if ( inpCoord.y > 0.0 && inpCoord.y < M_PI * 3.0 ) return splitCell2 (inpCoord.xz, inpCoord.y, 4.0);
    else if ( inpCoord.y < 0.0) return circle (inpCoord.xz, vec2 (0.0), CORE_RADIUS, FLUFF_RADIUS);
}
/******************************************************************************/

// 2D rotate
mat2 rot2D (float ang)
{
    return mat2 (cos(ang), -sin(ang), sin(ang), cos(ang));
}

/******************* THE FLOOR HEIGHT FIELD **********************/
float floorEq (vec2 inpCoord)
{
    return (sin(inpCoord.x) + 1.0) * 0.5 + (sin(inpCoord.y) + 1.0) * 0.5;
}
/*****************************************************************/

/********************* MELON GRASS!!! **********************/
// I call this melon grass... :)
// It's grass made from 4 stripes on 4 melon-like shapes next to each other
float melonGrass (vec3 inpCoord)
{
    inpCoord.y /= 3.0;
    if ( inpCoord.y < -2.0 || inpCoord.y > -1.0 ) return 0.0;
    vec3 coordFract = fract (inpCoord) * 2.4 - 1.2;

    // Orientate the grass patch against the height field...
    vec3 centerOnFloor = floor (inpCoord) + 0.5;
    vec3 tanVec = vec3 (0.02, floorEq(centerOnFloor.xz + vec2 (0.01, 0.0)) - floorEq(centerOnFloor.xz - vec2 (0.01, 0.0)), 0.0);
    vec3 biTanVec = vec3 (0.0, floorEq(centerOnFloor.xz + vec2 (0.0, 0.01)) - floorEq(centerOnFloor.xz - vec2 (0.0, 0.01)), 0.02);
    vec3 norm = normalize (cross (tanVec, biTanVec));
    if ( norm.y < 0.0 ) norm = -norm;
    biTanVec = normalize (cross (norm, tanVec));
    tanVec = cross (biTanVec, norm);
    mat3 grassPatchSpace;
    grassPatchSpace[0] = tanVec;
    grassPatchSpace[1] = norm;
    grassPatchSpace[2] = biTanVec;
    
    // Bring sample point into local grass patch space...
    coordFract = inverse (grassPatchSpace) * coordFract;

    if ( coordFract.y < 0.0 ) return 0.0; // Cut below the melon
    
    vec3 toMelon1 = coordFract - vec3 ( 1.0, 0.0,  0.0);
    vec3 toMelon2 = coordFract - vec3 (-1.0, 0.0,  0.0);
    vec3 toMelon3 = coordFract - vec3 ( 0.0, 0.0,  1.0);
    vec3 toMelon4 = coordFract - vec3 ( 0.0, 0.0, -1.0);

    float result1 = 0.0, result2 = 0.0, result3 = 0.0, result4 = 0.0;
    if ( normalize (toMelon1.xz).x < -0.99 ) result1 = 1.0 - pow((min (abs(dot (toMelon1,toMelon1) - 1.0), 3.0) / 3.0), FLUFF_POWER * 0.1);
    if ( normalize (toMelon2.xz).x >  0.99 ) result2 = 1.0 - pow((min (abs(dot (toMelon2,toMelon2) - 1.0), 3.0) / 3.0), FLUFF_POWER * 0.1);
    if ( normalize (toMelon3.xz).y < -0.99 ) result3 = 1.0 - pow((min (abs(dot (toMelon3,toMelon3) - 1.0), 3.0) / 3.0), FLUFF_POWER * 0.1);
    if ( normalize (toMelon4.xz).y >  0.99 ) result4 = 1.0 - pow((min (abs(dot (toMelon4,toMelon4) - 1.0), 3.0) / 3.0), FLUFF_POWER * 0.1);
    return max (max (result1, result2), max (result3, result4));
}
/***********************************************************/

/*************** THE ENTIRE WORLD COMBINED ***************/
float worldDensity (vec3 inpCoord)
{
    if ( inpCoord.y < -6.0 + floorEq (inpCoord.xz) ) return 1.0;
    
    mat2 rot1 = rot2D (M_PI *  0.2);
    mat2 rot2 = rot2D (M_PI * -0.1);
    mat2 rot3 = rot2D (M_PI *  0.35);

    vec3 treeCoord = inpCoord;
    treeCoord.xz = rot1 * (fract (inpCoord.xz / 5.0) * 20.0 - 10.0);
    float worldDensity = 0.0;
    worldDensity = max (fractalTree (treeCoord), worldDensity);
    
    vec3 grassCoord1 = inpCoord, grassCoord2 = inpCoord, grassCoord3 = inpCoord;
    grassCoord1.xz = rot2 * inpCoord.xz + vec2 ( 0.2, 0.3);
    grassCoord2.xz = rot1 * inpCoord.xz + vec2 (-0.1, 0.45);
    grassCoord3.xz = rot3 * inpCoord.xz + vec2 (0.35, 0.12);
    
    worldDensity = max (melonGrass (grassCoord1), worldDensity);
    worldDensity = max (melonGrass (grassCoord2), worldDensity);
    worldDensity = max (melonGrass (grassCoord3), worldDensity);
    return worldDensity;
}
/*********************************************************/

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.xy * 2.0 - 1.0;
    
    vec3 curEye = vec3 (0.0, 1.0, -5.0) + vec3 (time, 0.0, time);
    vec3 sampleDir = normalize (vec3 (uv, 1.0)) * 0.01 * _2dNoise (uv);
    vec3 samplePt = curEye + sampleDir;
    float scat = 1.0;
    float finalColor = 0.0;

    for (;;)
    {
        float fader = max (DRAW_DISTANCE - length (samplePt - curEye), 0.0)/ DRAW_DISTANCE;
        float densityEval = worldDensity (samplePt);
        if ( densityEval > 0.001 )
        {
            finalColor += scat * densityEval * fader;
            scat *= exp (-densityEval);
        }
        if ( scat < 0.1 ) break;
        if ( fader == 0.0 ) break;
        samplePt += sampleDir;
    }

    // Output to screen
    glFragColor = vec4(vec3 (finalColor),1.0);
}
