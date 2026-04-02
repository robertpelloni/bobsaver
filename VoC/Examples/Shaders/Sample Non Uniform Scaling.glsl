#version 420

// original https://neort.io/art/bruv6rs3p9ffuj8oi3fg

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;
uniform sampler2D backbuffer;

out vec4 glFragColor;

// ------------------------------------------------------------------------------------
// Original "thinking..." created by kaneta : https://www.shadertoy.com/view/wslSRr
// Original Character By MikkaBouzu : https://twitter.com/mikkabouzu777
// ------------------------------------------------------------------------------------

#define saturate(x) clamp(x, 0.0, 1.0)
#define MAX_MARCH 200
#define MAX_DIST 1000.

#define M_PI 3.1415926
#define M_PI2 M_PI*2.0

#define M_PI03 1.04719
#define M_PI06 2.09439

const float EPS = 1e-3;
const float EPS_N = 1e-4;
const float OFFSET = EPS * 10.0;

struct surface {
    float dist;
    vec3 albedo;
    vec3 emission;
    float roughness;
    float metalness;
    int count;
    bool isTransparent;
    float refractPower;
    bool isHit;
};

// Surface Data Define
#define SURF_NOHIT(d)   (surface(d, vec3(0,1,1),          vec3(0), 0.0, 0.0, 0, false, 0.0, false))
#define SURF_BLACK(d)     (surface(d, vec3(0.),        vec3(0), 0.3, 0.0, 0, false, 0.0, true))
#define SURF_FACE(d)     (surface(d, vec3(1,0.7,0.6), vec3(0), 0.3, 0.0, 0, false, 0.0, true))
#define SURF_MOUSE(d)     (surface(d, vec3(1,0,0.1),   vec3(0), 0.3, 0.0, 0, false, 0.0, true))
#define SURF_CHEEP(d)     (surface(d, vec3(1,0.3,0.4), vec3(0), 0.3, 0.0, 0, false, 0.0, true))
surface SURF_BG1(float d, vec3 pos)
{
    vec3 index = floor(pos * 10. + 0.5);
    vec3 col = vec3(0.25) + vec3(0.75) * mod(mod(index.x + index.y, 2.0) + index.z + index.y, 2.0);
    return surface(d, col, vec3(0), 0.5, 0.3, 0, false, 0., true);
}
#define SURF_CS(d)         (surface(d, vec3(0.9), vec3(0,0,0), 0.1, 0.8, 0, false, 0., true))

#define SURF_SPHERE(d)     (surface(d, vec3(0), vec3(0), 0.1, 0.8, 0, false, 2.2, true))
#define SURF_CUBE(d)     (surface(d, vec3(0,1,0), vec3(0), 0.5, 0.0, 0, false, 2.2, true))
#define SURF_SPHERE2(d) (surface(d, vec3(0,0,1), vec3(0), 0.1, 0.2, 0, false, 2.2, true))

vec3 sinebow(float h) {
    vec3 r = sin((.5-h)*M_PI + vec3(0,M_PI03,M_PI06));
    return r*r;
}

float rand(vec2 st)
{
    return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 10000.0);
}

float rand3d(vec3 st)
{
    return fract(sin(dot(st.xyz, vec3(12.9898, 78.233, 56.787))) * 10000.0);
}

float noise(vec3 st)
{
    vec3 ip = floor(st);
    vec3 fp = smoothstep(vec3(0.), vec3(1.), fract(st));
    
    vec4 a = vec4(rand3d(ip+vec3(0.)),rand3d(ip+vec3(1.,0.,0.)),rand3d(ip+vec3(0.,1.,0.)),rand3d(ip+vec3(1.,1.,0.)));
    vec4 b = vec4(rand3d(ip+vec3(0.,0.,1.)),rand3d(ip+vec3(1.,0.,1.)),rand3d(ip+vec3(0.,1.,1.)),rand3d(ip+vec3(1.,1.,1.)));
    
    a = mix(a, b, fp.z);
    a.xy = mix(a.xy, a.zw, fp.y);
    
    return mix(a.x, a.y, fp.x);
}

vec2 hash( in vec2 x )  // replace this by something better
{
    const vec2 k = vec2( 0.3183099, 0.3678794 );
    x = x*k + k.yx;
    return -1.0 + 2.0*fract( 16.0 * k*fract( x.x*x.y*(x.x+x.y)) );
}

// return gradient noise (in x) and its derivatives (in yz)
vec3 noised( in vec2 p )
{
    vec2 i = floor( p );
    vec2 f = fract( p );

#if 1
    // quintic interpolation
    vec2 u = f*f*f*(f*(f*6.0-15.0)+10.0);
    vec2 du = 30.0*f*f*(f*(f-2.0)+1.0);
#else
    // cubic interpolation
    vec2 u = f*f*(3.0-2.0*f);
    vec2 du = 6.0*f*(1.0-f);
#endif    
    
    vec2 ga = hash( i + vec2(0.0,0.0) );
    vec2 gb = hash( i + vec2(1.0,0.0) );
    vec2 gc = hash( i + vec2(0.0,1.0) );
    vec2 gd = hash( i + vec2(1.0,1.0) );
    
    float va = dot( ga, f - vec2(0.0,0.0) );
    float vb = dot( gb, f - vec2(1.0,0.0) );
    float vc = dot( gc, f - vec2(0.0,1.0) );
    float vd = dot( gd, f - vec2(1.0,1.0) );

    return vec3( va + u.x*(vb-va) + u.y*(vc-va) + u.x*u.y*(va-vb-vc+vd),   // value
                 ga + u.x*(gb-ga) + u.y*(gc-ga) + u.x*u.y*(ga-gb-gc+gd) +  // derivatives
                 du * (u.yx*(va-vb-vc+vd) + vec2(vb,vc) - va));
}

