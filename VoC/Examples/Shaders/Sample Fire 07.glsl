#version 420

// original https://www.shadertoy.com/view/3dfXRM

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

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

//###############################################################################

//----------------------------------------------------------------------------------------
float hashOld12(vec2 p)
{
    // Two typical hashes...
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
    
    // This one is better, but it still stretches out quite quickly...
    // But it's really quite bad on my Mac(!)
    //return fract(sin(dot(p, vec2(1.0,113.0)))*43758.5453123);

}

vec3 hashOld33( vec3 p )
{
    p = vec3( dot(p,vec3(127.1,311.7, 74.7)),
              dot(p,vec3(269.5,183.3,246.1)),
              dot(p,vec3(113.5,271.9,124.6)));

    return fract(sin(p)*43758.5453123);
}

vec3 hash33w(vec3 p3)
{
    p3 = fract(p3 * vec3(0.1031f, 0.1030f, 0.0973f));
    p3 += dot(p3, p3.yxz+19.19f);
    return fract((p3.xxy + p3.yxx)*p3.zyx);

}

vec3 hash33s(vec3 p3)
{
    p3 = fract(p3 * vec3(0.1031f, 0.11369f, 0.13787f));
    p3 += dot(p3, p3.yxz + 19.19f);
    return -1.0f + 2.0f * fract(vec3((p3.x + p3.y) * p3.z, (p3.x + p3.z) * p3.y, (p3.y + p3.z) * p3.x));
}

// I think from iq...
float simplex(vec3 pos)
{
    const float K1 = 0.333333333;
    const float K2 = 0.166666667;

    vec3 i = floor(pos + (pos.x + pos.y + pos.z) * K1);
    vec3 d0 = pos - (i - (i.x + i.y + i.z) * K2);

    vec3 e = step(vec3(0.0), d0 - d0.yzx);
    vec3 i1 = e * (1.0 - e.zxy);
    vec3 i2 = 1.0 - e.zxy * (1.0 - e);

    vec3 d1 = d0 - (i1 - 1.0 * K2);
    vec3 d2 = d0 - (i2 - 2.0 * K2);
    vec3 d3 = d0 - (1.0 - 3.0 * K2);

    vec4 h = max(0.6 - vec4(dot(d0, d0), dot(d1, d1), dot(d2, d2), dot(d3, d3)), 0.0);
    vec4 n = h * h * h * h * vec4(dot(d0, hash33s(i)), dot(d1, hash33s(i + i1)), dot(d2, hash33s(i + i2)), dot(d3, hash33s(i + 1.0)));

    return dot(vec4(31.316), n);
}

float simplexFbm(vec3 pos, float octaves, float persistence, float scale)
{
    float final        = 0.0;
    float amplitude    = 1.0;
    float maxAmplitude = 0.0;

    for(float i = 0.0; i < octaves; ++i)
    {
        final        += simplex(pos * scale) * amplitude;
        scale        *= 2.0;
        maxAmplitude += amplitude;
        amplitude    *= persistence;
    }

    return (min(final, 1.0f) + 1.0f) * 0.5f;
}

#define PI acos(-1.)
#define TAU (PI+PI)

#define rot(x) mat2(cos(x),-sin(x),sin(x),cos(x))

vec3 hsv(float x) {
    return .5+.5*sin(x+vec3(0,TAU/3.,2.*TAU/3.));
}

float aspect;

float getTime(float id, float time) {
    return time + hash11(id);
}

vec2 getPosition(float id, float time) {
    vec2 h = hash21(id);
    float speed = .5+hash11(id);
    vec2 p = fract(h + vec2((.0025+.01*hash11(id))
                            *sin( (speed*h.y + getTime(id,time))*PI ),
                            .25*time))*2.-1. ;
    return p *vec2(aspect,1);
}

float getAngle(float id, float time) {
    return ((hash11(id)*2.-1.)+time)*TAU;
}

float getSmoke(vec2 p, float id, float time) {
    float t = getTime(id,time);
    vec2 c = getPosition(id,t);
    
    float r = .3+hash11(id)*.25;
    float d = length(p-c)-r;
    float a = .3+hash11(id)*.8;
    return (.5+.5*simplex(vec3(rot(getAngle(id,.15*t))*(2.*(p-c)),hash11(id)+.25*t)))
        * smoothstep(0., -r*.75, d) * a * exp(-3.*(c.y*.5+.5));
}

void main(void)
{
    vec2 u = gl_FragCoord.xy;
    vec4 O = glFragColor;

    vec2 R = resolution.xy, p = (u+u-R)/R.y;
    aspect = R.x/R.y;
    vec2 uv = u/R;
    
    //p = rot(-PI/4.) * p;
    vec2 p0 = (p - vec2(.025*sin((p.x-time)*PI)*sin(p.y*PI),time)) * vec2(6.,1.);
    float a = pow(.5+.5*simplexFbm(vec3(p0,.75*time),4.,.7,1.),1.4+2.5*uv.y) * exp(-4.*u.y/R.y);
    O *= 0.;
    O.rgb = mix(O.rgb, hsv((1.-a)*TAU/4.), a);
    
    int i = -1, N = 25;
    while(++i<N) {
        float alpha = getSmoke(p,float(i),time);
        O.rgb = mix(O.rgb, vec3(.5),  alpha);
    }
    
   O.rgb = sqrt(O.rgb);// gamma 2.2

   glFragColor = O;
}
