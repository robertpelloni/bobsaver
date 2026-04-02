#version 420

// original https://www.shadertoy.com/view/ltKyRR

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*
 * This work is licensed under a 
 * Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License
 * http://creativecommons.org/licenses/by-nc-sa/3.0/
 *  - You must attribute the work in the source code 
 *    (link to https://www.shadertoy.com/view/ltKyRR).
 *  - You may not use this work for commercial purposes.
 *  - You may distribute a derivative work only under the same license.
 */

vec3 random3(vec3 c)
{
    float j = 4096.0*sin(dot(c, vec3(17.0, 59.4, 15.0)));
    vec3 r;
    r.z = fract(512.0 * j);
    j *= 0.125;
    r.x = fract(512.0 * j);
    j *= 0.125;
    r.y = fract(512.0 * j);
    return r - 0.5;
}

const float F3 = 0.3333333;
const float G3 = 0.1666667;

// taken from https://www.shadertoy.com/view/XsX3zB
float simplex3d(vec3 p)
{
     vec3 s = floor(p + dot(p, vec3(F3)));
     vec3 x = p - s + dot(s, vec3(G3));
     vec3 e = step(vec3(0.0), x - x.yzx);
     vec3 i1 = e*(1.0 - e.zxy);
     vec3 i2 = 1.0 - e.zxy*(1.0 - e);
     vec3 x1 = x - i1 + G3;
     vec3 x2 = x - i2 + 2.0*G3;
     vec3 x3 = x - 1.0 + 3.0*G3;
     vec4 w, d;
     w.x = dot(x, x);
     w.y = dot(x1, x1);
     w.z = dot(x2, x2);
     w.w = dot(x3, x3);
     w = max(0.6 - w, 0.0);
     d.x = dot(random3(s), x);
     d.y = dot(random3(s + i1), x1);
     d.z = dot(random3(s + i2), x2);
     d.w = dot(random3(s + 1.0), x3);
     w *= w;
     w *= w;
     d *= w;
     return dot(d, vec4(52.0));
}

float simplex3d_fractal(vec3 m)
{
    float sum = 0.0;
    for (int i = 0; i < 12; ++i)
    {
        float scale = pow(2.0, float(i));
        sum += simplex3d(scale * m) / scale;
    }
    return sum;
}

vec3 flow_texture(in vec3 p)
{
    // animate initial coordinates
    vec3 p1 = 0.1 * p + vec3(1.0 + time * 0.0023, 2.0 - time * 0.0017, 4.0 + time * 0.0005);
    // distort noise sampling coordinates using the same noise function
    vec3 p2 = p + 8.1 * simplex3d_fractal(p1) + 0.5;
    vec3 p3 = p2 + 4.13 * simplex3d_fractal(0.5 * p2 + vec3(5.0, 4.0, 8.0 + time * 0.07)) + 0.5;

    vec3 ret;
    ret.x = simplex3d_fractal(p3 + vec3(0.0, 0.0, 0.0 + time * 0.3));
    ret.y = simplex3d_fractal(p3 + vec3(0.0, 0.0, 0.2 + time * 0.3));
    ret.z = simplex3d_fractal(p3 + vec3(0.0, 0.0, 0.3 + time * 0.3));

    // scale output & map
    ret = 0.5 + 0.5 * ret;
    ret = smoothstep(vec3(0.15), vec3(0.85), ret);
    return ret;
}

void main(void)
{
    vec3 result = vec3(0.0);

    const int numSamples = 2; // cheap AA
    for (int x = 0; x < numSamples; ++x)
    {
        for (int y = 0; y < numSamples; ++y)
        {
            vec2 offset = vec2(float(x), float(y)) / float(numSamples);
            vec3 p = vec3((gl_FragCoord.xy + offset) / resolution.x, time*0.001);
            result += flow_texture(p * 6.0);
            
        }
    }

    result /= float(numSamples * numSamples);
    glFragColor = vec4(sqrt(result), 1.0);
}
