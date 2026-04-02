#version 420

// original https://www.shadertoy.com/view/wsdGDB

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// (c) Kristian Sivonen 2019

#define MAX_STEPS 60
#define MAX_STEPS_SHADOW 45
#define MIN_DISTANCE .0175
#define MIN_DISTANCE_SHADOW .001
#define MAX_DISTANCE 45.

// Hash without sine by Dave Hoskins, CC BY-SA 4.0
// https://www.shadertoy.com/view/4djSRW
float hash12(vec2 p)
{
    vec3 p3  = fract(vec3(p.xyx) * .1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

vec3 hash33(vec3 p3)
{
    p3 = fract(p3 * vec3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yxz+33.33);
    return fract((p3.xxy + p3.yxx)*p3.zyx);

}
// --

float noise(vec2 p)
{
    vec2 pi = floor(p);
    vec2 pf = smoothstep(.01, .99, fract(p));
    float h00 = hash12(pi);
    float h01 = hash12(pi + vec2(0., 1.));
    float h10 = hash12(pi + vec2(1., 0.));
    float h11 = hash12(pi + 1.);
    return mix(mix(h00, h10, pf.x), mix(h01, h11, pf.x), pf.y);
}

float sMin(float a, float b)
{
    float t = clamp(b - a + .5, 0., 1.);
    return mix(b, a, t) - t * (1. - t) * .5;
}

float sSub(float a, float b)
{
    float t = clamp(.5 - (b + a) * .25, 0., 1.);
    return mix(b, -a, t) + t * (1. - t) * .5;
}

vec4 quat(in vec3 x, in float a)
{
    return vec4(x * sin(a), cos(a));
}

vec3 rot(vec3 p, vec4 q)
{
    return cross(q.xyz,cross(q.xyz, p) + q.w * p) * 2. + p;
}

float sIntersect(float a, float b)
{
    float t = clamp(b - a + .5, 0., 1.);
    return mix(a, b, t) + t * (1. - t) * .5;
}

float vor(in vec3 p, float m)
{
    vec3 p_i = floor(p + .501);
    vec3 p_f = p - p_i;
    float mDist = m;
    float base = mDist;
    for(int x = -1; x < 1; x++)
    {
        for(int y = -1; y < 1 ; y++)
        {
            for(int z = -1; z < 1; z++)
            {
                vec3 n = vec3(x, y, z);
                vec3 c = hash33(p_i + n) * .6 + .2;
                vec3 d = n + c - p_f;
                float dist = dot(d,d);
                
                mDist = min(mDist, dist);           
            }
        }
    }
    return mDist * .5;
}

float sphere(vec3 p, vec3 sp, float r, vec4 q)
{
    float b = sin(time * 4. - 2.);
    b *= .6 + b * .4;
    p.y *= 1. + b * .4;
    p.xy *= 1.1 - b * .3;
    float ds = length(p - sp) - r;
    vec3 vp = rot((p - sp) , q);
    return sSub(ds + r * .3, sIntersect(ds - .3 + sp.y * .1, vor(vp * 2., .1 + p.y * .5)));
}

float ground(vec3 p)
{
    return p.y + noise(p.xz * 30.) * .005;
}

float scene(vec3 p, vec4 q)
{
    vec3 spherePos = vec3(0, 1.75 + sin(time * 2.) * 2., 7);
    float sphereRadius = 2.;
    return sMin(ground(p), sphere(p, spherePos, sphereRadius, q));
}

float march(vec3 ro, vec3 rd, vec4 q)
{
    float res = 0.;
    
    for(int i = 0; i < MAX_STEPS; ++i)
    {
        float d = scene(ro + rd * res, q);
        res += d;
        if(abs(d) < MIN_DISTANCE || res > MAX_DISTANCE)
            break;
    }
    return res;
}

float shadow(vec3 ro, vec3 rd, float k, float maxDist, vec4 q)
{
    float res = 1.;
    float d = 0.;
    float t = .02;
    for(int i = 0; i < MAX_STEPS_SHADOW; ++i)
    {
        d = scene(ro + rd * t, q);
        res = min(res, k * d / t);
        t += d;
        if(abs(d) < MIN_DISTANCE_SHADOW || t >= maxDist)
            break;
    }
    return res;
}

vec3 normal(vec3 p, vec4 q)
{
    float d = scene(p, q);
    vec2 e = vec2(.005, .0);
    return normalize(d - vec3(
        scene(p - e.xyy, q),
        scene(p - e.yxy, q),
        scene(p - e.yyx, q)));
}

float light(vec3 p, vec3 n, float k, vec4 q)
{
    vec3 lightPos = vec3(0, 2. + sin(time * 2.) * 1.9, 7);
    lightPos.xz += vec2(-cos(time * .5), sin(time * .5)) * .2;
    vec3 l = normalize(lightPos - p);
    
    float res = dot(n, l);
    float d = length(p - lightPos) + .001;
    
    p += n * .02;
    if(res >= 0.)
    {
        float sh = shadow(p, l, k, d, q);
        res *= sh;
    }
    res = clamp(res, 0., 1.);
    res *= smoothstep(20., 0., d);
    return res;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy - resolution.xy * .5) / resolution.y;

    vec3 ro = vec3(0.,1.,0.);
    vec3 rd = normalize(vec3(uv, .8));
    
    vec3 col = vec3(0.);
    
    vec2 cs = sin(vec2(time + 1.57, time)) * vec2(-1,1);
    vec3 axis = vec3(cs, 0.);
    vec4 q = quat(axis, time * .3 + (1.75 + sin(time * 2.) * 2.) * .5);
    float d = march(ro, rd, q);
    vec3 p = ro + rd * d;
    vec3 n = normal(p, q);
    float l = light(p, n, 128., q);
    float hl = smoothstep(.6, .8, l);
    l = smoothstep(.2, .3, l);
    col = mix(mix(vec3(.2, .3, .5), vec3(1., .6, .1), l), vec3(1.), hl);
    glFragColor = vec4(col,1.0);
}
