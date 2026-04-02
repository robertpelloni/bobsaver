#version 420

// original https://www.shadertoy.com/view/XltyW8

uniform int frames;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14159265359

#define N vec2( 0, 1)
#define E vec2( 1, 0)
#define S vec2( 0,-1)
#define W vec2(-1, 0)

// Hash without Sine
// Creative Commons Attribution-ShareAlike 4.0 International Public License
// Created by David Hoskins.

// https://www.shadertoy.com/view/4djSRW
// Trying to find a Hash function that is the same on ALL systens
// and doesn't rely on trigonometry functions that change accuracy 
// depending on GPU. 
// New one on the left, sine function on the right.
// It appears to be the same speed, but I suppose that depends.

// * Note. It still goes wrong eventually!
// * Try full-screen paused to see details.

#define ITERATIONS 4

// *** Change these to suit your range of random numbers..

// *** Use this for integer stepped ranges, ie Value-Noise/Perlin noise functions.
#define HASHSCALE1 .1031
#define HASHSCALE3 vec3(.1031, .1030, .0973)
#define HASHSCALE4 vec4(.1031, .1030, .0973, .1099)

// For smaller input rangers like audio tick or 0-1 UVs use these...
//#define HASHSCALE1 443.8975
//#define HASHSCALE3 vec3(443.897, 441.423, 437.195)
//#define HASHSCALE4 vec3(443.897, 441.423, 437.195, 444.129)

//----------------------------------------------------------------------------------------
//  1 out, 1 in...
float hash11(float p)
{
        vec3 p3  = fract(vec3(p) * HASHSCALE1);
    p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.x + p3.y) * p3.z);
}

//----------------------------------------------------------------------------------------
//  1 out, 2 in...
float hash12(vec2 p)
{
        vec3 p3  = fract(vec3(p.xyx) * HASHSCALE1);
    p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.x + p3.y) * p3.z);
}

//----------------------------------------------------------------------------------------
//  1 out, 3 in...
float hash13(vec3 p3)
{
        p3  = fract(p3 * HASHSCALE1);
    p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.x + p3.y) * p3.z);
}

//----------------------------------------------------------------------------------------
//  2 out, 1 in...
vec2 hash21(float p)
{
        vec3 p3 = fract(vec3(p) * HASHSCALE3);
        p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.xx+p3.yz)*p3.zy);

}

//----------------------------------------------------------------------------------------
///  2 out, 2 in...
vec2 hash22(vec2 p)
{
        vec3 p3 = fract(vec3(p.xyx) * HASHSCALE3);
    p3 += dot(p3, p3.yzx+19.19);
    return fract((p3.xx+p3.yz)*p3.zy);

}

//----------------------------------------------------------------------------------------
///  2 out, 3 in...
vec2 hash23(vec3 p3)
{
        p3 = fract(p3 * HASHSCALE3);
    p3 += dot(p3, p3.yzx+19.19);
    return fract((p3.xx+p3.yz)*p3.zy);
}

//----------------------------------------------------------------------------------------
//  3 out, 1 in...
vec3 hash31(float p)
{
   vec3 p3 = fract(vec3(p) * HASHSCALE3);
   p3 += dot(p3, p3.yzx+19.19);
   return fract((p3.xxy+p3.yzz)*p3.zyx); 
}

//----------------------------------------------------------------------------------------
///  3 out, 2 in...
vec3 hash32(vec2 p)
{
        vec3 p3 = fract(vec3(p.xyx) * HASHSCALE3);
    p3 += dot(p3, p3.yxz+19.19);
    return fract((p3.xxy+p3.yzz)*p3.zyx);
}

//----------------------------------------------------------------------------------------
///  3 out, 3 in...
vec3 hash33(vec3 p3)
{
        p3 = fract(p3 * HASHSCALE3);
    p3 += dot(p3, p3.yxz+19.19);
    return fract((p3.xxy + p3.yxx)*p3.zyx);

}

//----------------------------------------------------------------------------------------
// 4 out, 1 in...
vec4 hash41(float p)
{
        vec4 p4 = fract(vec4(p) * HASHSCALE4);
    p4 += dot(p4, p4.wzxy+19.19);
    return fract((p4.xxyz+p4.yzzw)*p4.zywx);
    
}

//----------------------------------------------------------------------------------------
// 4 out, 2 in...
vec4 hash42(vec2 p)
{
        vec4 p4 = fract(vec4(p.xyxy) * HASHSCALE4);
    p4 += dot(p4, p4.wzxy+19.19);
    return fract((p4.xxyz+p4.yzzw)*p4.zywx);

}

//----------------------------------------------------------------------------------------
// 4 out, 3 in...
vec4 hash43(vec3 p)
{
        vec4 p4 = fract(vec4(p.xyzx)  * HASHSCALE4);
    p4 += dot(p4, p4.wzxy+19.19);
    return fract((p4.xxyz+p4.yzzw)*p4.zywx);
}

//----------------------------------------------------------------------------------------
// 4 out, 4 in...
vec4 hash44(vec4 p4)
{
        p4 = fract(p4  * HASHSCALE4);
    p4 += dot(p4, p4.wzxy+19.19);
    return fract((p4.xxyz+p4.yzzw)*p4.zywx);
}