// Hash without Sine by Dave_Hoskins
// https://www.shadertoy.com/view/4djSRW
//----------------------------------------------------------------------------------------
//  1 out, 3 in...
float hash13(vec3 p3)
{
    p3  = fract(p3 * .1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

///  2 out, 2 in...
vec2 hash22(vec2 p)
{
    vec3 p3 = fract(vec3(p.xyx) * vec3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yzx+33.33);
    return fract((p3.xx+p3.yz)*p3.zy);

}

//  3 out, 1 in...
vec3 hash31(float p)
{
   vec3 p3 = fract(vec3(p) * vec3(.1031, .1030, .0973));
   p3 += dot(p3, p3.yzx+33.33);
   return fract((p3.xxy+p3.yzz)*p3.zyx); 
}

///  3 out, 3 in...
vec3 hash33(vec3 p3)
{
    p3 = fract(p3 * vec3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yxz+33.33);
    return fract((p3.xxy + p3.yxx)*p3.zyx);

}
// Distance functions by iq
// https://iquilezles.org/www/articles/distfunctions/distfunctions.htm

float sdSphere(in vec3 p, float s) {
    return length(p) - s;
}

float sdRoundBox(vec3 p, vec3 size, float r)
{
    return length(max(abs(p) - size * 0.5, 0.0)) - r;
}

float sdBox( vec3 p, vec3 b ) {
    vec3 d = abs(p) - b;
    return min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0));
}

float sdCapsule(vec3 p, vec3 a, vec3 b, float r)
{
    vec3 pa = p - a, ba = b - a;
    float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    return length(pa - ba*h) - r;
}

float sdEllipsoid( vec3 p, vec3 r )
{
    float k0 = length(p/r);
    float k1 = length(p/(r*r));
    return k0*(k0-1.0)/k1;
}

float sdCappedTorus(in vec3 p, in vec2 sc, in float ra, in float rb)
{
  p.x = abs(p.x);
  float k = (sc.y*p.x>sc.x*p.y) ? dot(p.xy,sc) : length(p.xy);
  return sqrt( dot(p,p) + ra*ra - 2.0*ra*k ) - rb;
}

float sdRoundedCylinder( vec3 p, float ra, float rb, float h )
{
  vec2 d = vec2( length(p.xz)-2.0*ra+rb, abs(p.y) - h );
  return min(max(d.x,d.y),0.0) + length(max(d,0.0)) - rb;
}

float sdPlane( vec3 p, vec4 n )
{
  // n must be normalized
  return dot(p,n.xyz) + n.w;
}

float dot2( in vec2 v ) { return dot(v,v); }
float dot2( in vec3 v ) { return dot(v,v); }
float ndot( in vec2 a, in vec2 b ) { return a.x*b.x - a.y*b.y; }

float sdCappedCone( vec3 p, float h, float r1, float r2 )
{
  vec2 q = vec2( length(p.xz), p.y );
  vec2 k1 = vec2(r2,h);
  vec2 k2 = vec2(r2-r1,2.0*h);
  vec2 ca = vec2(q.x-min(q.x,(q.y<0.0)?r1:r2), abs(q.y)-h);
  vec2 cb = q - k1 + k2*clamp( dot(k1-q,k2)/dot2(k2), 0.0, 1.0 );
  float s = (cb.x<0.0 && ca.y<0.0) ? -1.0 : 1.0;
  return s*sqrt( min(dot2(ca),dot2(cb)) );
}

float sdTorus( vec3 p, vec2 t )
{
  vec2 q = vec2(length(p.xz)-t.x,p.y);
  return length(q)-t.y;
}

// Distance Function 2D
float sdSegment( in vec2 p, in vec2 a, in vec2 b )
{
    vec2 pa = p-a, ba = b-a;
    float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
    return length( pa - ba*h );
}

// Union, Subtraction, SmoothUnion (distance, Material) 
surface opU(surface d1, surface d2)
{
    //return (d1.dist < d2.dist) ? d1 : d2;
    if(d1.dist < d2.dist){
        return d1;
    } else {
        return d2;
    }
}

surface opS( surface d1, surface d2 )
{ 
    //return (-d1.dist > d2.dist) ? vec2(-d1.x, d1.y): d2;
    //return (-d1.dist > d2.dist) ? surface(-d1.dist, d1.albedo, d1.emission, d1.roughness, d1.metalness) : d2;
    if(-d1.dist > d2.dist){
        d1.dist = -d1.dist;
        return d1;
    } else {
        return d2;
    }
}

surface opSU( surface d1, surface d2, float k ) {
    float h = clamp( 0.5 + 0.5*(d2.dist - d1.dist)/k, 0.0, 1.0 );
    float d = mix( d2.dist, d1.dist, h ) - k*h*(1.0-h);
    vec3 albedo = mix( d2.albedo, d1.albedo, h );
    vec3 emission = mix( d2.emission, d1.emission, h );
    float roughness = mix( d2.roughness, d1.roughness, h );
    float metalness = mix( d2.metalness, d1.metalness, h );
    float refractPower = mix( d2.refractPower, d1.refractPower, h );
    return surface(d, albedo, emission, roughness, metalness, d1.count, h > 0.5 ? d1.isTransparent : d2.isTransparent, refractPower, true);
}

