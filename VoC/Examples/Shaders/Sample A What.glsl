#version 420

// original https://www.shadertoy.com/view/3d2SWt

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// (c) Kristian Sivonen 2019

//#define MOUSE_CTRL

float rand(in vec3 p)
{
    return fract(sin(dot(p, vec3(306.3289, 456.1157, 398.7079)))* 64.77871);
}
    
vec3 randP(in vec3 p)
{
    return fract(sin(vec3(dot(p, vec3(181.1291, 277.7524, 862.331)),
                          dot(p, vec3(271.321, 857.3111, 190.614)),
                          dot(p, vec3(178.9412, 832.961, -269.523))))* 493.721);
}

float vor(in vec3 p, in float t)
{
    // try to nudge position to between
    // the eight nearest neighbours
    // for somewhat naive 2x2x2 sampling
    vec3 p_i = floor(p + .501);
    vec3 p_f = p - p_i;
    float mDist = .8 + .6 * t;
    float r = 0.0;
    for(int x = -1; x < 1; x++)
    {
        for(int y = -1; y < 1 ; y++)
        {
            for(int z = -1; z < 1; z++)
            {
                vec3 n = vec3(x, y, z);
                // reduce discontinuities from 2x2x2 sampling
                vec3 c = randP(p_i + n) * .6 + .2;
                vec3 d = n + c - p_f;
                float dist = dot(d,d);
                if(dist < mDist)
                {
                    mDist = dist;
                    r = rand(p_i + n);
                }
            }
        }
    }
    return r;
}

float vor4(in vec3 p, in float t)
{
    float r = vor(p, t) * 2.0 - 1.0;
    r += vor(p * 2.0, t) - .5;
    r += vor(p * 4.0, t) * .5 - .25;
    r += vor(p * 8.0, t) * .25 - .125;
    return r * .266666 + .266666;
}

// a bit truncated version of iq's palette function
// https://www.shadertoy.com/view/ll2GD3
vec3 color(in float t, in vec3 d)
{
    return cos(6.28318 * (t + d)) * .5 + .5;
}

vec4 quat(in vec3 x, in float a)
{
    vec4 q;
    q.xyz = x * sin(a);
    q.w = cos(a);
    return q;
}

vec3 rot(vec3 p, vec4 q)
{
    return cross(q.xyz,cross(q.xyz, p) + q.w * p) * 2. + p;
}

void main(void)
{
    vec2 fc = gl_FragCoord.xy;

    float t = time * .2;
    vec3 c = vec3(0.1, cos(t * .7) * .1 + .1, sin(t * 1.1) * .1 + .15);

    vec3 uv = vec3(fc / resolution.xy, .5);
    float ratio = resolution.y / resolution.x;
    uv.y *= ratio;
#ifdef MOUSE_CTRL
    vec3 mouse = vec3(mouse*resolution.xy.xy/resolution.xy, .5);
#else
    vec3 mouse = vec3(.5);
#endif
    mouse.y *= ratio;
    uv.z = 1. - sqrt(dot(uv-mouse,uv-mouse));
    uv = rot(uv * (3. + sin(t)), quat(normalize(vec3(uv.y,-uv.x,uv.z) - mouse), t * .1));
    uv *= 8.;
    
    float r = 0.;
    float st = sin(time * .3);    
    float a = 4.18879;
    float j = time + fc.x * .01;
    vec2 scale = vec2(.015);
    for(int i = 0; i < 3; i++)
    {
        vec3 ouv = vec3(uv.xy + vec2(cos(j), sin(j)) * scale, uv.z);
        r += vor4(ouv, st);
        uv += vec3(.0, .0, .004);
        j += a;
    }
    r *= .3333;
    glFragColor = vec4(color(fract(r + t * .1), c), 1.0);
}
