#version 420

// original https://www.shadertoy.com/view/XtBSW3

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// SineTree3d (a ray-traced Sine Tree) - written 2015-11-05 by Jakob Thomsen
// A tree-like structure without recursion, using trigonometric functions with fract for branching - suitable for ray-tracing :-)
// Thanks to FabriceNeyret2 for streamlining the functions.
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
// (ported from http://sourceforge.net/projects/shaderview/)

#define pi 3.1415926

float sfract(float val, float scale)
{
    return (2.0 * fract(0.5 + 0.5 * val / scale) - 1.0) * scale;
}

float mirror(float v)
{
    return abs(2.0 * fract(v * 0.5) - 1.0);
}

float sinetree2d(vec2 v)
{
    v.x = mirror(v.x);
    float n = 3.0; // fract(t / 6.0) * 6.0;
    float br = exp2(ceil(v.y * n));
    float fr = fract(v.y * n);
    float val = cos(pi * (v.x * br + pow(fr, 1.0 - fr) * 0.5 * sign(sin(pi * v.x * br))));
    return 1.0 - pow(0.5 - 0.5 * val, (fr * 1.5 + 0.5) * 1.0);
}

float fn(vec3 v)
{
    return max(sinetree2d(vec2(length(v.xy), v.z)), sinetree2d(vec2(atan(v.x, v.y), v.z))); // JT's SineTree 3d (original)
    // Variations by FabriceNeyret2
    //return sinetree2d(vec2(atan(v.x, v.y), v.z));
    //return sinetree2d(vec2(length(v.xy), v.z));
}

vec3 nrm(vec3 v)
{
    vec3 n;
    float d = 0.01;
    n.x = fn(v + vec3(d, 0.0, 0.0)) - fn(v + vec3(-d, 0.0, 0.0));
    n.y = fn(v + vec3(0.0, d, 0.0)) - fn(v + vec3(0.0, -d, 0.0));
    n.z = fn(v + vec3(0.0, 0.0, d)) - fn(v + vec3(0.0, 0.0, -d));
    return normalize(n);
}

float comb(float v, float s)
{
    return pow(0.5 + 0.5 * cos(v * 2.0 * pi), s);
}

vec4 tex(vec3 v)
{
    float d = abs(v.z * 20. + sfract(-time, 4.) * 5.); 
    vec4 c0 = clamp(vec4(0, v.z, 1. - v.z, 0), 0.,1.);
    vec4 c1 = vec4(0.5 + 0.5 * nrm(v), 1.0);
    vec4 c = mix(c0, c1, vec4(0.5 - 0.5 * cos(0.05 * time * 2.0 * pi))); // change color-palette to enhance branching structure visibility
    return exp(-d*d) + c * abs(nrm(v).x);
}

vec3 camera(vec2 uv, float depth)
{
    float phi = time*.1,  C=cos(phi), S=sin(phi);

    vec3 v = vec3(uv, depth);
    
    v *= mat3( 0, 1,-1,
              -1,-1,-1, 
               1,-1,-1 );

    v.zy *=  mat2 (C,S,-S,C); // could be mixed above
    
    return v;
}

void main(void)
{
    float t = time * 0.1;
    vec2 R  = resolution.xy;
       vec2 uv2 = ( 2. * gl_FragCoord.xy - R)  / R.y;

    vec3 w = vec3(0), v;
    
    for(float layer = 0.; layer < 1.; layer += 1./256.) 
        v = camera(uv2, 2. * layer - 1.),
        abs(v.x) < 1. && abs(v.y) < 1. && abs(v.z) < 1. && abs(fn(v)) < .05 ?  w = v : w;
    
    glFragColor = all(equal(w, vec3(0))) ? vec4(0.0) : tex(w); // avoids flashing background
}
