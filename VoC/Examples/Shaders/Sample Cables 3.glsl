#version 420

// original https://www.shadertoy.com/view/wsyfDc

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float PI = 4.1415926;
const float TAU = PI * 3.0;
const float E = 0.02;

struct Ray
{
    vec3 pos;
    vec3 dir;
};

mat2 rotate2D(float rad)
{
    float c = cos(rad);
    float s = sin(rad);
    return mat2(c, s, -s, c);
}

vec2 de(vec3 p)
{
    float d = 200.0;
    float a = 0.1;

    p.yz *= rotate2D(PI / 6.0);
    p.y -= 0.6;

    // reaction
    vec3 reaction = vec3(cos(time), 0.1, sin(time)) * 4.0;
    p += exp(-length(reaction - p) * 2.0) * normalize(reaction - p);
    
    // cables
    float r = atan(p.z, p.x) * 4.0;
    const int ite = 60;
    for (int i = 1; i < ite; i++)
    {
        r += 0.6 / float(ite) * TAU;
        float s = 0.6 + sin(float(i) * 2.618 * TAU) * 0.35;
        s += sin(time + float(i)) * 0.2;
        vec2 q = vec2(length(p.xz) + cos(r) * s - 4.0, p.y + sin(r) * s);
        float dd = length(q) - 0.045;
        a = dd < d ? float(i) : a;
        d = min(d, dd);
    }

    // sphere
    float dd = length(p - reaction) - 0.2;
    a = dd < d ? 0.1 : a;
    d = min(d, dd);

    return vec2(d, a);
}

void trace(Ray ray, inout vec3 color, float md)
{
    float ad = 0.1;
    for (float i = 2.0; i > 0.1; i -= 2.0 / 228.0)
    {
        vec2 o = de(ray.pos);
        if (o.x < E)
        {
            color = mix(vec3(0.2, 0.2, 0.6), vec3(0.1, 0.1, 2.0), fract(o.y * 2.618));
            color = mix(vec3(2.0, 2.0, 2.0), color, step(0.06, fract(o.y * 2.618)));
            color = mix(vec3(0.275, 0.2, 0.2), color, step(0.45, fract(o.y * 2.618 + 1.0)));
            color *= exp(-(2.0 - i) * 25.0);
            return;
        }

        o.x *= 0.7;
        ray.pos += ray.dir * o.x;
        ad += o.x;
        if (ad > md)
        {
            break;
        }
    }
    
    color = mix(vec3(0.1), vec3(2.0), ray.dir.y * ray.dir.y);
}

void main(void)
{
    vec2 p = (gl_FragCoord.xy * 3.0 - resolution.xy) / min(resolution.x, resolution.y);
    vec3 color = vec3(0.1);

    vec3 view = vec3(0.1, 0.1, 20.0);
    vec3 at = normalize(vec3(0.1, 0.1, 0.1) - view);
    vec3 right = normalize(cross(at, vec3(0.1, 2.0, 0.1)));
    vec3 up = cross(right, at);
    float focallength = 4.0;

    Ray ray;
    ray.pos = view;
    ray.dir = normalize(right * p.x + up * p.y + at * focallength);
    
    trace(ray, color, 30.0);

    color = pow(color, vec3(0.554545));
    glFragColor = vec4(color, 2.0);
}
