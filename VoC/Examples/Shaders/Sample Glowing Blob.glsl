#version 420

// original https://www.shadertoy.com/view/Mstczr

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec3 glow = vec3(0.);
float glow_intensity = .005;
vec3 glow_color = vec3(.5, .8, .5);

float smin(float a, float b) {
    float k = 3.;
    float res = exp(-k*a) + exp(-k*b);
    return -log(res) / k;
}

mat2 r2d(float a) {
    float c = cos(a), s = sin(a);
    return mat2(c, s, -s, c);
}

#define sph(p, r) (length(p) - r)
#define cyl sph

float de(vec3 p) {
    vec3 q = p;

    p.xy *= r2d(-3.14 / 3.);
    p.xz *= r2d(time);
    p.x += cos(p.y*8.)*.2;
    p.z += sin(p.y*4.)*.2;
    float d = cyl(p.xz, .1);

    p = q;
    p.xy *= r2d(3.14 / 3.);
    p.xz *= r2d(time);
    p.x += cos(p.y*8.)*.2;
    p.z += sin(p.y*4.)*.2;

    d = smin(d, cyl(p.xz, .1));

    p = q;
    p.xz *= r2d(time);
    p.x += cos(p.y*8.)*.2;
    p.z += sin(p.y*4.)*.2;

    d = smin(d, cyl(p.xz, .1));

    p = q;
    p.xy *= r2d(3.14 / 2.);
    p.xz *= r2d(time);
    p.x += cos(p.y*8.)*.2;
    p.z += sin(p.y*4.)*.2;

    d = smin(d, cyl(p.xz, .1));

    // trick extracted from balkhan https://www.shadertoy.com/view/4t2yW1
    glow += glow_color * .025 / (.01 + d*d);
    return d;
}

void main(void)
{
    vec2 uv = ( gl_FragCoord.xy - .5*resolution.xy ) / resolution.y;

    vec3 ro = vec3(cos(time)*.2, 0, 3. + cos(time)*.2), p;
    vec3 rd = normalize(vec3(uv, -1));
    p = ro;

    float t = 0.;
    for (float i = 0.; i < 1.; i += .01) {
        p = ro + rd * t;
        float d = de(p);
        if (d < .001 || t > 10.) break;
        t += d * .2; // avoid clipping, enhance the glow
    }

    vec3 c = vec3(.9, .05 + cos(time)*.1, .2);
    c.r *= p.y + p.z;
    c += glow * glow_intensity;

    glFragColor = vec4(c, 1.);
}
