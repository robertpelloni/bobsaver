#version 420

/*
Displays all complex roots of a set of polynomials.
Polynomial is of the form:

±z^8 ±z^7 ±z^6 ±z^5 ±z^4 ... ±z -C

0th-order coefficient, C, is a complex value that changes over time, favoring 0.

A somewhat less symmetrical pattern, but one which reveals more structure, is achieved 
by replacing all or most of the negative coefficients with 0.

Jonathan Lidbeck
*/

// glslsandbox changes:
//iGlobalTime ==> time
//iResolution ==> resolution
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;
// uniform vec4 glFragColor;
// uniform vec2 gl_FragCoord;

// Configuration

#define MULTICOLOR true

#define MAP_DOTS true
#define MAP_AXES true

// Constants

#define TWOPI 6.28318530718
#define PI 3.14159265359
const vec2 one=vec2(1.,0.);

const vec4 purple = vec4(5., 1., 10., 1.);
const vec4 red = vec4(10., 2., 1., 1.);
const vec4 orange = vec4(9., 4., 0.3, 1.);
const vec4 yellow = vec4(8., 5., 1., 1.);
const vec4 green = vec4(3., 9., 1., 1.);
const vec4 teal = vec4(1., 4., 10., 1.);

mat4 colors = mat4(purple, teal, orange, green);

float pulse1 = sin(time * 3.);
float pulse2 = pulse1 * pulse1;
float pulse4 = pulse2 * pulse2;
float pulse = pulse4 * pulse4;

#ifdef MAP_DOTS
float dimness = (10000. );//* (1. - cos(time * 0.2)) );
#else
float dimness = (1000000. * mouse.y);
#endif

vec2 csq(vec2 v) {
    return vec2(v.x*v.x - v.y*v.y, 2.*v.x*v.y);
}

vec2 cmul(vec2 a, vec2 b) {
    return vec2(a.x*b.x - a.y*b.y, a.x*b.y + a.y*b.x);
}

// complex to integer exponent
// computes all z^N for 1<=N<=9
void cpowers(vec2 z, inout vec2 powers[10]) {
    powers[8] = csq(powers[4] = csq(powers[2] = csq(z)));
    powers[6] = csq(powers[3] = cmul(z, powers[2]));
    powers[5] = cmul(z, powers[4]);
    powers[7] = cmul(z, powers[6]);
    powers[9] = cmul(z, powers[8]);
}

vec2 from_polar(vec2 zp) {
    return zp.x * vec2(cos(zp.y), sin(zp.y));
}

// root rendering

#ifdef MULTICOLOR
#define PIP_TYPE vec4
#else
#define PIP_TYPE float
#endif

#ifdef MULTICOLOR
vec4 pipcounter = vec4(1., 0., 0., 0.);
#endif

// color root
PIP_TYPE pip(in vec2 v) {
    float r;
#ifdef MAP_DOTS
    r = dot(v, v);
#else
    r = v.x*v.x;
#endif
    
#ifdef MULTICOLOR
    pipcounter = pipcounter.yzwx;
    return pipcounter / (1. + dimness * r);
#else
    return 1. / (1. + dimness * r);
#endif
}