// By David Hoskins, May 2014. @ https://www.shadertoy.com/view/4dsXWn
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

float Noise(in vec3 p)
{
    vec3 i = floor(p);
        vec3 f = fract(p); 
        f *= f * (3.0-2.0*f);

    return mix(
                mix(mix(hash13(i + vec3(0.,0.,0.)), hash13(i + vec3(1.,0.,0.)),f.x),
                        mix(hash13(i + vec3(0.,1.,0.)), hash13(i + vec3(1.,1.,0.)),f.x),
                        f.y),
                mix(mix(hash13(i + vec3(0.,0.,1.)), hash13(i + vec3(1.,0.,1.)),f.x),
                        mix(hash13(i + vec3(0.,1.,1.)), hash13(i + vec3(1.,1.,1.)),f.x),
                        f.y),
                f.z);
}

const mat3 m = mat3( 0.00,  0.80,  0.60,
                    -0.80,  0.36, -0.48,
                    -0.60, -0.48,  0.64 ) * 1.7;

float FBM( vec3 p )
{
    float f;
        
        f = 0.5000 * Noise(p); p = m*p;
        f += 0.2500 * Noise(p); p = m*p;
        f += 0.1250 * Noise(p); p = m*p;
        f += 0.0625   * Noise(p); p = m*p;
        f += 0.03125  * Noise(p); p = m*p;
        f += 0.015625 * Noise(p);
    return f;
}

float rexp(vec2 p) {
    return -log(1e-4 + (1. - 2e-4) * hash12(p));
}

float line(vec2 a, vec2 b, vec2 p, float width) {
    // http://www.iquilezles.org/www/articles/distfunctions/distfunctions.htm
    vec2 pa = p - a, ba = b - a;
    float h = clamp(dot(pa,ba) / dot(ba,ba), 0., 1.);    
    float d = length(pa - ba * h);
    float x = distance(p,a) / (distance(p,a) + distance(p,b));
    return 1.5 * mix(rexp(a), rexp(b), x) * smoothstep(width, 0., d) * smoothstep(1.75, 0.5, distance(a,b));
}

float network(vec2 p, float width) {
    // based on https://www.shadertoy.com/view/lscczl
    vec2 c = floor(p) + hash22(floor(p));
    vec2 n = floor(p) + N + hash22(floor(p) + N);
    vec2 e = floor(p) + E + hash22(floor(p) + E);
    vec2 s = floor(p) + S + hash22(floor(p) + S);
    vec2 w = floor(p) + W + hash22(floor(p) + W);
    
    float m = 0.;
    m += line(n, e, p, width);
    m += line(e, s, p, width);
    m += line(s, w, p, width);
    m += line(w, n, p, width);
   
    for (float y = -1.; y <= 1.; y++) {
        for (float x = -1.; x <= 1.; x++) {
            vec2 q = floor(p) + vec2(x,y) + hash22(floor(p) + vec2(x,y));
            float intensity = distance(p,q) / clamp(rexp(floor(p) + vec2(x,y)), 0., 1.);
            m += line(c, q, p, width);
            m += 5. * smoothstep(0.09, 0., intensity);
        }
    }
    
    return m;
}

float speckle(vec2 p, float density) {
    float m = 0.;
    for (float y = -1.; y <= 1.; y++) {
        for (float x = -1.; x <= 1.; x++) {
            vec2 q = floor(p) + vec2(x,y) + hash22(floor(p) + vec2(x,y));
            m += 1.5 * rexp(p) * smoothstep(1., 0.5, distance(p,q) / clamp(density, 0., 1.));
        }
    }
    return m;
}

void main(void) {
    vec2 uv = (gl_FragCoord.xy + vec2(frames,0)) / resolution.y;
    uv += 0.015 * vec2(FBM(vec3(50. * uv, 1)), FBM(vec3(50. * uv, 2))); // wiggle
    
    float height = FBM(vec3(6. * uv, 3)) - 0.5;
    if (height < 0.) {
        glFragColor = vec4(0.00, 0.01, 0.11, 1);
    } else {
        float d = 0.75;
        d += 0.5 * network(50. * uv, 0.150);
        d += 1.0 * network(15. * uv, 0.045);
        d += 2.0 * network( 5. * uv, 0.015);
        d += smoothstep(0.04, 0., height); // coast
        d *= 0.1 + clamp(2. * FBM(vec3(12. * uv, 0)) - 0.5, 0., 1.);

        float a = speckle(300. * uv, d);
        if (d > 5.) a = d;
        a *= 0.5 * FBM(vec3(50. * uv, time));
        
        glFragColor = vec4(0.02, 0.03, 0.15, 1);
        glFragColor.rgb *= 1. + 0.7 * clamp(FBM(vec3(100. * uv, 0)) - 0.15, 0., 1.);
        glFragColor = mix(glFragColor, 0.75 * sqrt(d) * vec4(0.95, 0.76, 0.47, 1), smoothstep(0., 1., a));
    }
}