surface opI( surface d1, surface d2 )
{ 
    //return (d1.dist > d2.dist) ? d1 : d2;]
    if(d1.dist > d2.dist) {
        return d1;
    }else{
        return d2;
    }
}

surface opPaint(surface d1, surface d2)
{
    //return (d1.dist < d2.dist) ? d1 : surface(d1.dist, d2.albedo, d2.emission, d2.roughness, d2.metalness);
    if(d1.dist < d2.dist) {
        return d1;
    } else {
        d2.dist = d1.dist;
        return d2;
    }
}
             
// Union, Subtraction, SmoothUnion (distance only)
float opUnion( float d1, float d2 ) {  return min(d1,d2); }

float opSubtraction( float d1, float d2 ) { return max(-d1,d2); }

float opIntersection( float d1, float d2 ) { return max(d1,d2); }

float opSmoothUnion( float d1, float d2, float k ) {
    float h = clamp( 0.5 + 0.5*(d2-d1)/k, 0.0, 1.0 );
    return mix( d2, d1, h ) - k*h*(1.0-h); }

vec3 rotate(vec3 p, float angle, vec3 axis)
{
    vec3 a = normalize(axis);
    float s = sin(angle);
    float c = cos(angle);
    float r = 1.0 - c;
    mat3 m = mat3(
        a.x * a.x * r + c,
        a.y * a.x * r + a.z * s,
        a.z * a.x * r - a.y * s,
        a.x * a.y * r - a.z * s,
        a.y * a.y * r + c,
        a.z * a.y * r + a.x * s,
        a.x * a.z * r + a.y * s,
        a.y * a.z * r - a.x * s,
        a.z * a.z * r + c
    );
    return m * p;
}

mat2 rot( float th ){ vec2 a = sin(vec2(1.5707963, 0) + th); return mat2(a, -a.y, a.x); }

vec2 foldRotate(in vec2 p, in float s) {
    float a = M_PI / s - atan(p.x, p.y);
    float n = M_PI2 / s;
    a = floor(a / n) * n;
    p *= rot(a);
    return p;
}

vec3 opTwist(in vec3 p, float k )
{
    float c = cos(k*p.y);
    float s = sin(k*p.y);
    mat2  m = mat2(c,-s,s,c);
    vec3  q = vec3(m*p.xz,p.y);
    return vec3(q.x, q.y, q.z);
}

vec3 TwistY(vec3 p, float power)
{
    float s = sin(power * p.y);
    float c = cos(power * p.y);
    mat3 m = mat3(
          c, 0.0,  -s,
        0.0, 1.0, 0.0,
          s, 0.0,   c
    );
    return m*p;
}

vec3 opRep( in vec3 p, in vec3 c)
{
    return mod(p+0.5*c,c)-0.5*c;
}

vec2 opRep2D( in vec2 p, in vec2 c)
{
    return mod(p+0.5*c,c)-0.5*c;
}

// 線分と無限平面の衝突位置算出
// rayPos : レイの開始地点
// rayDir : レイの向き
// planePos : 平面の座標
// planeNormal : 平面の法線
float GetIntersectLength(vec3 rayPos, vec3 rayDir, vec3 planePos, vec3 planeNormal)
{
    return dot(planePos - rayPos, planeNormal) / dot(rayDir, planeNormal);
}

// 直方体とレイの衝突位置算出
vec2 GetIntersectBox(vec3 rayPos, vec3 rayDir, vec3 boxPos, vec3 boxSize)
{
    vec3 diff = rayPos - boxPos;
    vec3 m = 1.0 / rayDir;
    vec3 n = m * diff;
    vec3 k = abs(m) * boxSize;
    vec3 t1 = -n - k;
    vec3 t2 = -n + k;
    
    float tN = max(max(t1.x, t1.y), t1.z);
    float tF = min(min(t2.x, t2.y), t2.z);
    
    return vec2(tN, tF);
/*    
    if(tN > tF || tF < 0.0)
        return vec2(-1.0);    // no intersection
    
    return vec2(tN, tF);
*/
}

/////////////////////////////////////////////////////////////////////////////////////////////////
// easing function
/////////////////////////////////////////////////////////////////////////////////////////////////
float ease_cubic_out(float p)
{
    float f = (p - 1.0);
    return f * f * f + 1.0;
}

float easeInCirc(float x)
{
    return 1. - sqrt(1. - pow(x, 2.));
}

float easeOutCirc(float x) 
{
    return sqrt(1. - pow(x - 1., 2.));
}

float easeInExpo(float x)
{
    return x == 0. ? 0. : pow(2., 10. * x - 10.);
}

/////////////////////////////////////////////////////////////////////////////////////////////////
// Mikka Boze Distance Function
/////////////////////////////////////////////////////////////////////////////////////////////////
#define RAD90 (M_PI * 0.5)

float sdEar(vec3 p)
{
    p = rotate(p, RAD90+0.25, vec3(0,0,1));    
    return sdCappedTorus(p + vec3(0.05, 0.175, 0), vec2(sin(0.7),cos(0.7)), 0.03, 0.01);
}

#define EYE_SPACE 0.04

vec3 opBendXY(vec3 p, float k)
{
    float c = cos(k*p.x);
    float s = sin(k*p.x);
    mat2  m = mat2(c,-s,s,c);
    return vec3(m*p.xy,p.z);
}

vec3 opBendXZ(vec3 p, float k)
{
    float c = cos(k*p.x);
    float s = sin(k*p.x);
    mat2  m = mat2(c,-s,s,c);
    vec2 xz = m*p.xz;
    return vec3(xz.x, p.y, xz.y);
}

