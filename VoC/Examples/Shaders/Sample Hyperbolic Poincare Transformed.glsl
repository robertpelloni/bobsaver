#version 420

// original https://www.shadertoy.com/view/3lscDf

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*
    Hyperbolic Poincaré transformed
    2015-2020 stb

    Just messing with some old code, and a few complex functions.
*/

// change these
const int N        = 7;    // number of polygon vertices
const int P        = 3;    // number of polygons meeting at a vertex
const int Iters    = 16;    // number of iterations

#define E         2.71828182
#define HALFPI    1.57079633
#define PI        3.14159265
#define TWOPI    6.28318531

float s, c;
#define rotate(p, a) mat2(c=cos(a), s=-sin(a), -s, c) * p
#define rotate2(p, a) vec2(p.x*cos(a) - p.y*sin(a), p.x*sin(a) + p.y*cos(a))

vec2 radialRepeat(vec2 p, vec2 o, int n) {
    return rotate(vec2(o.x, o.y), floor(atan(p.x, p.y)*(float(n)/TWOPI)+.5)/(float(n)/TWOPI));
}

vec2 cInvert(vec2 p, vec2 o, float r) {
    return (p-o) * pow(r, 2.) / dot(p-o, p-o) + o;
}

vec2 cInvertMirror(vec2 p, vec2 o, float r, float flip){
    return (length(p-o)<r ^^ flip==1. ? cInvert(p, o, r) : p);
}

vec4 poincareGetStuff(int n_, int p_) {
    float n = PI / float(n_), p = PI / float(p_);
    vec2 r1 = vec2(cos(n), -sin(n));
    vec2 r2 = vec2(cos(p+n-HALFPI), -sin(p+n-HALFPI));
    float dist = (r1.x - (r2.x/r2.y) * r1.y);
    float rad = length(vec2(dist, 0.)-r1);
    float d2 = dist*dist - rad*rad;
    float s = (d2<0. ? 1. : sqrt(d2));
    return vec4(vec3(dist, rad, 1.)/s, float(d2<0.));
}

vec2 poincareCreateUVs(vec2 p, vec4 pI) {
    return cInvertMirror(p, radialRepeat(p, vec2(0., pI.x), N), pI.y, pI.w);
}

// Many complex functions are from: https://raw.githubusercontent.com/julesb/glsl-util/master/complexvisual.glsl

#ifndef sinh
    #define sinh(a) (pow(E, a)-pow(E, -a)) / 2.
#endif
#ifndef cosh
    #define cosh(a) (pow(E, a)+pow(E, -a)) / 2.
#endif

#define c_abs(a) length(a)
#define c_arg(a) atan(a.y, a.x)

#define c_conj(a) vec2(a.x, -a.y)
#define c_exp(a) vec2(exp(a.x)*cos(a.y), exp(a.x)*sin(a.y))
#define c_sqr(a) vec2(a.x*a.x-a.y*a.y, 2.*a.x*a.y)
#define c_mul(a, b) vec2(a.x*b.x-a.y*b.y, a.x*b.y+a.y*b.x)
#define c_div(a, b) vec2((a.x*b.x+a.y*b.y)/(b.x*b.x+b.y*b.y), (a.y*b.x-a.x*b.y)/(b.x*b.x+b.y*b.y))
#define c_sin(a) vec2(sin(a.x)*cosh(a.y), cos(a.x)*sinh(a.y))
#define c_cos(a) vec2(cos(a.x)*cosh(a.y), -sin(a.x)*sinh(a.y))
#define c_cartToPolar(a) vec2(length(a), atan(a.y, a.x))
#define c_polarToCart(a) a.x * vec2(cos(a.y), sin(a.y))

vec2 c_sqrt(vec2 a){
    float r = sqrt(a.x*a.x+a.y*a.y);
    float rpart = sqrt(.5*(r+a.x));
    float ipart = sqrt(.5*(r-a.x));
    if (a.y < 0.) ipart = -ipart;
    return vec2(rpart, ipart);
}

vec2 c_tan(vec2 a){ return c_div(c_sin(a), c_cos(a)); }

vec2 c_log(vec2 a){
    float rpart = length(a);
    float ipart = atan(a.y, a.x);
    if (ipart > PI) ipart -= 2. * PI;
    return vec2(log(rpart), ipart);
}

vec2 c_toThe(vec2 a, float b){ return c_exp(b*c_log(a)); }
vec2 c_toThe(vec2 a, vec2 b){ return c_exp(c_mul(b, c_log(a))); }

void main(void) {
    vec2 p = 2. * (gl_FragCoord.xy-.5*resolution.xy) / resolution.y;
    
    
    // some transformations
    float nArms = 1.+floor(16.*abs(fract(.025*time)-.5));
    p = rotate2(p, .2*time);
    p /= dot(p, p);
    p = c_toThe(p, nArms);
    p.x += 1.;
    p = c_toThe(p, .5);
    p.x += .5;
    p /= dot(p, p);
    p.x -= 1.;
    p = rotate2(p, .1*time);
    
    
    // get data for the disk model
    vec4 pI = poincareGetStuff(N, P);
    
    // build the disk
    for(int i=0; i<Iters; i++)
        p = poincareCreateUVs(p, pI);
    
    // uncomment to mirror from disk's margin
    //p = cInvertMirror(p, vec2(0., 0.), 1., 1.);
    
    
    // this is the pattern for each polygon
    float f = 1. - dot(p, p) / pow(pI.z, 2.);
    
    glFragColor = vec4(vec3(f)*vec3(1.7, 1.2, .8), 1.);
}
