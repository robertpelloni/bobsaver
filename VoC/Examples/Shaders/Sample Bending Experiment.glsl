#version 420

// original https://www.shadertoy.com/view/WltcRH

uniform int frames;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Cheap Rotation by las:
// http://www.pouet.net/topic.php?which=7931&page=1

// General
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#define framesRate 24.
#define ZERO min(0,frames)
#define PI 3.14159265
#define HALF_PI 1.5707963267948966
#define PI2 (2.0*PI)
#define PHI (sqrt(5.0)*0.5 + 0.5)
#define saturate(x) clamp(x, 0.0, 1.0)
#define sms(min, max, x) smoothstep(min, max, x)

#define s2u(x) (x*.5+.5)
#define u2s(x) ((x*2.)-1.)
#define pabs(x) sqrt(x*x+.05)
#define sabs(x) sqrt(x*x+1e-2)
#define smin(a,b) ((a)+(b)-sabs((a)-(b)))*.5
#define smax(a,b) ((a)+(b)+sabs((a)-(b)))*.5

// SDF functions
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

float sdPlane(in vec3 p){
    return p.y;
}

float sdEllipsoid(in vec3 p, in vec3 r)
{
    return (length(p/r)-1.0)*min(min(r.x,r.y),r.z);
}

float sdCapsule(vec3 p, float r, float c)
{
    return mix(length(p.xz) - r, length(vec3(p.x, abs(p.y) - c, p.z)) - r, step(c, abs(p.y)));
}

float sdCappedCylinder( vec3 p, vec2 h )
{
    vec2 d = abs(vec2(length(p.xz),p.y)) - h;
    return ((min(max(d.x,d.y),0.0) + length(max(d,0.0))))-0.0;
}

float fOpUnion(in float a,in float b)
{
    return a<b?a:b;
}

vec4 v4OpUnion(in vec4 a,in vec4 b)
{
    return a.x<b.x?a:b;
}

float fOpUnionSmooth(float a,float b,float r)
{
    vec2 u = max(vec2(r - a,r - b), vec2(0));
    return max(r, min (a, b)) - length(u);

    // iq:
    //float h = max(r-abs(a-b),0.0);
    //return min(a, b) - h*h*0.25/r;
}

vec4 v4OpUnionSmooth(vec4 a,vec4 b,float r)
{
    float h=clamp(0.5+0.5*(b.x-a.x)/r,0.0,1.0);
    float res = mix(b.x,a.x,h)-r*h*(1.0-h);
    return vec4(res, mix(b.yzw,a.yzw,h));
}

// Raymarching
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#define ERNST_RENDER_SCALE float(1.)
#define INV_ERNST_RENDER_SCALE (1./ERNST_RENDER_SCALE)
#define MIN_DIST 0.0100
#define MAX_DIST 1000.
#define ITERATION 100
#define MAT_VOID vec3(-1)

#define MAT_ERNST0_002 vec3(0.6921, 0.6105, 0.5361)
#define MAT_ERNST0 vec3(0.8000, 0.8000, 0.8000)
#define MAT_ERNST0_001 vec3(0.6921, 0.5156, 0.5499)

#define AMB_COL vec3(0.6921, 0.8030, 1.)
#define AMB_STRENGTH 0.3000
#define FOG_COL vec3(1., 1., 1.)
#define FOG_START -0.4200
#define FOG_POW 1.

// "init": init camera/lights.
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
vec3  Camera_pos;
vec4  Camera_quat;
float Camera_fov;
vec3  sdLight001_dir;
vec3  sdLight001_col;
float sdLight001_clip_start;
float sdLight001_clip_end;
float sdLight001_softness;
#define L0_dir sdLight001_dir
#define L0_col sdLight001_col
#define L0_str sdLight001_clip_start
#define L0_end sdLight001_clip_end
#define L0_sft sdLight001_softness
vec3  sdLight002_dir;
vec3  sdLight002_col;
float sdLight002_clip_start;
float sdLight002_clip_end;
float sdLight002_softness;
#define L1_dir sdLight002_dir
#define L1_col sdLight002_col
#define L1_str sdLight002_clip_start
#define L1_end sdLight002_clip_end
#define L1_sft sdLight002_softness

void init()
{
    Camera_pos = vec3(0., 0.6800, 19.9716);
    Camera_quat = vec4(0., 0., 0., 1.);
    Camera_fov = 0.3456;
    sdLight001_dir = normalize(vec3(-0.1719, 0.5966, 0.7839));
    sdLight001_col = vec3(1.2428, 1.2082, 1.0403);
    sdLight001_clip_start = 0.0500;
    sdLight001_clip_end = 30.;
    sdLight001_softness = 50.;
    sdLight002_dir = normalize(vec3(0.1719, -0.5966, -0.7839));
    sdLight002_col = vec3(0.0922, 0.0922, 0.0922);
    sdLight002_clip_start = 0.0500;
    sdLight002_clip_end = 30.;
    sdLight002_softness = 50.;

}