float sdMouse(vec3 p, float ms)
{
    vec3 q = opBendXY(p, 2.0);
    ms += 0.00001;
    //return sdEllipsoid(q - vec3(0,0,0.2) * sc, vec3(0.05,0.015 + sin(time * 1.) * 0.05,0.05) * sc);
    return sdEllipsoid(q - vec3(0,0,0.2), vec3(0.035, 0.01 * ms,0.2 * ms));
}

float sdCheep(vec3 p)
{    
    const float x = 0.05;
    const float z = -0.175;
    const float r = 0.0045;
    const float rb1 = 100.;
    
    p = rotate(p, M_PI * -0.6 * (p.x - x), vec3(-0.2,0.8,0));
    
    float d = sdCapsule(opBendXY(p + vec3(x, -0.01, z), rb1), vec3(-0.005,0.0,0.0), vec3(0.005, 0., 0.001), r);
    float d1 = sdCapsule(opBendXY(p + vec3(x+0.01, -0.01, z), 200.0), vec3(-0.0026,0.0,0), vec3(0.0026, 0., 0), r);
    float d2 = sdCapsule(opBendXY(p + vec3(x+0.019, -0.015, z), -rb1), vec3(-0.01,0.0,-0.01), vec3(0.0045, 0., 0.0), r);
    
    return opUnion(opUnion(d, d1), d2);
}

float sdEyeBrow(vec3 p)
{
    const float x = 0.05;
    p = opBendXZ(p + vec3(0.02,0,-0.02), -6.5);
    //p = rotate(p, M_PI * -0.0225, vec3(0,0,1));
    //p = opBendXZ(p + vec3(0.03, 0, 0) * sc, 0.1);
    //p = opBendXZ(p + vec3(0.015, 0, 0.1) * sc, 2.5 * sc);
    //p = rotate(p, M_PI * -0.6 * (p.x - x) / sc, vec3(-0.2,0.8,0));
    return sdRoundBox(p + vec3(0.005, -0.14,-0.11), vec3(0.003,0.0025,0.05), 0.001);
}

surface sdBoze(vec3 p, vec3 sc, float ms)
{    
    surface result = SURF_NOHIT(0.);
    
    //float sl = sc.x * sc.y * sc.z;
    //float sl = 1.;
    float minsc = min(sc.x, min(sc.y, sc.z));
    //vec3 sc2 = 1.0/sc;
    //float dist = someSDF(samplePoint / vec3(s_x, s_y, s_z)) * min(s_x, min(s_y, s_z));
    p /= sc;
    
    // head
    float d = sdCapsule(p, vec3(0,0.05,0), vec3(0, 0.11, 0), 0.125);
    
    float d1 = sdRoundedCylinder(p + vec3(0,0.025,0), 0.095, 0.05, 0.0);
    
    d = opSmoothUnion(d, d1, 0.1);
    
    vec3 mxp = vec3(-abs(p.x), p.yz);
    
    // ear
    float d2 = sdEar(mxp);
    d = opUnion(d, d2);

    surface head = SURF_FACE(d);

    // eye
    float d4 = sdCapsule(mxp, vec3(-EYE_SPACE, 0.06, 0.13), vec3(-EYE_SPACE, 0.08, 0.125), 0.0175);
    surface eye = SURF_BLACK(d4);
    
    // mouse
    float d6 = sdMouse(p, ms);
    surface mouse = SURF_MOUSE(d6);
    
    // cheep
    float d7 = sdCheep(mxp);
    surface cheep = SURF_CHEEP(d7);
    
    // eyebrows
    float d9 = sdEyeBrow(mxp);
    eye.dist = opUnion(eye.dist, d9);
    
    // integration
    mouse = opU(eye, mouse);
    result = opS(mouse, head);
    //result = opU(mouse, head);
    result = opU(cheep, result);
    
    result.dist *= minsc;
    
    return result;
}

surface sdCapsuleBoze(vec3 p, vec3 a, vec3 b, vec3 sc, float ms)
{
    vec3 pa = p - a, ba = b - a;
    float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    return sdBoze(pa - ba*h, sc, ms);
}

surface sdUFBoze(vec3 p, vec3 sc, float ms)
{
    float sl = length(sc);
    surface cone = SURF_CS(sdCappedCone(p + vec3(0, 0.08 * sl, 0), 0.06 * sl, 0.5 * sl, 0.25 * sl));
    return opU(sdBoze(p, sc, ms), cone);
}

surface sdCapsuleUFBoze(vec3 p, vec3 a, vec3 b, vec3 sc, float ms)
{
    vec3 pa = p - a, ba = b - a;
    float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    return sdUFBoze(pa - ba*h, sc, ms);
    //vec3 q = rotate(pa - ba*h, h * M_PI2, normalize(ba));
    //return sdUFBoze(q, sc, ms);
}

/////////////////////////////////////////////////////////////////////////////////////////////////
// End of Mikka Boze
/////////////////////////////////////////////////////////////////////////////////////////////////

