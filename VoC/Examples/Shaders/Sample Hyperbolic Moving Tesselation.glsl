#version 420

// original https://www.shadertoy.com/view/ldsfD8

#extension GL_EXT_gpu_shader4 : enable

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define ITER_L 20

#define number float
#define complex highp vec2
#define i_complex highp ivec2
#define mobius highp ivec4

complex thetransform[4];
complex passive_t[4];
highp number PI=3.14159265359;
highp number l = 1./3.*sqrt(3.);
highp number halfl;
highp int dcount=0;

highp int sides = 4;

highp number t = 0.;

complex conj(complex a) {
    return vec2(a.x, -a.y);
}

complex mul(complex a, complex b)
{
    return vec2(a.x*b.x - a.y*b.y, a.x*b.y + a.y*b.x);
}

complex expo(complex a)
{
    number l = exp(a.x);
    return l*vec2(cos(a.y), sin(a.y));
}

highp number abs_sq(complex xy)
{
    return xy.x*xy.x + xy.y*xy.y;
}

complex invert(complex xy)
{
    number a = abs_sq(xy);
    return (1./a)*conj(xy);
}

complex doshift(complex z, complex a) {
    return mul(z - a, invert(vec2(1, 0) - mul(conj(a), z)));
}

complex transform(complex z) {
    return mul(mul(z, thetransform[0]) + thetransform[1],
        invert(mul(z, thetransform[2]) + thetransform[3]));
}

vec4 getpixel(complex pos) {
    pos = 1.05*pos;
    if (abs_sq(pos) >= 1.) return vec4(0.5, 0.5, 0.5, 0.5);
    //if (abs_sq(pos) <= 0.0002) return vec4(1, 0, 0, 1);
    //pos = transform(pos);
    int col = dcount;

    complex rv = expo(vec2(0, PI*2./float(sides)));
    complex dv = vec2(l, 0);
    int ctr = 0;
    int flipctr = 0;
    for (int i=0; i<ITER_L; i++) {
        dv = mul(dv, rv);
        complex newpos = doshift(pos, dv);
        if (abs_sq(newpos) >= abs_sq(pos)) {
            ctr++;
            if (ctr >= sides) break;
        } else {
            ctr = 0;
            pos = -newpos;
            if (i%2 == 0) flipctr++;
            col++;
        }
    }

    if ((col + flipctr) % 2 == 0) pos.x *= -1.;
    if (flipctr % 2 == 0) pos.y *= -1.;

    number shift = mod(t, 8.);
    if (shift >= 4.) {
        shift -= 4.;
        //pos = -pos;
    }
    if (shift >= 2.) {
        shift -= 2.;
        pos = vec2(pos.y, -pos.x);
        col++;
    }
    shift -= 1.; shift *= halfl;
    pos = doshift(pos, vec2(halfl, 0));
    pos = doshift(pos, vec2(shift, 0));
    complex newpos = doshift(pos, vec2(-l, 0));
    if (abs_sq(newpos) < abs_sq(pos)) {
        col++;
        pos = newpos;
    }
    
    vec4 backgtiles = vec4(vec3(col%2), 1);
    vec4 thecolor = vec4(0,0,0,1);
    if (abs_sq(pos) <= halfl*halfl*0.5) thecolor.rgb = vec3(1, 1, 1);

    return 0.9*thecolor + 0.1*backgtiles;
}

void main(void)
{
    halfl = (1. - sqrt(1. - l*l))/l;
    vec2 pos=gl_FragCoord.xy;    
    pos.xy -= max(vec2(0), resolution.xy - resolution.yx)/2.;
    pos = pos / min(resolution.x, resolution.y);
    pos = pos*2. - vec2(1,1);

    t = time;
    glFragColor = getpixel(pos);
}