// "camera": create camera vectors.
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

vec3 quat_rotate(vec4 quat, vec3 dir)
{
    return dir + 2.0 * cross(quat.xyz, cross(quat.xyz, dir) + quat.w * dir);
}

void perspectiveCam(vec2 uv, out vec3 ro, out vec3 rd)
{
    vec3 dir = quat_rotate(Camera_quat, vec3(0,0,-1)).xzy;
    vec3 up = quat_rotate(Camera_quat, vec3(0,1,0)).xzy;
    vec3 pos = Camera_pos.xzy;
    float fov = Camera_fov;
    vec3 target = pos-dir;

    vec3 cw = normalize(target - pos);
    vec3 cu = normalize(cross(cw, up));
    vec3 cv = normalize(cross(cu, cw));

    mat3 camMat = mat3(cu, cv, cw);
    rd = normalize(camMat * normalize(vec3(sin(fov) * uv.x, sin(fov) * uv.y, -cos(fov))));
    ro = pos;
}

// "Hash without Sine" by Dave_Hoskins:
// https://www.shadertoy.com/view/4djSRW
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

// Hash without Sine
// MIT License...
/* Copyright (c)2014 David Hoskins.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.*/

//----------------------------------------------------------------------------------------
//  1 out, 1 in...
float hash11(float p)
{
    p = fract(p * .1031);
    p *= p + 33.33;
    p *= p + p;
    return fract(p);
}