surface map(vec3 p)
{
    surface result = SURF_NOHIT(MAX_DIST);
    //p = rotate(p, M_PI, vec3(0,1,0));

    vec3 index = floor(p + 0.5);
    float h = hash13(index);
    float t = time * (0.75 + h * 0.25) * M_PI2;
    
    vec3 q = opRep(p, vec3(1., 100., 1.));
    q = rotate(q, h * M_PI2, vec3(0,1,0));
    
    //float sc = mix(0.5, 1., abs(sin(t)*0.9)+0.1);
    float tp = h * M_PI + t;
    float sc = abs(sin(tp));
    float scxz = sc * 0.75 + 0.25;
    
    //float sc = 1.;
    //result = SURF_SPHERE(sdSphere(p - vec3(0,0.125,0), 0.2));
    //result = sdBoze(p, vec3(1., 1., 0.75), sin(t*3.)*0.5 + 0.5);
    result = sdBoze(q + vec3(0, abs(cos(tp))*-0.2+0.15, 0), vec3(scxz, 1.1-easeInExpo(sc)*0.9, scxz), 1.);
    //result = sdBoze(p, vec3(1., 2., 1.), sin(t*3.)*0.5 + 0.5);
    
    //vec3 sc = hash33(index) *0 .5+ 0.5;
    //vec3 sc = noised(index.xy * 512. + index.y * 333. + t * 0.25) * 0.4 + 0.6;
    //result = sdBoze(q, sc, sin(t*3.)*0.5 + 0.5);
    
        
    //result = opU(boze1, boze2);
    //result = boze2;
    //result = opU(opU(boze1, boze2), boze3);
    //result = sdBoze(p, 1., sin(t*3.)*0.5 + 0.5);
    //result = opSU(sdBoze(p + vec3(cos(t)*-0.05-0.05,0.05,0), 1., cos(t * 3.8)*0.5+0.5), result, 0.01);
    //result = opU(result, SURF_CUBE(sdRoundBox(p - vec3(0.5,0.125,0), vec3(0.25), 0.01)));
    
    //result = opU(result, SURF_SPHERE2(sdSphere(p - vec3(-0.5,0.125,0), 0.2)));
    
    // background
    surface bg1 = SURF_BG1(sdPlane(p + vec3(0., 0.15, 0.), vec4(0,1,0,0)), p);
    //surface bg1 = SURF_BG1(sdBox(p + vec3(0., 1.15, 0.), vec3(0.75,1.0,0.75)), p);
    result = opU(result, bg1);
    /*
    vec3 index = floor(p * 2. + 0.5);
    float rnd = hash13(vec3(index.x,0,index.z));
    vec3 rnd3 = hash33(vec3(index.x,0,index.z));
    
    //vec3 q = opRep(p, vec3(0.5, 5., 0.5));
    q = TwistY(q, 2.*M_PI2);
    q = rotate(q, t+rnd*M_PI2, vec3(0,1,0));
    q += vec3(0.02,0,0.02);
    float w = 0.025;
    //vec3 col = vec3(0.25) + vec3(0.75) * mod(mod(index.x + index.y, 2.0) + index.z + index.y, 2.0);
    vec3 col = sinebow(rnd + time * 3.5) * saturate(noise(rnd3 + vec3(time * 10.5,0,0))*2.5-1.);
    surface bg2 = surface(sdRoundBox(q, vec3(w,5.,w), 0.01), vec3(0), saturate((sin(q.y * 100.-t*2.)*10.0-5.))*col, 0.1, 0.8, 0);
    
    result = opU(result, opSU(bg1, bg2, 0.1));
    */
    
    return result;
}

#if 0
vec3 norm(vec3 p)
{
    vec2 e=vec2(.00001,.0);
    return normalize(.000001+map(p).x-vec3(map(p-e.xyy).x,map(p-e.yxy).x,map(p-e.yyx).x));
}
#else

vec3 norm(in vec3 position) {
    vec3 epsilon = vec3(0.001, 0.0, 0.0);
    vec3 n = vec3(
          map(position + epsilon.xyy).dist - map(position - epsilon.xyy).dist,
          map(position + epsilon.yxy).dist - map(position - epsilon.yxy).dist,
          map(position + epsilon.yyx).dist - map(position - epsilon.yyx).dist);
    return normalize(n);
}
#endif

float shadow(in vec3 origin, in vec3 direction) {
    float hit = 1.0;
    float t = 0.02;
    
    for (int i = 0; i < MAX_MARCH; i++) {
        float h = map(origin + direction * t).dist;
        if (h < EPS) return 0.0;
        t += h;
        hit = min(hit, 10.0 * h / t);
        if (t >= 2.5) break;
    }

    return clamp(hit, 0.0, 1.0);
}

surface traceRay(in vec3 origin, in vec3 direction) {
    float t = 0.0;
    
    vec3 pos = origin;

    int count = 0;
    surface hit;
    float d;
    for (int i = 0; i < MAX_MARCH; i++) {
        hit = map(pos);
        d = abs(hit.dist);
        
        if (d <= EPS || d >= MAX_DIST) {
            break;
        }
        
        // grid overshoot check
        vec2 iBox = GetIntersectBox(pos, direction, floor(pos + 0.5), vec3(0.5));
        if(iBox.x < iBox.y && iBox.y > 0.0 && iBox.y < d) {
            d = iBox.y + EPS; 
        }
        
        t += d;
        pos = origin + direction * t;

        count++;        
    }

    if(d <= EPS){
        return surface(t, hit.albedo, hit.emission, hit.roughness, hit.metalness, count, hit.isTransparent, hit.refractPower, true);
    }else{
        return surface(t, vec3(0), hit.emission, hit.roughness, hit.metalness, count, hit.isTransparent, hit.refractPower, false);
    }
}

// ---------------------------------------------------
// Starfield01 by xaot88
// https://www.shadertoy.com/view/Md2SR3
// ---------------------------------------------------
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

