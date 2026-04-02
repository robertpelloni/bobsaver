#version 420

// original https://www.shadertoy.com/view/NtlXzf

uniform int frames;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// ####### Zi7ar21's KIFS #######
// Made by Jacob Bingham (Zi7ar21) on July 13th, 2021

// Last Updated on July 13th, 2021 at 21:20 Mountain Standard Time

// If you found this anywhere except Shadertoy, the original and possibly updated version can be found at:
// https://www.shadertoy.com/view/NtlXzf

// "License":
// You can use this code in any way you want, as long as you keep credits to things that aren't mine
// e.g. Triple32: https://nullprogram.com/blog/2018/07/31/
// We are programmers, not lawyers! :)

/*
It's crazy just how simple a KIFS fractal is!

Features:
- KIFS Fractal
- Ray-Marching
- Soft Shadows
- Glow
- Orbit Trap Colors
- Animation
*/

// Check out my friends!
// michael0884
// https://www.shadertoy.com/user/michael0884
// loicvdb
// https://www.shadertoy.com/user/loicvdb
// Dumb_Psycho
// https://www.shadertoy.com/user/Dumb_Psycho
// peabrainiac
// https://www.shadertoy.com/user/peabrainiac

// ##### Parameters #####

// Camera Field of View
#define camfov 1.0

// Tonemap Exposure
#define exposure 1.0

// Maximum Ray-Marching Steps
#define maxStep 128

// Distance Considered a Collision
#define hitDist 1E-3

// Maximum Ray-Marching Distance
#define maxDist 4.0

// Maximum Shadow Ray Distance
#define shadowDist 2.0

// ##### Preprocessor #####

// I don't know if I am using these properly so I will leave them disabled by default
//#pragma optimize(on)
//#pragma debug(off)

// ##### Constants #####

// http://www.mimirgames.com/articles/programming/digits-of-pi-needed-for-floating-point-numbers/
#define pi 3.141592653589793

// Traditional Uniform Identifiers
#define resolution resolution
#define frame frames
#define time time
//#define time (float(frame)/60.0)
//#define time 0.0

// ##### Rendering #####

// Rotate a 3-Component Vector
vec3 rotate(vec3 vec, vec3 rot)
{
    vec3 s = sin(rot), c = cos(rot);

    mat3 rotx = mat3(
    1.0, 0.0, 0.0,
    0.0, c.x,-s.x,
    0.0, s.x, c.x);
    mat3 roty = mat3(
    c.y, 0.0,-s.y,
    0.0, 1.0, 0.0,
    s.y, 0.0, c.y);
    mat3 rotz = mat3(
    c.z,-s.z, 0.0,
    s.z, c.z, 0.0,
    0.0, 0.0, 1.0);

    mat3 rotmat = rotx*roty*rotz;

    /*
    rotmat[0] = normalize(rotmat[0]);
    rotmat[1] = normalize(rotmat[1]);
    rotmat[2] = normalize(rotmat[2]);
    */

    return (vec.x*rotmat[0])+(vec.y*rotmat[1])+(vec.z*rotmat[2]);
}

// Root Object SDF
float SDF(vec3 pos)
{
    // Sphere
    //return length(pos)-1.0;

    // Cube
    //pos = abs(pos);
    return max(max(pos.x, pos.y), pos.z)-1.0;
}

// Zi7ar21's KIFS SDF: https://www.shadertoy.com/view/NtlXzf
float DE(in vec3 pos, out vec3 orbitTrap)
{
    // Fractal Parameters
    vec3 rot = mod(vec3(time*pi*0.05, -0.5+(time*pi*0.023), 0.3+(time*pi*0.03)), 2.0);
    //const vec3 rot = vec3(-0.6, -0.5, 0.3);
    const vec3 translate = vec3(-0.1, -0.23, -0.17);
    const float scale = 1.3;

    // Set-Up Variables
    orbitTrap = vec3(10.0);
    float t = 1.0;

    // Iterate the Fractal
    for(int i = 0; i < 16; i++)
    {
        // Scale
        pos *= scale;
        t *= scale;

        // Rotate
        pos = rotate(pos, rot*pi);

        // Mirror
        pos = abs(pos);

        // Orbit Trap
        orbitTrap = min(pos, orbitTrap);

        // Translate
        pos += translate;
    }

    // Return the Distance Estimate
    return SDF(pos)/t;
}

