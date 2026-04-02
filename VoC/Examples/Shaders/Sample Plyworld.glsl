#version 420

// original https://www.shadertoy.com/view/3lsfW7

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Plyworld by Kristian Sivonen (ruojake)
// CC BY-SA 4.0 (https://creativecommons.org/licenses/by-sa/4.0/)

vec2 hash21(float v)
{
    vec2 p = vec2(v * 12.3 + 2., v + 11.31);
    return fract(sin(p + dot(p, vec2(2.5341, 1.9413))) * 41321.123);
}

float hash12(vec2 p)
{
    return fract(sin(dot(p, vec2(3.5341, 2.9413))) * 4321.123);
}

float hash13(vec3 p)
{
    return fract(sin(dot(p, vec3(3.5341, 2.9413, 3.1533))) * 4321.123);
}

vec2 hash22(vec2 p)
{
    return fract(sin(p + dot(p, vec2(2.5341, 1.9413))) * 41321.123);
}

#define sat(x) clamp((x), 0., 1.)
#define LAYERS 60.

float noise(vec2 p)
{
    vec2 i = floor(p);
    vec2 f = smoothstep(0., 1., p - i);
    const vec2 o = vec2(1, 0);
    
    return mix(mix(hash12(i), hash12(i + o), f.x),
               mix(hash12(i + o.yx), hash12(i + 1.), f.x),
               f.y);
}

float noise(vec3 p)
{
    vec3 i = floor(p);
    vec3 f = smoothstep(0., 1., p - i);
    const vec2 o = vec2(1, 0);
    
    return mix(
        mix(
            mix(hash13(i), hash13(i + o.xyy), f.x),
            mix(hash13(i + o.yxy), hash13(i + o.xxy), f.x),
            f.y),
        mix(
            mix(hash13(i + o.yyx), hash13(i + o.xyx), f.x),
            mix(hash13(i + o.yxx), hash13(i + 1.), f.x),
            f.y),
        f.z);
}

float fbm(vec2 p)
{
    const float per = .45;
    const float oct = 5.;
    
    float res = 0.;
    float amp = .4;
    
    for(float i = 1.; i <= oct; i += 1.)
    {
        res += amp * noise(p);
        p += p;
        amp *= per;
    }
    return smoothstep(1., 0., res);
}

vec2 noise21(float v)
{
    float i = floor(v);
    float f = smoothstep(0., 1., v - i);
    return mix(hash21(i), hash21(i + 1.), f);
}

float stairstep(float v, float s, float b)
{
    float i = floor(v * s);
    float f = v * s - i;
    f = smoothstep(b - 1., b, f * b);
    return mix(i, i + 1., f) / s;
}

float pattern(vec3 p)
{
    float i = floor(p.y * LAYERS);
    float f = p.y * LAYERS - i;
    vec2 o = hash21(i * 31. + .4) * 2. - 1.;
    vec2 xz = p.xz;
    p.xz += noise(p.xz * 5. + i * 3.) * .125 - .0625;
    p.xz += mix(sin(dot(xz * 1000., o)), sin(dot(xz * 1301., o)), hash12(xz * 900.)) * .002;
    
    return mix( 
        fract(sin(dot(p.xz * 20. * (1. + sin(i * 1312.41) * .2), o))),
        cos(f * 25.1327) * sat(1. - 100. * length(fwidth(p))),
        smoothstep(.199, .2, f));
}

float scene(vec3 p)
{
    float res = fbm(p.xz);
    res *= 2.5 - res * res;
    res = stairstep(res, LAYERS, max(40. - fwidth(p.x) * 1000., 2.));
    return .55 * (p.y + res - 2.);
}

float shadow(vec3 ro, vec3 rd, float maxDist, float k)
{
    float res = 1.;
    float d = 0.;
    float t = .01;
    for(int i = 0; i < 30; ++i)
    {
        d = scene(ro + rd * t);
        res = min(res, k * d / t);
        t += d;
        if(abs(d) < .0001 || t >= maxDist)
            break;
        if (res < .001)
        {
            res = 0.;
            break;
        }
    }
    return res;
}

vec3 normal(vec3 p)
{
    float d = scene(p);
    vec2 e = vec2(.00001, .0);
    return normalize(d - vec3(
        scene(p - e.xyy),
        scene(p - e.yxy),
        scene(p - e.yyx)));
}

vec3 ray(vec3 ro, vec3 lookAt, vec2 uv, float zoom)
{
    vec3 f = normalize(lookAt - ro);
    vec3 r = cross(vec3(0., 1., 0.), f);
    vec3 u = cross(f, r);

    return normalize(uv.x * r + uv.y * u + f * zoom);
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy - resolution.xy * .5) / resolution.y;

    vec2 m = clamp((mouse*resolution.xy.xy / resolution.xy) * 2. - 1., vec2(-1.), vec2(1.));
    if (m == vec2(-1.,-1.)) m = vec2(0.);
    
    vec3 v = vec3(0, 0, time * .1);
    vec3 md = vec3(m.x * 2., m.y, -max(abs(m.x), abs(m.y) * .5));
    
    vec3 tgt = vec3(10., 1., 2.) + v + md;
    vec3 ro = vec3(10.,1.5, 0.) + v;
    
    vec3 rd = ray(ro, tgt, uv, .8);
    float t = 0.;
    vec3 p;
    float asd = 0.;
    for(float i = 0.; i < 60.; i++)
    {
        p = ro + rd * t;
        float d = scene(p);
        if (d < 0.) d /= (i * 2. + 1.);
        asd += 1.;
        
        if (abs(d) < .00005) break;
        t += d;
    }

    vec3 lDir = normalize(vec3(4,4,3));
    vec3 n = normal(p);
    float l = sat(dot(n,lDir));
    l *= shadow(p + n * .001, lDir, 4., 3.);
    
    vec3 col = mix(vec3(.95,.92,.76), vec3(.81,.72,.45), pattern(p));
    
    col *= 1. + sin(floor(p.y * LAYERS) * 5123.23) * vec3(0,.02,.1);
    col *= n.y * .6 + .4;
    
    col *= mix(vec3(.2,.25, .35), vec3(1.2,1.17,1.), l);
    col = mix(mix(vec3(.96,.97,1.) * sat(1.3 - rd.y), vec3(.4,.4,.42), rd.y), col, sat(1.2 - t * .1));
    
    col *= 1. - smoothstep(.45, .7, length((uv * resolution.y / resolution.xy))) * .5;
    
    glFragColor = vec4(pow(col, vec3(1./2.2)),1.0);
}