void main()    // glslsandbox
{
    vec2 cc =   0.5 * (1. + cos(time * 0.2)) * vec2(cos(time * 0.5), sin(time * 0.3));
    
    // rough exposure adjustment: with C near zero, roots pile up and become too bright
    dimness /= distance(cc, vec2(0.));
    
    // complex value from pixel position
    vec2 z = 3. * (gl_FragCoord.xy - resolution.xy * 0.5) / resolution.y;
    
    vec2 zpow[10];
    cpowers(z, zpow);
    
    // aggregate proximities to all roots
    PIP_TYPE f = 
       pip(                                                                  -cc)
     + pip(                                                               +z -cc)
     + pip(                                                      +zpow[2]    -cc)
     + pip(                                                      +zpow[2] +z -cc)
     + pip(                                             +zpow[3]             -cc)
     + pip(                                             +zpow[3]          +z -cc)
     + pip(                                             +zpow[3] +zpow[2]    -cc)
     + pip(                                             +zpow[3] +zpow[2] +z -cc)
     + pip(                                    +zpow[4]                      -cc)
     + pip(                                    +zpow[4]                   +z -cc)
     + pip(                                    +zpow[4]          +zpow[2]    -cc)
     + pip(                                    +zpow[4]          +zpow[2] +z -cc)
     + pip(                                    +zpow[4] +zpow[3]             -cc)
     + pip(                                    +zpow[4] +zpow[3]          +z -cc)
     + pip(                                    +zpow[4] +zpow[3] +zpow[2]    -cc)
     + pip(                                    +zpow[4] +zpow[3] +zpow[2] +z -cc)
     + pip(                           +zpow[5]                               -cc)
     + pip(                           +zpow[5]                            +z -cc)
     + pip(                           +zpow[5]                   +zpow[2]    -cc)
     + pip(                           +zpow[5]                   +zpow[2] +z -cc)
     + pip(                           +zpow[5]          +zpow[3]             -cc)
     + pip(                           +zpow[5]          +zpow[3]          +z -cc)
     + pip(                           +zpow[5]          +zpow[3] +zpow[2]    -cc)
     + pip(                           +zpow[5]          +zpow[3] +zpow[2] +z -cc)
     + pip(                           +zpow[5] +zpow[4]                      -cc)
     + pip(                           +zpow[5] +zpow[4]                   +z -cc)
     + pip(                           +zpow[5] +zpow[4]          +zpow[2]    -cc)
     + pip(                           +zpow[5] +zpow[4]          +zpow[2] +z -cc)
     + pip(                           +zpow[5] +zpow[4] +zpow[3]             -cc)
     + pip(                           +zpow[5] +zpow[4] +zpow[3]          +z -cc)
     + pip(                           +zpow[5] +zpow[4] +zpow[3] +zpow[2]    -cc)
     + pip(                           +zpow[5] +zpow[4] +zpow[3] +zpow[2] +z -cc)
     + pip(                  +zpow[6]                                        -cc)
     + pip(                  +zpow[6]                                     +z -cc)
     + pip(                  +zpow[6]                            +zpow[2]    -cc)
     + pip(                  +zpow[6]                            +zpow[2] +z -cc)
     + pip(                  +zpow[6]                   +zpow[3]             -cc)
     + pip(                  +zpow[6]                   +zpow[3]          +z -cc)
     + pip(                  +zpow[6]                   +zpow[3] +zpow[2]    -cc)
     + pip(                  +zpow[6]                   +zpow[3] +zpow[2] +z -cc)
     + pip(                  +zpow[6]          +zpow[4]                      -cc)
     + pip(                  +zpow[6]          +zpow[4]                   +z -cc)
     + pip(                  +zpow[6]          +zpow[4]          +zpow[2]    -cc)
     + pip(                  +zpow[6]          +zpow[4]          +zpow[2] +z -cc)
     + pip(                  +zpow[6]          +zpow[4] +zpow[3]             -cc)
     + pip(                  +zpow[6]          +zpow[4] +zpow[3]          +z -cc)
     + pip(                  +zpow[6]          +zpow[4] +zpow[3] +zpow[2]    -cc)
     + pip(                  +zpow[6]          +zpow[4] +zpow[3] +zpow[2] +z -cc)
     + pip(                  +zpow[6] +zpow[5]                               -cc)
     + pip(                  +zpow[6] +zpow[5]                            +z -cc)
     + pip(                  +zpow[6] +zpow[5]                   +zpow[2]    -cc)
     + pip(                  +zpow[6] +zpow[5]                   +zpow[2] +z -cc)
     + pip(                  +zpow[6] +zpow[5]          +zpow[3]             -cc)
     + pip(                  +zpow[6] +zpow[5]          +zpow[3]          +z -cc)
     + pip(                  +zpow[6] +zpow[5]          +zpow[3] +zpow[2]    -cc)
     + pip(                  +zpow[6] +zpow[5]          +zpow[3] +zpow[2] +z -cc)
     + pip(                  +zpow[6] +zpow[5] +zpow[4]                      -cc)
     + pip(                  +zpow[6] +zpow[5] +zpow[4]                   +z -cc)
     + pip(                  +zpow[6] +zpow[5] +zpow[4]          +zpow[2]    -cc)
     + pip(                  +zpow[6] +zpow[5] +zpow[4]          +zpow[2] +z -cc)
     + pip(                  +zpow[6] +zpow[5] +zpow[4] +zpow[3]             -cc)
     + pip(                  +zpow[6] +zpow[5] +zpow[4] +zpow[3]          +z -cc)
     + pip(                  +zpow[6] +zpow[5] +zpow[4] +zpow[3] +zpow[2]    -cc)
     + pip(                  +zpow[6] +zpow[5] +zpow[4] +zpow[3] +zpow[2] +z -cc)
     + pip(         +zpow[7]                                                 -cc)
     + pip(         +zpow[7]                                              +z -cc)
     + pip(         +zpow[7]                                     +zpow[2]    -cc)
     + pip(         +zpow[7]                                     +zpow[2] +z -cc)
     + pip(         +zpow[7]                            +zpow[3]             -cc)
     + pip(         +zpow[7]                            +zpow[3]          +z -cc)
     + pip(         +zpow[7]                            +zpow[3] +zpow[2]    -cc)
     + pip(         +zpow[7]                            +zpow[3] +zpow[2] +z -cc)
     + pip(         +zpow[7]                   +zpow[4]                      -cc)
     + pip(         +zpow[7]                   +zpow[4]                   +z -cc)
     + pip(         +zpow[7]                   +zpow[4]          +zpow[2]    -cc)
     + pip(         +zpow[7]                   +zpow[4]          +zpow[2] +z -cc)
     + pip(         +zpow[7]                   +zpow[4] +zpow[3]             -cc)
     + pip(         +zpow[7]                   +zpow[4] +zpow[3]          +z -cc)
     + pip(         +zpow[7]                   +zpow[4] +zpow[3] +zpow[2]    -cc)
     + pip(         +zpow[7]                   +zpow[4] +zpow[3] +zpow[2] +z -cc)
     + pip(         +zpow[7]          +zpow[5]                               -cc)
     + pip(         +zpow[7]          +zpow[5]                            +z -cc)
     + pip(         +zpow[7]          +zpow[5]                   +zpow[2]    -cc)
     + pip(         +zpow[7]          +zpow[5]                   +zpow[2] +z -cc)
     + pip(         +zpow[7]          +zpow[5]          +zpow[3]             -cc)
     + pip(         +zpow[7]          +zpow[5]          +zpow[3]          +z -cc)
     + pip(         +zpow[7]          +zpow[5]          +zpow[3] +zpow[2]    -cc)
     + pip(         +zpow[7]          +zpow[5]          +zpow[3] +zpow[2] +z -cc)
     + pip(         +zpow[7]          +zpow[5] +zpow[4]                      -cc)
     + pip(         +zpow[7]          +zpow[5] +zpow[4]                   +z -cc)
     + pip(         +zpow[7]          +zpow[5] +zpow[4]          +zpow[2]    -cc)
     + pip(         +zpow[7]          +zpow[5] +zpow[4]          +zpow[2] +z -cc)
     + pip(         +zpow[7]          +zpow[5] +zpow[4] +zpow[3]             -cc)
     + pip(         +zpow[7]          +zpow[5] +zpow[4] +zpow[3]          +z -cc)
     + pip(         +zpow[7]          +zpow[5] +zpow[4] +zpow[3] +zpow[2]    -cc)
     + pip(         +zpow[7]          +zpow[5] +zpow[4] +zpow[3] +zpow[2] +z -cc)
     + pip(         +zpow[7] +zpow[6]                                        -cc)
     + pip(         +zpow[7] +zpow[6]                                     +z -cc)
     + pip(         +zpow[7] +zpow[6]                            +zpow[2]    -cc)
     + pip(         +zpow[7] +zpow[6]                            +zpow[2] +z -cc)
     + pip(         +zpow[7] +zpow[6]                   +zpow[3]             -cc)
     + pip(         +zpow[7] +zpow[6]                   +zpow[3]          +z -cc)
     + pip(         +zpow[7] +zpow[6]                   +zpow[3] +zpow[2]    -cc)
     + pip(         +zpow[7] +zpow[6]                   +zpow[3] +zpow[2] +z -cc)
     + pip(         +zpow[7] +zpow[6]          +zpow[4]                      -cc)
     + pip(         +zpow[7] +zpow[6]          +zpow[4]                   +z -cc)
     + pip(         +zpow[7] +zpow[6]          +zpow[4]          +zpow[2]    -cc)
     + pip(         +zpow[7] +zpow[6]          +zpow[4]          +zpow[2] +z -cc)
     + pip(         +zpow[7] +zpow[6]          +zpow[4] +zpow[3]             -cc)
     + pip(         +zpow[7] +zpow[6]          +zpow[4] +zpow[3]          +z -cc)
     + pip(         +zpow[7] +zpow[6]          +zpow[4] +zpow[3] +zpow[2]    -cc)
     + pip(         +zpow[7] +zpow[6]          +zpow[4] +zpow[3] +zpow[2] +z -cc)
     + pip(         +zpow[7] +zpow[6] +zpow[5]                               -cc)
     + pip(         +zpow[7] +zpow[6] +zpow[5]                            +z -cc)
     + pip(         +zpow[7] +zpow[6] +zpow[5]                   +zpow[2]    -cc)
     + pip(         +zpow[7] +zpow[6] +zpow[5]                   +zpow[2] +z -cc)
     + pip(         +zpow[7] +zpow[6] +zpow[5]          +zpow[3]             -cc)
     + pip(         +zpow[7] +zpow[6] +zpow[5]          +zpow[3]          +z -cc)
     + pip(         +zpow[7] +zpow[6] +zpow[5]          +zpow[3] +zpow[2]    -cc)
     + pip(         +zpow[7] +zpow[6] +zpow[5]          +zpow[3] +zpow[2] +z -cc)
     + pip(         +zpow[7] +zpow[6] +zpow[5] +zpow[4]                      -cc)
     + pip(         +zpow[7] +zpow[6] +zpow[5] +zpow[4]                   +z -cc)
     + pip(         +zpow[7] +zpow[6] +zpow[5] +zpow[4]          +zpow[2]    -cc)
     + pip(         +zpow[7] +zpow[6] +zpow[5] +zpow[4]          +zpow[2] +z -cc)
     + pip(         +zpow[7] +zpow[6] +zpow[5] +zpow[4] +zpow[3]             -cc)
     + pip(         +zpow[7] +zpow[6] +zpow[5] +zpow[4] +zpow[3]          +z -cc)
     + pip(         +zpow[7] +zpow[6] +zpow[5] +zpow[4] +zpow[3] +zpow[2]    -cc)
     + pip(         +zpow[7] +zpow[6] +zpow[5] +zpow[4] +zpow[3] +zpow[2] +z -cc);
  f += pip(+zpow[8]                                                          -cc)
     + pip(+zpow[8]                                                       +z -cc)
     + pip(+zpow[8]                                              +zpow[2]    -cc)
     + pip(+zpow[8]                                              +zpow[2] +z -cc)
     + pip(+zpow[8]                                     +zpow[3]             -cc)
     + pip(+zpow[8]                                     +zpow[3]          +z -cc)
     + pip(+zpow[8]                                     +zpow[3] +zpow[2]    -cc)
     + pip(+zpow[8]                                     +zpow[3] +zpow[2] +z -cc)
     + pip(+zpow[8]                            +zpow[4]                      -cc)
     + pip(+zpow[8]                            +zpow[4]                   +z -cc)
     + pip(+zpow[8]                            +zpow[4]          +zpow[2]    -cc)
     + pip(+zpow[8]                            +zpow[4]          +zpow[2] +z -cc)
     + pip(+zpow[8]                            +zpow[4] +zpow[3]             -cc)
     + pip(+zpow[8]                            +zpow[4] +zpow[3]          +z -cc)
     + pip(+zpow[8]                            +zpow[4] +zpow[3] +zpow[2]    -cc)
     + pip(+zpow[8]                            +zpow[4] +zpow[3] +zpow[2] +z -cc)
     + pip(+zpow[8]                   +zpow[5]                               -cc)
     + pip(+zpow[8]                   +zpow[5]                            +z -cc)
     + pip(+zpow[8]                   +zpow[5]                   +zpow[2]    -cc)
     + pip(+zpow[8]                   +zpow[5]                   +zpow[2] +z -cc)
     + pip(+zpow[8]                   +zpow[5]          +zpow[3]             -cc)
     + pip(+zpow[8]                   +zpow[5]          +zpow[3]          +z -cc)
     + pip(+zpow[8]                   +zpow[5]          +zpow[3] +zpow[2]    -cc)
     + pip(+zpow[8]                   +zpow[5]          +zpow[3] +zpow[2] +z -cc)
     + pip(+zpow[8]                   +zpow[5] +zpow[4]                      -cc)
     + pip(+zpow[8]                   +zpow[5] +zpow[4]                   +z -cc)
     + pip(+zpow[8]                   +zpow[5] +zpow[4]          +zpow[2]    -cc)
     + pip(+zpow[8]                   +zpow[5] +zpow[4]          +zpow[2] +z -cc)
     + pip(+zpow[8]                   +zpow[5] +zpow[4] +zpow[3]             -cc)
     + pip(+zpow[8]                   +zpow[5] +zpow[4] +zpow[3]          +z -cc)
     + pip(+zpow[8]                   +zpow[5] +zpow[4] +zpow[3] +zpow[2]    -cc)
     + pip(+zpow[8]                   +zpow[5] +zpow[4] +zpow[3] +zpow[2] +z -cc)
     + pip(+zpow[8]          +zpow[6]                                        -cc)
     + pip(+zpow[8]          +zpow[6]                                     +z -cc)
     + pip(+zpow[8]          +zpow[6]                            +zpow[2]    -cc)
     + pip(+zpow[8]          +zpow[6]                            +zpow[2] +z -cc)
     + pip(+zpow[8]          +zpow[6]                   +zpow[3]             -cc)
     + pip(+zpow[8]          +zpow[6]                   +zpow[3]          +z -cc)
     + pip(+zpow[8]          +zpow[6]                   +zpow[3] +zpow[2]    -cc)
     + pip(+zpow[8]          +zpow[6]                   +zpow[3] +zpow[2] +z -cc)
     + pip(+zpow[8]          +zpow[6]          +zpow[4]                      -cc)
     + pip(+zpow[8]          +zpow[6]          +zpow[4]                   +z -cc)
     + pip(+zpow[8]          +zpow[6]          +zpow[4]          +zpow[2]    -cc)
     + pip(+zpow[8]          +zpow[6]          +zpow[4]          +zpow[2] +z -cc)
     + pip(+zpow[8]          +zpow[6]          +zpow[4] +zpow[3]             -cc)
     + pip(+zpow[8]          +zpow[6]          +zpow[4] +zpow[3]          +z -cc)
     + pip(+zpow[8]          +zpow[6]          +zpow[4] +zpow[3] +zpow[2]    -cc)
     + pip(+zpow[8]          +zpow[6]          +zpow[4] +zpow[3] +zpow[2] +z -cc)
     + pip(+zpow[8]          +zpow[6] +zpow[5]                               -cc)
     + pip(+zpow[8]          +zpow[6] +zpow[5]                            +z -cc)
     + pip(+zpow[8]          +zpow[6] +zpow[5]                   +zpow[2]    -cc)
     + pip(+zpow[8]          +zpow[6] +zpow[5]                   +zpow[2] +z -cc)
     + pip(+zpow[8]          +zpow[6] +zpow[5]          +zpow[3]             -cc)
     + pip(+zpow[8]          +zpow[6] +zpow[5]          +zpow[3]          +z -cc)
     + pip(+zpow[8]          +zpow[6] +zpow[5]          +zpow[3] +zpow[2]    -cc)
     + pip(+zpow[8]          +zpow[6] +zpow[5]          +zpow[3] +zpow[2] +z -cc)
     + pip(+zpow[8]          +zpow[6] +zpow[5] +zpow[4]                      -cc)
     + pip(+zpow[8]          +zpow[6] +zpow[5] +zpow[4]                   +z -cc)
     + pip(+zpow[8]          +zpow[6] +zpow[5] +zpow[4]          +zpow[2]    -cc)
     + pip(+zpow[8]          +zpow[6] +zpow[5] +zpow[4]          +zpow[2] +z -cc)
     + pip(+zpow[8]          +zpow[6] +zpow[5] +zpow[4] +zpow[3]             -cc)
     + pip(+zpow[8]          +zpow[6] +zpow[5] +zpow[4] +zpow[3]          +z -cc)
     + pip(+zpow[8]          +zpow[6] +zpow[5] +zpow[4] +zpow[3] +zpow[2]    -cc)
     + pip(+zpow[8]          +zpow[6] +zpow[5] +zpow[4] +zpow[3] +zpow[2] +z -cc)
     + pip(+zpow[8] +zpow[7]                                                 -cc)
     + pip(+zpow[8] +zpow[7]                                              +z -cc)
     + pip(+zpow[8] +zpow[7]                                     +zpow[2]    -cc)
     + pip(+zpow[8] +zpow[7]                                     +zpow[2] +z -cc)
     + pip(+zpow[8] +zpow[7]                            +zpow[3]             -cc)
     + pip(+zpow[8] +zpow[7]                            +zpow[3]          +z -cc)
     + pip(+zpow[8] +zpow[7]                            +zpow[3] +zpow[2]    -cc)
     + pip(+zpow[8] +zpow[7]                            +zpow[3] +zpow[2] +z -cc)
     + pip(+zpow[8] +zpow[7]                   +zpow[4]                      -cc)
     + pip(+zpow[8] +zpow[7]                   +zpow[4]                   +z -cc)
     + pip(+zpow[8] +zpow[7]                   +zpow[4]          +zpow[2]    -cc)
     + pip(+zpow[8] +zpow[7]                   +zpow[4]          +zpow[2] +z -cc)
     + pip(+zpow[8] +zpow[7]                   +zpow[4] +zpow[3]             -cc)
     + pip(+zpow[8] +zpow[7]                   +zpow[4] +zpow[3]          +z -cc)
     + pip(+zpow[8] +zpow[7]                   +zpow[4] +zpow[3] +zpow[2]    -cc)
     + pip(+zpow[8] +zpow[7]                   +zpow[4] +zpow[3] +zpow[2] +z -cc)
     + pip(+zpow[8] +zpow[7]          +zpow[5]                               -cc)
     + pip(+zpow[8] +zpow[7]          +zpow[5]                            +z -cc)
     + pip(+zpow[8] +zpow[7]          +zpow[5]                   +zpow[2]    -cc)
     + pip(+zpow[8] +zpow[7]          +zpow[5]                   +zpow[2] +z -cc)
     + pip(+zpow[8] +zpow[7]          +zpow[5]          +zpow[3]             -cc)
     + pip(+zpow[8] +zpow[7]          +zpow[5]          +zpow[3]          +z -cc)
     + pip(+zpow[8] +zpow[7]          +zpow[5]          +zpow[3] +zpow[2]    -cc)
     + pip(+zpow[8] +zpow[7]          +zpow[5]          +zpow[3] +zpow[2] +z -cc)
     + pip(+zpow[8] +zpow[7]          +zpow[5] +zpow[4]                      -cc)
     + pip(+zpow[8] +zpow[7]          +zpow[5] +zpow[4]                   +z -cc)
     + pip(+zpow[8] +zpow[7]          +zpow[5] +zpow[4]          +zpow[2]    -cc)
     + pip(+zpow[8] +zpow[7]          +zpow[5] +zpow[4]          +zpow[2] +z -cc)
     + pip(+zpow[8] +zpow[7]          +zpow[5] +zpow[4] +zpow[3]             -cc)
     + pip(+zpow[8] +zpow[7]          +zpow[5] +zpow[4] +zpow[3]          +z -cc)
     + pip(+zpow[8] +zpow[7]          +zpow[5] +zpow[4] +zpow[3] +zpow[2]    -cc)
     + pip(+zpow[8] +zpow[7]          +zpow[5] +zpow[4] +zpow[3] +zpow[2] +z -cc)
     + pip(+zpow[8] +zpow[7] +zpow[6]                                        -cc)
     + pip(+zpow[8] +zpow[7] +zpow[6]                                     +z -cc)
     + pip(+zpow[8] +zpow[7] +zpow[6]                            +zpow[2]    -cc)
     + pip(+zpow[8] +zpow[7] +zpow[6]                            +zpow[2] +z -cc)
     + pip(+zpow[8] +zpow[7] +zpow[6]                   +zpow[3]             -cc)
     + pip(+zpow[8] +zpow[7] +zpow[6]                   +zpow[3]          +z -cc)
     + pip(+zpow[8] +zpow[7] +zpow[6]                   +zpow[3] +zpow[2]    -cc)
     + pip(+zpow[8] +zpow[7] +zpow[6]                   +zpow[3] +zpow[2] +z -cc)
     + pip(+zpow[8] +zpow[7] +zpow[6]          +zpow[4]                      -cc)
     + pip(+zpow[8] +zpow[7] +zpow[6]          +zpow[4]                   +z -cc)
     + pip(+zpow[8] +zpow[7] +zpow[6]          +zpow[4]          +zpow[2]    -cc)
     + pip(+zpow[8] +zpow[7] +zpow[6]          +zpow[4]          +zpow[2] +z -cc)
     + pip(+zpow[8] +zpow[7] +zpow[6]          +zpow[4] +zpow[3]             -cc)
     + pip(+zpow[8] +zpow[7] +zpow[6]          +zpow[4] +zpow[3]          +z -cc)
     + pip(+zpow[8] +zpow[7] +zpow[6]          +zpow[4] +zpow[3] +zpow[2]    -cc)
     + pip(+zpow[8] +zpow[7] +zpow[6]          +zpow[4] +zpow[3] +zpow[2] +z -cc)
     + pip(+zpow[8] +zpow[7] +zpow[6] +zpow[5]                               -cc)
     + pip(+zpow[8] +zpow[7] +zpow[6] +zpow[5]                            +z -cc)
     + pip(+zpow[8] +zpow[7] +zpow[6] +zpow[5]                   +zpow[2]    -cc)
     + pip(+zpow[8] +zpow[7] +zpow[6] +zpow[5]                   +zpow[2] +z -cc)
     + pip(+zpow[8] +zpow[7] +zpow[6] +zpow[5]          +zpow[3]             -cc)
     + pip(+zpow[8] +zpow[7] +zpow[6] +zpow[5]          +zpow[3]          +z -cc)
     + pip(+zpow[8] +zpow[7] +zpow[6] +zpow[5]          +zpow[3] +zpow[2]    -cc)
     + pip(+zpow[8] +zpow[7] +zpow[6] +zpow[5]          +zpow[3] +zpow[2] +z -cc)
     + pip(+zpow[8] +zpow[7] +zpow[6] +zpow[5] +zpow[4]                      -cc)
     + pip(+zpow[8] +zpow[7] +zpow[6] +zpow[5] +zpow[4]                   +z -cc)
     + pip(+zpow[8] +zpow[7] +zpow[6] +zpow[5] +zpow[4]          +zpow[2]    -cc)
     + pip(+zpow[8] +zpow[7] +zpow[6] +zpow[5] +zpow[4]          +zpow[2] +z -cc)
     + pip(+zpow[8] +zpow[7] +zpow[6] +zpow[5] +zpow[4] +zpow[3]             -cc)
     + pip(+zpow[8] +zpow[7] +zpow[6] +zpow[5] +zpow[4] +zpow[3]          +z -cc)
     + pip(+zpow[8] +zpow[7] +zpow[6] +zpow[5] +zpow[4] +zpow[3] +zpow[2]    -cc)
     + pip(+zpow[8] +zpow[7] +zpow[6] +zpow[5] +zpow[4] +zpow[3] +zpow[2] +z -cc);

#ifdef MULTICOLOR
    glFragColor = colors * f;
#else
    glFragColor = mix(teal, orange, mod(time*0.2/PI, 1.));
    glFragColor = glFragColor * f;
#endif
}
