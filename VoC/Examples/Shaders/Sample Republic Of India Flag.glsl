#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/3lyGRd

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/**
 A very lazy and quick doodle of the Indian flag on this year's Indian Republic Day.
 Not the most efficient code, but I think it still looks cool. 
*/

#define PI 3.1415926535

#define ROT(x) mat2(cos(x), -sin(x), sin(x), cos(x))

#define ORANGE vec3(255., 154., 48.) / 255.
#define GREEN vec3(9., 137, 1.) / 255.
#define NAVY_BLUE vec3(0., 0., 137.) / 255.

#define RADIUS .7
#define HALF_RADIUS RADIUS * .5

// Hash by Dave_Hoskins
float hash(vec2 p)
{
    uvec2 q = uvec2(ivec2(p)) * uvec2(1597334673U, 3812015801U);
    uint n = (q.x ^ q.y) * 1597334673U;
    return float(n) / float(0xffffffffU);
}

// iq's 2d sdf for iscosceles triangles (https://www.shadertoy.com/view/MldcD7)
float isoscelesTriangle(in vec2 q, in vec2 p)
{
    p.y -= .5;
    p.x = abs(p.x);
    
    vec2 a = p - q * clamp(dot(p, q) / dot(q, q), 0., 1.);
    vec2 b = p - q * vec2(clamp(p.x / q.x, 0., 1.), 1.);
    
    float s = -sign(q.y);

    vec2 d = min(vec2(dot(a, a), s * (p.x * q.y - p.y * q.x)),
                  vec2(dot(b, b), s * (p.y - q.y)));

    return -sqrt(d.x) * sign(d.y);
}

// Probably not the best way to model the chakra, would have used the abs
// mirroring technique to efficiently draw it, but since it's a lazy and quick
// doodle so I said whatever, it doesn't matter either way.
float getChakra(vec2 uv)
{
    float outerCircle = smoothstep(.01, -.01, abs(length(uv) - RADIUS - .22) - .06);
    float innerCircle = smoothstep(.22, .20, length(uv));
    float spokes = 0., spokeThickness = .03, notches = 0., theta = 2. * PI / 24.;
    for (int i = 0; i < 24; ++i)
    {
        vec2 suv = ROT(float(i) * theta) * uv;
        // shorter inward pointing triangle
        suv.y += HALF_RADIUS;
        spokes += smoothstep(.015, -.015,
                    isoscelesTriangle(vec2(spokeThickness, RADIUS * .334), suv));
        // longer outward pointing triangle
        suv.y -= RADIUS + .0025;
        spokes += smoothstep(.015, -.015,
                    isoscelesTriangle(vec2(spokeThickness, -RADIUS * .666), suv));
        
        // boundary notches
        vec2 nuv = ROT(float(i) * theta + theta * .5) * uv;
        nuv.y -= RADIUS + .16;
        notches += smoothstep(.04, .032, length(nuv));
    }
    
    float chakra = notches + innerCircle + outerCircle + spokes;
    return clamp(chakra, 0., 1.);
}

void main(void)
{
    vec2 uv = (2. * gl_FragCoord.xy - resolution.xy) / min(resolution.x, resolution.y);
    vec2 st = gl_FragCoord.xy / resolution.xy;
    float w = sin((uv.x + uv.y - time * .75 + sin(1.5 * uv.x + 4.5 * uv.y) * PI * .3)
                  * PI * .6); // fake waviness factor
    
    uv *= 1. + (.036 - .036 * w);
    vec3 col = vec3(0.);
    
    // flag colors
    col += 1.;
    col = mix(col, ORANGE, smoothstep(.35, .36, uv.y));
    col = mix(col, GREEN, smoothstep(-.35, -.36, uv.y));
    col = mix(col, NAVY_BLUE, getChakra(uv * 3.2));
    col += w * .225;
    
    float v = 16. * st.x * (1. - st.x) * st.y * (1. - st.y); // vignette
    col *= 1. - .6 * exp2(-1.75 * v);
    col = clamp(col - hash(gl_FragCoord.xy) * .004, 0., 1.);
    glFragColor = vec4(col, 1.);
}
