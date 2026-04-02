#version 420

// original https://www.shadertoy.com/view/XlSSW3

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Matrix-Tree (a ray-traced Sine Tree) - written 2015-11-05 by Jakob Thomsen
// A tree-like structure without recursion, using trigonometric functions with fract for branching - suitable for ray-tracing :-)
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
    float br = pow(2.0, ceil(v.y * n));
    float fr = fract(v.y * n);
    float val = cos(pi * (v.x * br + pow(fr, 1.0 - fr) * 0.5 * sign(sin(pi * v.x * br))));
    //return pow(0.5 - 0.5 * val, (fr * 1.5 + 0.5) * 100.0);
    return 1.0 - pow(0.5 - 0.5 * val, (fr * 1.5 + 0.5) * 1.0);
}

float fn(vec3 v)
{
    return max(sinetree2d(v.xz), sinetree2d(v.yz));
}

float comb(float v, float s)
{
    return pow(0.5 + 0.5 * cos(v * 2.0 * pi), s);
}

vec3 tex(vec3 v)
{
    float x = v.x;
    float y = v.y;
    float z = v.z;
    //x += 0.01 * time;
    //y += 0.01 * time;
    float d = exp(-pow(abs(z * 20.0 + sfract(-time, 4.0) * 5.0), 2.0));
    z -= 0.05 * time;
    x = (x * 8.0);
    y = (y * 8.0);
    z = (z * 8.0);
    float q = 0.0;
    q = max(q, comb(x, 10.0));
    q = max(q, comb(y, 10.0));
    q = max(q, comb(z, 10.0));
    float w = 1.0;
    w = min(w, max(comb(x, 10.0), comb(y, 10.0)));
    w = min(w, max(comb(y, 10.0), comb(z, 10.0)));
    w = min(w, max(comb(z, 10.0), comb(x, 10.0)));
    return d +  max(w + vec3(0.0, q, 0.5 * q), 0.25 * clamp(vec3(0.0, v.z, 1.0 - v.z), 0.0, 1.0));
}

vec3 camera(vec2 uv, float depth)
{
    float phi = time * 0.1;
    //float phi = 2.0 * mouse*resolution.xy.x / resolution.x - 1.0;
    vec3 v = vec3(uv, depth);
    
    // isometry
    vec3 iso;
    iso.x =  v.x - v.y - v.z;
    iso.y = -v.x - v.y - v.z;
    iso.z =        v.y - v.z;
    
    v.z = iso.x * cos(phi) + iso.y * sin(phi);
    v.y = iso.x * -sin(phi) + iso.y * cos(phi);
    v.x = iso.z;

    return v;
}

/*
vec3 camera(vec2 uv, float depth)
{
    float t = time * 0.1;
    vec3 v;
    v.x = uv.x * cos(t) + uv.y * sin(t); // uv.x;
    v.y = uv.x * -sin(t) + uv.y * cos(t); // uv.y;
    v.z = depth;
    
    // isometry
    vec3 iso;
    iso.x =  v.x - v.y - v.z;
    iso.y = -v.x - v.y - v.z;
    iso.z =        v.y - v.z;

    return iso;
}
*/
void main(void)
{
    float t = time * 0.1;
    vec2 uv = 2.0 * gl_FragCoord.xy / resolution.xy - 1.0;
    uv.x *= resolution.x / resolution.y;

    const int depth = 256;
    float m = 0.0;
    vec3 color = vec3(0.0, 0.0, 0.0);
    for(int layer = 0; layer < depth; layer++) // slow...
    {
        vec3 v = camera(uv, 2.0 * float(layer) / float(depth) - 1.0);

        if(abs(v.x) > 1.0 || abs(v.y) > 1.0 || abs(v.z) > 1.0)
            continue;

        if(abs(fn(v)) < 0.05)
        {
            m = 2.0 * float(layer) / float(depth) - 1.0;
            color = tex(v);
        }
    }
    
    //glFragColor = vec4(color * vec3(m), 1.0);
    glFragColor = vec4(color, 1.0);
}
