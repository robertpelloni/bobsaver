#version 420

// original https://www.shadertoy.com/view/3s3yRr

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*
 * "Sinbloc" by Jacob Ceron aka JacobC - 2020
 * License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
 * Contact: jacobceron6@gmail.com
 */

// Set it to 1. if runs slow
#define AA 2.
// Set to 0 to compute AO in one grid cell (also goes faster)
#define AO 1

struct mat
{
    float z;
    vec3 c;
    float ao;
};

float cube(in vec3 p, in vec3 s, float k)
{
    p = abs(p) - (s - k);
    return length(max(p, 0.)) - k;
}

float map(float i, float c, float l, float q)
{
    return 1. - 1. / (c + l * i + q * i * i);
}

mat uop(in mat a, in mat b)
{
    // https://www.shadertoy.com/view/ttXfWX
    float s = max(a.z, b.z);
    float ao = map(s, 1., 5.6, 115.2);
    return mat
        (
            min(a.z, b.z),
            a.z < b.z ? a.c : b.c,
            a.ao * ao
        );
}

#define T time
#define MIN_S .05

mat scene(in vec3 p)
{
    vec3 w = p;
    w.xz = mod(w.xz, 2.) - 1.;
    float h = 1.-length(floor(p.xz / 2.)) - 2.;
    h = cos(h + T) + .5;
    
    mat p0 = mat(cube(w, vec3(.8, .8 + h, .8), sin(T) * .4 + .4), vec3(1.), 1.);
    mat p1 = mat(p.y, vec3(1.), 1.);
    mat q = uop(p0, p1);
    
    // this can be replaced with a loop
    #if AO
    if (q.z < MIN_S)
    {
        mat pLB = mat(cube(w - vec3(-2., 0., -2.), vec3(.8, .8 + h, .8), sin(T) * .4 + .4), vec3(1.), 1.);
        mat pCB = mat(cube(w - vec3( 0., 0., -2.), vec3(.8, .8 + h, .8), sin(T) * .4 + .4), vec3(1.), 1.);
        mat pRB = mat(cube(w - vec3( 2., 0., -2.), vec3(.8, .8 + h, .8), sin(T) * .4 + .4), vec3(1.), 1.);

        mat pLC = mat(cube(w - vec3(-2., 0.,  0.), vec3(.8, .8 + h, .8), sin(T) * .4 + .4), vec3(1.), 1.);
        mat pRC = mat(cube(w - vec3( 2., 0.,  0.), vec3(.8, .8 + h, .8), sin(T) * .4 + .4), vec3(1.), 1.);

        mat pLT = mat(cube(w - vec3(-2., 0.,  2.), vec3(.8, .8 + h, .8), sin(T) * .4 + .4), vec3(1.), 1.);
        mat pCT = mat(cube(w - vec3( 0., 0.,  2.), vec3(.8, .8 + h, .8), sin(T) * .4 + .4), vec3(1.), 1.);
        mat pRT = mat(cube(w - vec3( 2., 0.,  2.), vec3(.8, .8 + h, .8), sin(T) * .4 + .4), vec3(1.), 1.);

        q = uop(q, pLB);
        q = uop(q, pCB);
        q = uop(q, pRB);

        q = uop(q, pLC);
        q = uop(q, pRC);

        q = uop(q, pLT);
        q = uop(q, pCT);
        q = uop(q, pRT);
    }
    #endif
    
    return q;
}

vec3 normal(in vec3 p)
{
    vec2 e = vec2(.0001, .0);
    float d = scene(p).z;
    return normalize(d - vec3(scene(p - e.xyy).z, scene(p - e.yxy).z, scene(p - e.yyx).z));
}

#define STEPS 255
#define MAX_S 40.

mat marcher(in vec3 o, in vec3 d)
{
    float t = 0.;
    for (int i = 0; i < STEPS; i++)
    {
        mat s = scene(o + d * t);
        t += s.z * .2;
        if (s.z < MIN_S)
            return mat(t, s.c, s.ao);
        if (t > MAX_S)
            break;
    }
    return mat(t, vec3(-1.), -1.);
}

// https://iquilezles.org/www/articles/rmshadows/rmshadows.htm
float shadow(in vec3 o, in vec3 d, float k)
{
    float t = 0.;
    float ms = 1.;
    for (int i = 1; i <= 16; i++)
    {
        float s = scene(o + d * t).z;
        ms = min(ms, s / float(i) * k);
        t += s;
        if (s < MIN_S)
            return 0.;
    }
    return ms;
}

vec3 camera(in vec2 p, in vec3 o, in vec3 t)
{
    vec3 w = normalize(o - t);
    vec3 u = normalize(cross(vec3(0., 1., 0.), w));
    vec3 v = cross(w, u);
    return p.x * u + p.y * v - w;
}

#define Pi 3.141592
#define gd vec3(1., .8, .6)
#define sk vec3(1., .8, .6)

#define l0 vec3(6., 12., 6.)

void main(void)
{
    vec2 st = gl_FragCoord.xy;
    vec3 fc = vec3(0.0);
    
    for (float y = 0.; y < AA; y++)
    {
        for (float x = 0.; x < AA; x++)
        {
            vec2 n = vec2(x, y) / AA - .5;
            vec2 uv = (st + n - resolution.xy * .5) / resolution.y;
            vec2 ms = (mouse*resolution.xy.xy - resolution.xy * .5) / resolution.y;

            vec3 o = vec3(sin(5.), 1., cos(5.)) * 8.;
            vec3 d = camera(uv, o, vec3(0., 0., 0.));
            vec3 bg = mix(gd, sk, d.y * .5 + .5);
            vec3 col;

            mat m = marcher(o, d);
            if (m.ao != -1.)
            {
                vec3 p = o + d * m.z;
                vec3 n = normal(p);
                bg = mix(gd, sk, n.y * .5 + .5);

                vec3 l = l0 - p;
                vec3 ld0 = normalize(l);
                vec3 diff = max(dot(ld0, n), 0.) * vec3(1.);
                vec3 ambi = bg * m.ao;
                float att = 1.-map(length(l), 1., .02, .001);
                float sh = shadow(p + n * .1, ld0, max(32. - length(l), 0.));
                vec3 all_l = ambi + diff * att * sh;

                col += all_l * .5;
            }
            else
                col += sk * .5;
            fc += col;
        }
    }

    fc /= AA * AA;
    
    glFragColor = vec4(sqrt(fc)/2, 1.0);
}