// Return random noise in the range [0.0, 1.0], as a function of x.
float Noise2d( in vec2 x )
{
    float xhash = cos( x.x * 37.0 );
    float yhash = cos( x.y * 57.0 );
    return fract( 415.92653 * ( xhash + yhash ) );
}

// Convert Noise2d() into a "star field" by stomping everthing below fThreshhold to zero.
float NoisyStarField( in vec2 vSamplePos, float fThreshhold )
{
    float StarVal = Noise2d( vSamplePos );
    if ( StarVal >= fThreshhold )
        StarVal = pow( (StarVal - fThreshhold)/(1.0 - fThreshhold), 6.0 );
    else
        StarVal = 0.0;
    return StarVal;
}

// Stabilize NoisyStarField() by only sampling at integer values.
float StableStarField( in vec2 vSamplePos, float fThreshhold )
{
    // Linear interpolation between four samples.
    // Note: This approach has some visual artifacts.
    // There must be a better way to "anti alias" the star field.
    float fractX = fract( vSamplePos.x );
    float fractY = fract( vSamplePos.y );
    vec2 floorSample = floor( vSamplePos );    
    float v1 = NoisyStarField( floorSample, fThreshhold );
    float v2 = NoisyStarField( floorSample + vec2( 0.0, 1.0 ), fThreshhold );
    float v3 = NoisyStarField( floorSample + vec2( 1.0, 0.0 ), fThreshhold );
    float v4 = NoisyStarField( floorSample + vec2( 1.0, 1.0 ), fThreshhold );

    float StarVal =   v1 * ( 1.0 - fractX ) * ( 1.0 - fractY )
                    + v2 * ( 1.0 - fractX ) * fractY
                    + v3 * fractX * ( 1.0 - fractY )
                    + v4 * fractX * fractY;
    return StarVal;
}

vec2 getPoint(vec2 id, vec2 offset)
{
    return sin(hash22(id + offset) * time * 1.5 + hash22(id + offset)) * 0.4 + offset;
}

vec3 SkyColor( vec3 rd )
{
#if 0
    // Cube Map
    // hide cracks in cube map
    rd -= sign(abs(rd.xyz)-abs(rd.yzx))*.01;

    //return mix( vec3(.2,.6,1), FogColour, abs(rd.y) );
    vec3 ldr = texture( iChannel0, rd ).rgb;
    
    // fake hdr
    vec3 hdr = 1.0/(1.2-ldr) - 1.0/1.2;
    
    return hdr;
#else
    // Black
    //return vec3(0,0,0);
    
    // test 1 UV
    //return rd * 0.5 + 0.5;
    
    // test 2 Grid
    //vec2 uv = vec2(atan(rd.z/rd.x), atan(length(rd.xz)/rd.y)) / M_PI;
    //uv += vec2(10.);
    //uv = abs(uv);
    /*
    // plexus
    vec2 suv = uv * 50.;
    
    vec2 id = floor(suv) - 0.5;
    vec2 fuv = fract(suv) - 0.5;
    vec2 pp =  getPoint(id, vec2(0));
    vec3 col = vec3(0);
    
    for(int x = -1; x <= 1; x++){
        for(int y = -1; y <= 1; y++){
            vec2 pos = getPoint(id, vec2(x,y)); //sin(hash22(id + vec2(x,y)) * time * 1.5) * 0.4 + vec2(x,y);
            float d = 1.0 / pow(length(fuv - pos), 1.75) * 0.001;
            col += d;

            float len = smoothstep(1.0,0.5,length(pp - pos));
            col += smoothstep(0.025,0.001,sdSegment(fuv, pos, pp)) * len;
        }
    }
    
    return col * sinebow(uv.x);
    */
    
    // fake unity default sky-box
    vec3 ground = mix(vec3(0.25,0.4,0.8), vec3(0.2,0.15,0.15), saturate(abs(rd.y) * 25.0));
    vec3 sky = mix(vec3(0.25,0.4,0.8), vec3(0.001, 0.15, 1.), saturate(abs(rd.y) * 10.0));
    return rd.y < 0. ? ground :sky;
    
    /*
    // Starfield
    float x = atan(rd.z / rd.x);
    float y = acos(rd.y);
    return vec3(StableStarField(vec2(x,y) * 1000., 0.97 ));
    */
#endif
}

//------------------------------------------------------------------------------
// BRDF
//------------------------------------------------------------------------------

float pow5(float x) {
    float x2 = x * x;
    return x2 * x2 * x;
}

float D_GGX(float linearRoughness, float NoH, const vec3 h) {
    // Walter et al. 2007, "Microfacet Models for Refraction through Rough Surfaces"
    float oneMinusNoHSquared = 1.0 - NoH * NoH;
    float a = NoH * linearRoughness;
    float k = linearRoughness / (oneMinusNoHSquared + a * a);
    float d = k * k * (1.0 / M_PI);
    return d;
}

float V_SmithGGXCorrelated(float linearRoughness, float NoV, float NoL) {
    // Heitz 2014, "Understanding the Masking-Shadowing Function in Microfacet-Based BRDFs"
    float a2 = linearRoughness * linearRoughness;
    float GGXV = NoL * sqrt((NoV - a2 * NoV) * NoV + a2);
    float GGXL = NoV * sqrt((NoL - a2 * NoL) * NoL + a2);
    return 0.5 / (GGXV + GGXL);
}

vec3 F_Schlick(const vec3 f0, float VoH) {
    // Schlick 1994, "An Inexpensive BRDF Model for Physically-Based Rendering"
    return f0 + (vec3(1.0) - f0) * pow5(1.0 - VoH);
}

