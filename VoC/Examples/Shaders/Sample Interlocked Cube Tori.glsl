#version 420

// original https://www.shadertoy.com/view/stVfDw

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// https://www.shadertoy.com/view/stVfDw interlocked cube tori, 2022 by Jakob Thomsen
// based on https://www.shadertoy.com/view/7dK3D3 Branchless Voxel Raycasting Tex
// using DDA from https://www.shadertoy.com/view/4dX3zl Branchless Voxel Raycasting by fb39ca4
// (with loop optimization by kzy), based on http://lodev.org/cgtutor/raycasting.html
// 3d-texture on voxels addon by jt

// Tiling space with interlocked loops (colored), gaps filled up with cuboids (grey).
// (This structure refines https://www.shadertoy.com/view/styfRG interlocked grids.)
// Animation shows different parts of the structure:
//     0. loops
//     1. outer grid
//     2. inner grid
//     3. combined
//     4. offset loops
//     5. offset outer grid
//     6. offset inner grid
//     7. offset combined
//     9-11 and 12 to 15 repeats steps for grid and offset grid combined.

// Towards filling space symmetrically (non-chiral) with interlocked bricks.

// tags: 3d, raycasting, voxel, dda, textured, interlocked, loop, torus, torii, cube, honeycomb, tiling, tesselation, space-filling, BCC

#define REPETITIONS 2u

#define BLACK 0u
#define RED (BLACK + 1u)
#define GREEN (RED + 1u)
#define YELLOW (GREEN + 1u)
#define BLUE (YELLOW + 1u)
#define MAGENTA (BLUE + 1u)
#define CYAN (MAGENTA + 1u)
#define WHITE (CYAN + 1u)
#define COLORS (WHITE + 1u)

vec3 palette(uint i)
{
    return vec3((i >> 0u) & 1u, (i >> 1u) & 1u, (i >> 2u) & 1u);
}

// two half-patterns fit together to fill one cube exactly in a body-centred cubic (BCC) lattice pattern.
uint half_pattern(ivec3 i, uint stage)
{
    i = abs(i); // global mirror-symmetry (to make sure "mod" works for negative numbers)
    i -= 6*(i / 6); // mod 6
    i -= 3; // move zero
    i = abs(i); // local mirror-symmetry

    if(stage == 0u || stage == 3u)
    {
        // loops / tori
        if(i.z == 3 && max(i.y, i.x) == 2) return BLUE;
        if(i.y == 3 && max(i.x, i.z) == 2) return GREEN;
        if(i.x == 3 && max(i.z, i.y) == 2) return RED;
    }
    
    if(stage == 1u || stage == 3u)
    {
        // outer grid
        //if(i.x == 3 && i.y == 3 && i.z == 3) return WHITE; // omit small cubes for better visibility (keep cuboids distinct)
        if(i.x == 3 && i.y == 3 && i.z < 3) return WHITE;
        if(i.y == 3 && i.z == 3 && i.x < 3) return WHITE;
        if(i.z == 3 && i.x == 3 && i.y < 3) return WHITE;
    }
    
    if(stage == 2u || stage == 3u)
    {
        // inner grid
        //if(i.x == 2 && i.y == 2 && i.z == 2 ) return WHITE; // omit small cubes for better visibility (keep cuboids distinct)
        if(i.x == 2 && i.y == 2 && i.z < 2 ) return WHITE;
        if(i.y == 2 && i.z == 2 && i.x < 2 ) return WHITE;
        if(i.z == 2 && i.x == 2 && i.y < 2 ) return WHITE;
    }

    return 0u;
}

// Fills one unit cell (composed of 6^3 voxels).
uint pattern(ivec3 i, uint stage)
{
    // NOTE: using bit-operators rather than modulo because of % bugs on windows

    stage = stage & 15u;

    if(stage < 4u || stage >= 8u)
    {
        uint c = half_pattern(i, stage & 3u);
        if(c > 0u)
            return c;
    }

    if(stage >= 4u || stage >= 8u)
    {
        uint c = half_pattern(i-3, stage & 3u);
        if(c == WHITE) // HACK: keep color to avoid transparency when inverting colors below
            return c;
        if(c > 0u)
            return WHITE - c;
    }

    return 0u;
}

#define PI 3.1415926

float checker(vec3 p)
{
    //return step(0.5, length(1.0 - abs(2.0 * fract(p) - 1.0))); // dots
    return step(0.0, sin(PI * p.x + PI/2.0)*sin(PI *p.y + PI/2.0)*sin(PI *p.z + PI/2.0));
    //return step(0.0, sin(p.x)*sin(p.y)*sin(p.z));
}