//----------------------------------------------------------------------------------------
//  1 out, 2 in...
float hash12(vec2 p)
{
    vec3 p3  = fract(vec3(p.xyx) * .1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

//----------------------------------------------------------------------------------------
//  1 out, 3 in...
float hash13(vec3 p3)
{
    p3  = fract(p3 * .1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

//----------------------------------------------------------------------------------------
//  2 out, 1 in...
vec2 hash21(float p)
{
    vec3 p3 = fract(vec3(p) * vec3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.xx+p3.yz)*p3.zy);

}

//----------------------------------------------------------------------------------------
///  2 out, 2 in...
vec2 hash22(vec2 p)
{
    vec3 p3 = fract(vec3(p.xyx) * vec3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yzx+33.33);
    return fract((p3.xx+p3.yz)*p3.zy);

}

//----------------------------------------------------------------------------------------
///  2 out, 3 in...
vec2 hash23(vec3 p3)
{
    p3 = fract(p3 * vec3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yzx+33.33);
    return fract((p3.xx+p3.yz)*p3.zy);
}

//----------------------------------------------------------------------------------------
//  3 out, 1 in...
vec3 hash31(float p)
{
   vec3 p3 = fract(vec3(p) * vec3(.1031, .1030, .0973));
   p3 += dot(p3, p3.yzx+33.33);
   return fract((p3.xxy+p3.yzz)*p3.zyx); 
}

//----------------------------------------------------------------------------------------
///  3 out, 2 in...
vec3 hash32(vec2 p)
{
    vec3 p3 = fract(vec3(p.xyx) * vec3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yxz+33.33);
    return fract((p3.xxy+p3.yzz)*p3.zyx);
}

//----------------------------------------------------------------------------------------
///  3 out, 3 in...
vec3 hash33(vec3 p3)
{
    p3 = fract(p3 * vec3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yxz+33.33);
    return fract((p3.xxy + p3.yxx)*p3.zyx);

}

//----------------------------------------------------------------------------------------
// 4 out, 1 in...
vec4 hash41(float p)
{
    vec4 p4 = fract(vec4(p) * vec4(.1031, .1030, .0973, .1099));
    p4 += dot(p4, p4.wzxy+33.33);
    return fract((p4.xxyz+p4.yzzw)*p4.zywx);
    
}

//----------------------------------------------------------------------------------------
// 4 out, 2 in...
vec4 hash42(vec2 p)
{
    vec4 p4 = fract(vec4(p.xyxy) * vec4(.1031, .1030, .0973, .1099));
    p4 += dot(p4, p4.wzxy+33.33);
    return fract((p4.xxyz+p4.yzzw)*p4.zywx);

}

//----------------------------------------------------------------------------------------
// 4 out, 3 in...
vec4 hash43(vec3 p)
{
    vec4 p4 = fract(vec4(p.xyzx)  * vec4(.1031, .1030, .0973, .1099));
    p4 += dot(p4, p4.wzxy+33.33);
    return fract((p4.xxyz+p4.yzzw)*p4.zywx);
}

//----------------------------------------------------------------------------------------
// 4 out, 4 in...
vec4 hash44(vec4 p4)
{
    p4 = fract(p4  * vec4(.1031, .1030, .0973, .1099));
    p4 += dot(p4, p4.wzxy+33.33);
    return fract((p4.xxyz+p4.yzzw)*p4.zywx);
}

#define R(p, a) p=cos(a)*p+sin(a)*vec2(p.y,-p.x)
vec3 rot(vec3 p,vec3 r){
    R(p.xz, r.y);
    R(p.yx, r.z);
    R(p.zy, r.x);
    return p;
}

vec3 ro = vec3(0), rd = vec3(0);
vec3 col = vec3(0);
float curve(float x){
    return x*x*(3.0-2.0*x);
}
vec4 sdScene(vec3 p)
{
    float d = MAX_DIST;
    vec4 res = vec4(MAX_DIST, MAT_VOID);

    vec3 cp001 = p;
    cp001.xyz += vec3(0., -1., 0.);
    
    // Bending...
    {
        vec3 q = cp001;
        float r = s2u(sin(time))*PI*.5; // rotation radian
        float range = .5+s2u(sin(time*.5)); // range of bending
        
        float sgn = sign(q.x);
        float smoothRange = sms(-sms(0., 1., p.z-.2), range, q.x*sgn) * sgn *.5;
        
        R(q.xz, r*smoothRange);
        cp001 = q;
    }
    
    d = sdCapsule(rot(cp001+vec3(0.3713, 0., 0.), vec3(0., 0., 1.5708)), 0.5900, 3.4100);
    d = fOpUnionSmooth(sdEllipsoid(rot(cp001+vec3(0.3713, 0., 0.), vec3(0., 0.6647, 0.)), vec3(0.5295, 1., 1.)), d, 0.1900);
    d = fOpUnionSmooth(sdEllipsoid(rot(cp001+vec3(-0.7288, 0., 0.), vec3(1.0374, 0.6176, 0.4935)), vec3(0.6807, 0.9020, 0.9020)), d, 0.1570);
    d = fOpUnionSmooth(sdEllipsoid(rot(cp001+vec3(1.3413, 0., 0.), vec3(0.8924, 0.5617, 0.2927)), vec3(0.6807, 0.9020, 0.9020)), d, 0.1900);
    d = fOpUnionSmooth(sdEllipsoid(rot(cp001+vec3(2.2848, 0., 0.), vec3(1.0186, 0.6089, 0.4699)), vec3(0.4136, 0.7825, 0.7825)), d, 0.1900);
    d = fOpUnionSmooth(sdEllipsoid(rot(cp001+vec3(-1.7662, 0., 0.), vec3(3.4214, 2.4668, 0.6159)), vec3(0.4972, 1.1038, 1.1038)), d, 0.1390);
    d = fOpUnionSmooth(sdEllipsoid(rot(cp001+vec3(3.1596, 0., 0.), vec3(0.5278, 0.5633, -0.3009)), vec3(0.6807, 1.0448, 1.0448)), d, 0.1900);
    d = fOpUnionSmooth(sdEllipsoid(rot(cp001+vec3(-2.5247, 0., 0.), vec3(0.6248, 0.5416, -0.1472)), vec3(0.6807, 0.9020, 0.9020)), d, 0.1900);
    res = v4OpUnion(vec4(d, MAT_ERNST0_001), res);

    d = sdPlane(p);
    res = v4OpUnion(vec4(d, MAT_ERNST0), res);

    d = sdCappedCylinder(rot(cp001+vec3(-3.3399, 0., 0.), vec3(0., 0., 1.5708)), vec2(0.4595, 0.4595))-0.0100;
    res = v4OpUnionSmooth(vec4(d, MAT_ERNST0_001), res, 0.0280);

    d = sdEllipsoid(cp001+vec3(-4.5001, 0., 0.), vec3(0.6139, 0.6139, 0.6139));
    res = v4OpUnion(vec4(d, MAT_ERNST0_002), res);

    return res;
}

vec4 intersect()
{
    float d = 1.;
    vec3  m = MAT_VOID;

    for (int i = 0; i < ITERATION; i++)
    {
        vec3 p = ro + d * rd;
        vec4 res = sdScene(p);
        m = res.yzw;
        res.x *= .5;
        if (abs(res.x) < MIN_DIST || res.x >= MAX_DIST) break;
        d += res.x;
        if (d >= MAX_DIST) break;
    }

    return vec4(d,m);
}

vec3 normal(vec3 p)
{
    float c=sdScene(p).x;
    float e=MIN_DIST*.1;
    return normalize(vec3(
        sdScene(p+vec3(e,0.,0.)).x-c,
        sdScene(p+vec3(0.,e,0.)).x-c,
        sdScene(p+vec3(0.,0.,e)).x-c)
    );
}

float shadow(vec3 o, vec3 n)
{
    float mint=L0_str;
    float maxt=L0_end;
    float k = L0_sft;
    float res = 1.;
    float t=mint;
    float ph = 1e10;
    for( int i=0; i < ITERATION; i++)
    {
        float h = sdScene(o + L0_dir*t).x;
#if 1
        res = min( res, k*h/t);
#else
        float y = h*h/(2.0*ph);
        float d = sqrt(h*h-y*y);
        res = min( res, k*d/max(0.0,t-y) );
        ph = h;
#endif
        t += h;

        if( res<0.0001 || t>maxt ) break;
    }
    return clamp( res, 0.0, 1.0 );
}

vec3 randomSphereDir(vec2 rnd)
{
    float s = rnd.x*PI*2.;
    float t = rnd.y*2.-1.;
    return vec3(sin(s), cos(s), t) / sqrt(1.0 + t * t);
}
vec3 randomHemisphereDir(vec3 dir, float i)
{
    vec3 v = randomSphereDir( vec2(hash11(i+1.), hash11(i+2.)) );
    return v * sign(dot(v, dir));
}

// "Hemispherical SDF AO" by XT95:
// https://www.shadertoy.com/view/4sdGWN
float ambientOcclusion( in vec3 p, in vec3 n, in float maxDist, in float falloff )
{
    const int nbIte = 12;
    const float nbIteInv = 1./float(nbIte);
    const float rad = 1.-1.*nbIteInv;

    float ao = 0.0;

    for( int i=0; i<nbIte; i++ )
    {
        float l = hash11(float(i))*maxDist;
        vec3 aord = normalize(n+randomHemisphereDir(n, l )*rad)*l;

        ao += (l - max(sdScene( p + aord ).x,0.)) / maxDist * falloff;
    }

    return clamp( 1.-ao*nbIteInv, 0., 1.);
}

float specular(vec3 p, vec3 n, vec3 ld)
{
    float power = 30.;
    vec3 to_eye = normalize(p - ro);
    vec3 reflect_light = normalize(reflect(ld, n));
    return pow(max(dot(to_eye, reflect_light), 0.), power);
}

void render()
{
    vec4 hit = intersect();
    vec3 p = ro + hit.x * rd;
    vec3 base_col = hit.yzw;

    if (hit.x>=MAX_DIST)
    {
        col=FOG_COL;
    }
    else
    {
        vec3 n = normal(p);
        vec3 offset = n * .00001;
        float light1 = saturate(dot(n, L0_dir));
        float light2 = saturate(dot(n, L1_dir));
        float shadow = shadow(p+offset, n);

        float ao=0.;
        ao = ambientOcclusion(p, n, .1, .5);
        ao += ambientOcclusion(p, n, .5, .5);
        ao += ambientOcclusion(p, n, 2., 2.);
        ao += ambientOcclusion(p, n, 4., 2.);
        ao = smoothstep(0., 4., ao);

        float shade = 0.;
        shade = light1;

        vec3 shadeLight1 = vec3(L0_col*light1);
        vec3 shadeLight2 = vec3(L1_col*light2);

        col = shadeLight1;
        col *= shadow;
        col+= shadeLight2*ao;
        col+= AMB_COL*ao*AMB_STRENGTH;
        col*= base_col;

        col = mix(col, col+L0_col, specular(p+offset, n, L0_dir)*shadow*1.);
        col = mix(col, FOG_COL, saturate(pow(distance(ro,p)/MAX_DIST+FOG_START, FOG_POW)));
    }
}

vec3 ACESFilm(vec3 x){
    float a = 2.51;
    float b = 0.03;
    float c = 2.43;
    float d = 0.59;
    float e = 0.14;
    return (x*(a*x+b))/(x*(c*x+d)+e);
}

void camera(vec2 uv)
{
    perspectiveCam(uv, ro, rd);
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    uv = (uv*2.-1.)*resolution.y/resolution.x;
    uv.x *= resolution.x / resolution.y;

    init();
    camera(uv);
    render();
    col = ACESFilm(col);
    col = pow(col, vec3(.9));

    glFragColor = vec4(col, 1);
}