float F_Schlick(float f0, float f90, float VoH) {
    return f0 + (f90 - f0) * pow5(1.0 - VoH);
}

float Fd_Burley(float linearRoughness, float NoV, float NoL, float LoH) {
    // Burley 2012, "Physically-Based Shading at Disney"
    float f90 = 0.5 + 2.0 * linearRoughness * LoH * LoH;
    float lightScatter = F_Schlick(1.0, f90, NoL);
    float viewScatter  = F_Schlick(1.0, f90, NoV);
    return lightScatter * viewScatter * (1.0 / M_PI);
}

float Fd_Lambert() {
    return 1.0 / M_PI;
}

//------------------------------------------------------------------------------
// Indirect lighting
//------------------------------------------------------------------------------

vec3 Irradiance_SphericalHarmonics(const vec3 n) {
    // Irradiance from "Ditch River" IBL (http://www.hdrlabs.com/sibl/archive.html)
    return max(
          vec3( 0.754554516862612,  0.748542953903366,  0.790921515418539)
        + vec3(-0.083856548007422,  0.092533500963210,  0.322764661032516) * (n.y)
        + vec3( 0.308152705331738,  0.366796330467391,  0.466698181299906) * (n.z)
        + vec3(-0.188884931542396, -0.277402551592231, -0.377844212327557) * (n.x)
        , 0.0);
}

vec2 PrefilteredDFG_Karis(float roughness, float NoV) {
    // Karis 2014, "Physically Based Material on Mobile"
    const vec4 c0 = vec4(-1.0, -0.0275, -0.572,  0.022);
    const vec4 c1 = vec4( 1.0,  0.0425,  1.040, -0.040);

    vec4 r = roughness * c0 + c1;
    float a004 = min(r.x * r.x, exp2(-9.28 * NoV)) * r.x + r.y;

    return vec2(-1.04, 1.04) * a004 + r.zw;
}

vec3 calcAmb(vec3 pos, vec3 rayDir, vec3 normal, vec3 lightPos, vec3 lightColor, surface surf) {
    vec3 color = vec3(0);
    vec3 lightDir = normalize(lightPos);
    vec3 viewDir = normalize(-rayDir);
    vec3 halfV = normalize(viewDir + lightDir);
    //vec3 r = normalize(reflect(rayDir, normal));
    
    float NoV = abs(dot(normal, viewDir)) + 1e-5;
    float NoL = saturate(dot(normal, lightDir));
    float NoH = saturate(dot(normal, halfV));
    float LoH = saturate(dot(lightDir, halfV));
    
    float indirectIntensity = 0.64;
    
    vec3 albedo = surf.albedo;
    float roughness = surf.roughness;
    float metallic = surf.metalness;
    float linearRoughness = roughness * roughness;
    vec3 diffuseColor = (1.0 - metallic) * albedo.rgb;
    vec3 f0 = 0.04 * (1.0 - metallic) + albedo.rgb * metallic;
    
    float attenuation = shadow(pos, lightDir);
    
    // specular BRDF
    float D = D_GGX(linearRoughness, NoH, halfV);
    float V = V_SmithGGXCorrelated(linearRoughness, NoV, NoL);
    vec3  F = F_Schlick(f0, LoH);
    vec3 Fr = (D * V) * F;

    // diffuse BRDF
    vec3 Fd = diffuseColor * Fd_Burley(linearRoughness, NoV, NoL, LoH);
    color = Fd + Fr;
    color *= (attenuation * NoL) * lightColor;
    
     // diffuse indirect
    vec3 indirectDiffuse = Irradiance_SphericalHarmonics(normal) * Fd_Lambert();
    
    vec3 ibl = diffuseColor * indirectDiffuse;
    
    color += ibl * indirectIntensity;
    color += surf.emission;
    
    return color;
}

//------------------------------------------------------------------------------
// Tone mapping and transfer functions
//------------------------------------------------------------------------------

vec3 Tonemap_ACES(const vec3 x) {
    // Narkowicz 2015, "ACES Filmic Tone Mapping Curve"
    const float a = 2.51;
    const float b = 0.03;
    const float c = 2.43;
    const float d = 0.59;
    const float e = 0.14;
    return (x * (a * x + b)) / (x * (c * x + d) + e);
}

vec3 OECF_sRGBFast(const vec3 linear) {
    return pow(linear, vec3(1.0 / 2.2));
}

///////////////
vec3 fresnelSchlick_roughness(vec3 F0, float cosTheta, float roughness) {
    return F0 + (max(vec3(1.0 - roughness), F0) - F0) * pow(1.0 - cosTheta, 5.0);
}

// Unreal Engine Ambient BRDF Approx
// https://www.unrealengine.com/en-US/blog/physically-based-shading-on-mobile?lang=en-US
vec3 EnvBRDFApprox( vec3 SpecularColor, float Roughness, float NoV )
{
    const vec4 c0 = vec4( -1, -0.0275, -0.572, 0.022 );
    const vec4 c1 = vec4( 1, 0.0425, 1.04, -0.04 );
    vec4 r = Roughness * c0 + c1;
    float a004 = min( r.x * r.x, exp2( -9.28 * NoV ) ) * r.x + r.y;
    vec2 AB = vec2( -1.04, 1.04 ) * a004 + r.zw;
    return SpecularColor * AB.x + AB.y;
}