mat2 rotate(float t)
{
    return mat2(vec2(cos(t), sin(t)), vec2(-sin(t), cos(t)));
}

float sdSphere(vec3 p, float d)
{ 
    return length(p) - d;
} 

float sdBox( vec3 p, vec3 b )
{
    vec3 d = abs(p) - b;
    return min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0));
}

bool getVoxel(ivec3 c, uint stage)
{
    if(any(greaterThan(abs(c), ivec3(REPETITIONS * 6u)))) return false;
    return pattern(c, stage) > 0u;
}

// "The raycasting code is somewhat based around a 2D raycasting toutorial found here: 
//  http://lodev.org/cgtutor/raycasting.html" (fb39ca4)

#define MAX_RAY_STEPS (24u * (1u << REPETITIONS))

void main(void)
{
    uint stage = uint(floor(time / 5.0));

    vec2 screenPos = 2.0 * gl_FragCoord.xy / resolution.xy - 1.0;
    screenPos.x *= resolution.x / resolution.y;
    vec3 rayDir = vec3(screenPos.x, screenPos.y, 2.0);
    vec3 rayPos = vec3(0.0, 0.0, -float(REPETITIONS * 16u));

    float mx = 2.0 * PI * float(-mouse*resolution.xy.x) / float(resolution.x);
    float my = PI * float(-mouse*resolution.xy.y) / float(resolution.y);
    mx = 2.0 * PI * fract(time * 0.055);
    my = PI / 2.0;

    mat2 S = mat2(vec2(cos(my), sin(my)), vec2(-sin(my), cos(my)));
    rayPos.yz = S * rayPos.yz;
    rayDir.yz = S * rayDir.yz;

    mat2 R = mat2(vec2(cos(mx), sin(mx)), vec2(-sin(mx), cos(mx)));
    rayPos.xy = R * rayPos.xy;
    rayDir.xy = R * rayDir.xy;
    
    rayDir = normalize(rayDir);

    ivec3 mapPos = ivec3(floor(rayPos + 0.));

    vec3 color = vec3(1.0);
    vec3 sideDist;
    bvec3 mask;
    // core of https://www.shadertoy.com/view/4dX3zl Branchless Voxel Raycasting by fb39ca4 (somewhat reduced)
    vec3 deltaDist;
    {
        deltaDist = 1.0 / abs(rayDir);
        ivec3 rayStep = ivec3(sign(rayDir));
        sideDist = (sign(rayDir) * (vec3(mapPos) - rayPos) + (sign(rayDir) * 0.5) + 0.5) * deltaDist; 

        for (uint i = 0u; i < MAX_RAY_STEPS; i++)
        {
            if (getVoxel(mapPos, stage)) break; // forked shader used continue here

            //Thanks kzy for the suggestion!
            mask = lessThanEqual(sideDist.xyz, min(sideDist.yzx, sideDist.zxy));
            sideDist += vec3(mask) * deltaDist;
            mapPos += ivec3(vec3(mask)) * rayStep;
        }

        color *= mask.x ? vec3(0.25) : mask.y ? vec3(0.5) : mask.z ? vec3(0.75) : vec3(0.0);
    }

    glFragColor = vec4(0);
    
    if(any(greaterThan(abs(mapPos), ivec3(REPETITIONS * 6u))))
        return;

    color *= palette(pattern(mapPos, stage));

    // jt's 3d-texture addon recovering distance & subvoxel intersection-position of ray 
    // as described in https://lodev.org/cgtutor/raycasting.html (see "perpWallDist" there)
    //float d = (mask.x ? sideDist.x - deltaDist.x : mask.y ? sideDist.y - deltaDist.y : mask.z ? sideDist.z - deltaDist.z : 0.0) / length(rayDir);
    //float d = length(vec3(mask) * (sideDist - deltaDist)) / length(rayDir); // rayDir not normalized
    float d = length(vec3(mask) * (sideDist - deltaDist)); // rayDir normalized

    vec3 dst = rayPos + rayDir * d;    

    //color *= smoothstep(0.6,0.61, distance(dst, vec3(mapPos)+0.5));
    color += 0.05*(1.0-smoothstep(0.6,0.61, distance(dst, vec3(mapPos)+0.5)));

    vec3 fogcolor = vec3(0.25, 0.4, 0.5); // fog
    //vec3 fogcolor = vec3(0.75, 0.6, 0.3); // smog
    color *= mix(fogcolor, color, exp(-d * d / 200.0)); // fog for depth impression & to suppress flickering

    //glFragColor = vec4(color, 1.0);
    glFragColor = vec4(sqrt(color), 1.0);
}