// SDF Tetrahedron Numerical Normals
vec3 sampleNormal(vec3 pos)
{
    const vec2 k = vec2(-1.0, 1.0);
    vec3 n;
    return normalize(
    k.xxx*DE(pos+k.xxx*hitDist, n)+
    k.xyy*DE(pos+k.xyy*hitDist, n)+
    k.yxy*DE(pos+k.yxy*hitDist, n)+
    k.yyx*DE(pos+k.yyx*hitDist, n));
}

// Distance Estimator Soft Shadows
float sampleLight(vec3 ro, vec3 rd)
{
    float res = 1.0;
    float t = 0.0;
    float ph = 1E4;
    vec3 n;
    for(int i = 0; i < maxStep; i++)
    {
        float h = DE(ro+rd*t, n);
        float y = i == 0 ? 0.0 : h*h/(2.0*ph);
        float d = sqrt(h*h-y*y);

        res = min(res, 10.0*d/max(0.0, t-y));

        t += h;

        if(res < hitDist || t > shadowDist){break;}
    }

    res = clamp(res, 0.0, 1.0);

    return res*res*(3.0-2.0*res);
}

// Intersection Structure
struct intersection {
    float tMin;
    float tMax;
    bool hit;
    bool expire;
    vec3 normal;
    vec3 albedo;
    vec3 emission;
};

// Ray-Marching
intersection trace(vec3 ro, vec3 rd)
{
    // Set-Up Variables
    float t = 0.0;
    vec3 emission = vec3(0.0);
    vec3 color = vec3(0.0);

    // Ray-Marching
    for(int i = 0; i < maxStep; i++)
    {
        // Check if the Ray "Hit" the Background
        if(t > maxDist)
        {
            // Return the Intersection Data
            return intersection(-1.0, -1.0, false, false, vec3(0.0), vec3(1.0, 0.0, 1.0), emission);
        }

        float td = DE(ro+rd*t, color);

        // Check if the Ray Hit the Scene
        if(td < hitDist)
        {
            // Return the Intersection Data
            return intersection(t, -1.0, true, false, sampleNormal(ro+rd*t), clamp(color*10.0, 0.0, 1.0), emission);
        }

        // Add to Glow
        emission += max(exp(-td*10.0), 0.0)*0.03;

        // "March" the Ray
        t += td;
    }

    // Ray Expired (Increase maxStep!)
    return intersection(-1.0, -1.0, false, true, vec3(0.0), vec3(1.0, 0.0, 1.0), vec3(0.0));
}

// Rendering
vec3 radiance(vec3 ro, vec3 rd)
{
    // Compute the Intersection
    intersection t = trace(ro, rd);

    // If the Ray expired, output Debug Magenta color
    if(t.expire)
    {
        // Magenta/Cyan Pattern
        //return int(gl_FragCoord.xy.x+gl_FragCoord.xy.y)/4 % 2 == 0 ? vec3(10.000, 00.000, 10.000) : vec3(00.000, 10.000, 10.000);

        // Magenta
        return vec3(100.0, 0.0, 100.0);
    }

    // If the Ray never hit anything, output the background color
    if(!t.hit)
    {
        return vec3(0.000, 0.000, 0.000)+t.emission;
    }

    // Light Direction
    const vec3 lightDirection = vec3(0.577350269189626, 0.577350269189626, 0.577350269189626);

    // Compute Lighting
    float lighting0 = sampleLight(ro+rd*t.tMin, lightDirection);
    float lighting1 = max(dot(t.normal, lightDirection), 0.0)*0.95;
    float lighting2 = max(dot(t.normal,-lightDirection), 0.0)*0.15;

    // Output the Final Color
    return t.albedo*lighting0*(lighting1+lighting2+0.05)+t.emission;
}

// Render and Output the Frame
void main(void)
{
    // Screen UV Coordinates
    vec2 uv = 2.0*(gl_FragCoord.xy-0.5*resolution.xy)/max(resolution.x, resolution.y);

    // Set-Up Camera
    const vec3 ro = vec3(0.0, 0.0, 2.0);
    const mat3 rotmat = mat3(1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0);
    vec3 rd = normalize(vec3(camfov*uv, -1.0)*rotmat);

    // Render the Frame
    vec3 color = radiance(ro, rd);

    // HDR Tonemapping
    color = clamp(1.0-exp(-max(color, 0.0)*exposure), 0.0, 1.0);

    // Output the Rendered Frame
    glFragColor = vec4(color, 1.0);
}