vec3 calcAmbient(vec3 pos, vec3 albedo, float metalness, float roughness, vec3 N, vec3 V, float t)
{
    vec3 F0 = mix(vec3(0.04), albedo, metalness);
    vec3 F  = fresnelSchlick_roughness(F0, max(0.0, dot(N, V)), roughness);
    vec3 kd = mix(vec3(1.0) - F, vec3(0.0), metalness);
    
    float aoRange = t/20.0;
    float occlusion = max( 0.0, 1.0 - map( pos + N*aoRange ).dist/aoRange );
    occlusion = min(exp2( -.8 * pow(occlusion, 2.0) ), 1.0);
    
    vec3 ambientColor = vec3(0.5);
    
    vec3 diffuseAmbient = kd * albedo * ambientColor * min(1.0, 0.75+0.5*N.y) * 3.0;
    vec3 R = reflect(-V, N);
    
    vec3 col = mix(vec3(0.5) * pow( 1.0-max(-R.y,0.0), 4.0), ambientColor, pow(roughness, 0.5));
    vec3 ref = EnvBRDFApprox(F0, roughness, max(dot(N, V), 0.0));
    vec3 specularAmbient = col * ref;

    diffuseAmbient *= occlusion;
    return vec3(diffuseAmbient + specularAmbient);
}

vec3 materialize(vec3 ro, vec3 p, vec3 ray, surface mat, vec2 uv)
{
    vec3 col = vec3(0,1,0);
    vec3 sky = SkyColor(ray);
    
    //float t = time * 1.0 + M_PI * 1.5;
    //float r = 2.0;
    vec3 lightPos = vec3(-0.6, 0.8, -0.5);
    vec3 lightColor = vec3(0.98, 0.92, 0.89) * 3.0;

    if (mat.dist >= MAX_DIST) {
        col = sky;
    } else {
        vec3 result = vec3(0.);
        vec3 nor = norm(p);
        vec3 sky = SkyColor(ray);
        
        col = calcAmb(p, ray, nor, lightPos, lightColor, mat);
        col = mix(col, sky, 1.0 - saturate(exp2(100.0 - mat.dist * mat.dist)));
        float metalness = mat.metalness;
        
        if(mat.isHit){
            // reflection
            for(int i = 0; i < 1; i++)
            {
                vec3 nor = norm(p);
                bool isIncoming = dot(ray, nor) < 0.0;
                vec3 orientingNormal = isIncoming ? nor : -nor;
                bool isTotalReflection = false;

                if(mat.isTransparent){
                    // refract
                      //float nnt = isIncoming ? 1.0 / mat.refractPower : mat.refractPower;
                    //float nnt = 1.0 / mat.refractPower;
                    float nnt = isIncoming ? 1.0 / mat.refractPower : 1.0;
                    ray = refract(ray, orientingNormal, nnt);
                    p = p - orientingNormal * OFFSET;
                    isTotalReflection = (length(ray) <= 0.9);
                }

                if(isTotalReflection || !mat.isTransparent)
                {
                    // reflect
                    ray = reflect(ray, orientingNormal);
                    p = p + orientingNormal * OFFSET;
                }

                surface indirectHit = traceRay(p, ray);

                p = p + indirectHit.dist * ray;
                //float reflength = length(indirectPosition - p);
                //p = indirectPosition;
                mat = indirectHit;

                result = calcAmb(p, ray, nor, lightPos, lightColor, mat);

                vec3 sky = SkyColor(ray);
                
                // Exponential distance fog
                result = mix(result, sky, 1.0 - saturate(exp2(100.0 - indirectHit.dist * indirectHit.dist)));

                col += result * metalness;
                //col += result;
                metalness *= mat.metalness;
                if(!mat.isHit || metalness < 0.0001)
                    break;

            }
        }
    }
    
    // Glow
    //col += (sinebow(time * 10.) +vec3(0.1))* pow((mat.z + 10.) / float(MAX_MARCH), 3.5); 
    
    // Tone mapping
    col = Tonemap_ACES(col);

    // Gamma compression
    col = OECF_sRGBFast(col);
    return col;
}

vec3 render(vec3 p, vec3 ray, vec2 uv)
{
    vec3 pos;
    surface mat = traceRay(p, ray);
    
    pos = p + mat.dist * ray;
    return materialize(p, pos, ray, mat, uv);
}

mat3 camera(vec3 ro, vec3 ta, float cr )
{
    vec3 cw = normalize(ta - ro);
    vec3 cp = vec3(sin(cr), cos(cr),0.);
    vec3 cu = normalize( cross(cw,cp) );
    vec3 cv = normalize( cross(cu,cw) );
    return mat3( cu, cv, cw );
}

void main(void) {
    vec2 p = (gl_FragCoord.xy * 2.0 - resolution.xy) / min(resolution.x, resolution.y);
    
    float t = time * M_PI2 * -0.05;
    //float t = 0.;
    //float y = sin(t * 2.5) * 0.125-0.0;
    float y = sin(t * 2.5) * 0.3 + 0.5;
    //float y = 2.0;
    //float r = 2. + sin(t * 0.5)*0.5;
    float r = 1.5;
    float theta = t + RAD90 + RAD90*0.25;
    //float theta = RAD90 + RAD90*0.25;
    //float theta = t + RAD90;
    //vec3 ro = vec3( 0., 0.05, -0.75 );
    vec3 ro = vec3(cos(theta) * r, y, -sin(theta) * r);
    vec3 ta = vec3(0., 0.075, 0.);
    
    mat3 c = camera(ro, ta, 0.0);
    vec3 ray = c * normalize(vec3(p, 3.5));
    vec3 col = render(ro, ray, gl_FragCoord.xy);
    
    glFragColor = vec4(col,1.0);
}
