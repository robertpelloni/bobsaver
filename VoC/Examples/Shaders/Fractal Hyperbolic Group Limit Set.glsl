#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/WdGBz3

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/* --------------------------------------------
  Limit set of rank 4 hyperbolic Coxeter groups

                                  by Zhao Liang

This program shows the limit set of rank 4 hyperbolic
Coxeter groups. (the brass metal points)

Let G be a hyperbolic Coxeter group and x a point inside
the hyperbolic ball, the set S = { gx, g \in G} has accumulation
points (under Euclidean metric) only on the boundary of the space.
We call the accumulation points of S the limit set of the group,
it can be proved that this set is independent of the way x is chosen,
and it's the smallest closed subset of the boundary that is invariant
under the action of the group.

In this animation these points are those colored in "brass metal".

As always, you can do whatever you want to this work.

Still a in-progress version, may undergo some change in later days.
------------------------------------------------
*/

// --------------------------
// some ryamarching settings

#define MAX_TRACE_STEPS  200
#define MIN_TRACE_DIST   0.1
#define MAX_TRACE_DIST   200.0
#define PRECISION        0.0001
#define MAXREFLECTIONS   16

// ---------------------------

#define AA  3
#define CHECKER1  vec3(0.82, 0.196078, 0.33)
#define CHECKER2  vec3(0.196078, 0.35, 0.92)
#define MATERIAL  vec3(0.71, 0.65, 0.26)
#define FUNDCOL   vec3(0., 0.82, .33)

/*-------------------------------
   Math stuff used in this shader

The Coxeter-Dynkin diagram of a rank 4 Coxeter group of
string type has the form

   A --- B --- C --- D
      p     q     r

Here A, B, D can be chosen as ususal Euclidean planes, C is a sphere
orthongonal to the unit ball. Taken from mla's notation.
*/

#define PI  3.141592653

#define MAX_REFLECTIONS 16

vec3 A, B, D;
vec4 C;
vec3 PQR;

// compute the normals of mirrors A, B, D and the sphere C
void initPQR()
{
    float P = PQR[0], Q = PQR[1], R = PQR[2];
    float cp = cos(PI / P), sp = sin(PI / P);
    float cq = cos(PI / Q);
    float cr = cos(PI / R);
    A = vec3(0,  0,   1);
    B = vec3(0, sp, -cp);
    D = vec3(1,  0,   0);
    
    float r = 1.0 / cr;
    float k = r * cq / sp;
     vec3 cen = vec3(1, k, 0);
    C = vec4(cen, r) / sqrt(dot(cen, cen) - r * r);
}

// minimal distance to the four mirrors
float distABCD(vec3 p)
{
    float dA = abs(dot(p, A));
    float dB = abs(dot(p, B));
    float dD = abs(dot(p, D));
    float dC = abs(length(p - C.xyz) - C.w);
    return min(dA, min(dB, min(dC, dD)));
}

// try to reflect across a plane with normal n and update the counter
bool try_reflect(inout vec3 p, vec3 n, inout int count)
{
    float k = dot(p, n);
    // if we are already inside, do nothing are return true
    if (k >= 0.0)
        return true;

    p -= 2.0 * k * n;
    count += 1;
    return false;
}

// similar with above, instead this is a sphere inversion
bool try_reflect(inout vec3 p, vec4 sphere, inout int count)
{
    vec3 cen = sphere.xyz;
    float r = sphere.w;
    vec3 q = p - cen;
    float d2 = dot(q, q);
    if (d2 == 0.0)
        return true;
    float k = (r * r) / d2;
    if (k < 1.0)
        return true;
    p = k * q + cen;
    count += 1;
    return false;
}

// sdf of the unit sphere at origin
float sdSphere(vec3 p, float radius) { return length(p) - 1.0; }

// sdf of the plane y=-1
float sdPlane(vec3 p, float offset) { return p.y + 1.0; }

// inverse stereo-graphic projection, from a point on plane y=-1 to
// the unit ball centered at the origin
vec3 planeToSphere(vec2 p)
{
    float pp = dot(p, p);
    return vec3(2.0 * p, pp - 1.0) / (1.0 + pp);
}

// iteratively reflect a point on the unit sphere into the fundamental cell
// and update the counter along the way
bool iterateSpherePoint(inout vec3 p, inout int count)
{
    bool inA, inB, inC, inD;
    for(int iter=0; iter<MAX_REFLECTIONS; iter++)
    {
        inA = try_reflect(p, A, count);
        inB = try_reflect(p, B, count);
        inC = try_reflect(p, C, count);
        inD = try_reflect(p, D, count);
        p =  normalize(p);  // avoid floating error accumulation
        if (inA && inB && inC && inD)
            return true;
    }
    return false;
}

vec3 chooseColor(bool found, int count)
{
    if (found)
    {
        if (count == 0) return FUNDCOL;
        return (count % 2 == 0) ? CHECKER1 : CHECKER2;
        
    }
    return MATERIAL;
}

vec2 rot2d(vec2 p, float a)
{
    float ca = cos(a), sa = sin(a);
    return vec2(p.x * ca - p.y * sa, p.x * sa + p.y * ca);
}

// --------------------------
// Coxeter group

#define P   3.
#define Q   3.
#define R   7.

/* ===========================
Our signed distance function here!

ball + plane

return vec2(distance, id)
==============================*/
vec2 map(vec3 p)
{
    float d1 = sdSphere(p, 1.0);
    float d2 = sdPlane(p, -1.0);
    float id = (d1 < d2) ? 0.: 1.;
    return vec2(min(d1, d2), id);
}

// standard scene normal
vec3 getNormal(vec3 p)
{
    const vec2 e = vec2(0.001, 0.);
    return normalize(vec3(
        map(p + e.xyy).x - map(p  - e.xyy).x,
        map(p + e.yxy).x - map(p  - e.yxy).x,
        map(p + e.yyx).x - map(p  - e.yyx).x));
}

// get the signed distance to an object and object id
vec2 raymarch(in vec3 ro, in vec3 rd)
{
    float t = MIN_TRACE_DIST;
    vec2 h;
    for(int i=0; i<MAX_TRACE_STEPS; i++)
    {
        h = map(ro + t * rd);
        if (h.x < PRECISION * t || t > MAX_TRACE_DIST)
            return vec2(t, h.y);
        t += h.x;
    }
    return vec2(-1.0);
}

// iq's sphere occlusion
// https://www.shadertoy.com/view/4djSDy
float calcOcclusion(in vec3 pos, in vec3 nor)
{
    vec4 sph = vec4(0., 0., 0., 1.);
    vec3  di = sph.xyz - pos;
    float l  = length(di);
    float nl = dot(nor, di/l);
    float h  = l/sph.w;
    float h2 = h*h;
    float k2 = 1.0 - h2*nl*nl;

    // above/below horizon: Quilez - http://iquilezles.org/www/articles/sphereao/sphereao.htm
    float res = max(0.0,nl)/h2;
    // intersecting horizon: Lagarde/de Rousiers - http://www.frostbite.com/wp-content/uploads/2014/11/course_notes_moving_frostbite_to_pbr.pdf
    if(k2 > 0.0) 
    {
        res = nl*acos(-nl*sqrt( (h2-1.0)/(1.0-nl*nl) )) - sqrt(k2*(h2-1.0));
        res = res/h2 + atan( sqrt(k2/(h2-1.0)));
        res /= PI;
    }

    return res;
}

float softShadow(vec3 ro, vec3 rd, float tmin, float tmax, float k) {
    float res = 1.0;
    float t = tmin;
    for (int i = 0; i < 12; i++) {
        float h = map(ro + rd * t).x;
        res = min(res, k * h / t);
        t += clamp(h, 0.01, 0.1);
        if (h < 0.004 || t > tmax)
            break;
    }
    return clamp(res, 0.0, 1.0);
}

vec3 getColor(vec3 ro, vec3 rd, vec3 pos, vec3 nor, vec3 lp, vec3 basecol)
{
    float ao = 1.0 - 1.5 * calcOcclusion(pos, nor);
    float sh = softShadow(ro, rd, 0.2, 8., 32.);
    vec3 ld = lp - pos;
    float lDist = max(length(ld), .001);
    ld /= lDist; 
    
    float atten = 1.5 / (1. + lDist * lDist * .03);
    float diff = max(dot(nor, ld), 0.) * sh;
    
    float spec = pow(max( dot( reflect(-ld, nor), -rd ), 0.0 ), 32.);
    float fres = clamp(1.0 + dot(rd, nor), 0.0, 1.0);
    
    vec3 col = basecol * (diff + vec3(1, .6, .3)*spec*4. + .5*ao + vec3(.8)*fres*fres*2.);
    col *= ao * atten * sh;
    return col;
}

mat3 sphMat(float theta, float phi)
{
    float cx = cos(theta);
    float cy = cos(phi);
    float sx = sin(theta);
    float sy = sin(phi);
    return mat3(cy, -sy * -sx, -sy * cx,
                0,   cx,  sx,
                sy,  cy * -sx, cy * cx);
}

void main(void)
{
    vec3 finalcol = vec3(0.);
    int count = 0;
    vec2 m = mouse*resolution.xy.xy / resolution.xy - 0.5;
    float rx = m.y * PI;
    float ry = -m.x * 2. * PI;
    mat3 mouRot = sphMat(rx, ry);

// ---------------------------------
// initialize the mirrors

    PQR = vec3(P, Q, R);
    initPQR();

// -------------------------------------
// view setttings

    vec3 camera = vec3(-3., 3.2, -3.);
    camera.xz = rot2d(camera.xz, time*0.3);
    vec3 lookat  = vec3(0.);
    vec3 up = vec3(0., 1., 0.);
    vec3 forward = normalize(lookat - camera);
    vec3 right = normalize(cross(forward, up));
    up = normalize(cross(right, forward));
    
// -------------------------------------
// light position
// z-component is negative means it's ahead of us

    vec3 lp = camera + vec3(0.5, 1.0, -0.3);

// -------------------------------------
// antialiasing loop

    for(int ii=0; ii<AA; ii++)
    {
        for(int jj=0; jj<AA; jj++)
        {
            vec2 o = vec2(float(ii), float(jj)) / float(AA);
            vec2 uv = (2. * gl_FragCoord.xy + o - resolution.xy) / resolution.y;
            vec3 rd = normalize(uv.x * right + uv.y * up + 2.0 * forward);
            
            // ---------------------------------
            // hit the scene and get distance, object id
            
            vec2 res = raymarch(camera, rd);
            float t = res.x;
            float id = res.y;
            vec3 pos = camera + t * rd;
            vec3 nor = getNormal(pos);

            bool found;
            float edist;
            vec3 col;
            // the sphere is hit
            if (id == 0.)
            {
                pos = pos * mouRot;
                nor = nor * mouRot;
                vec3 q = pos;
                found = iterateSpherePoint(q, count);
                edist = distABCD(q);
                vec3 basecol = chooseColor(found, count);
                col = getColor(camera, rd, pos, nor, lp, basecol);
            }
            
            else if (id == 1.)
            {
                vec3 q = planeToSphere(pos.xz);
                q = q * mouRot;
                found = iterateSpherePoint(q, count);
                edist = distABCD(q);
                vec3 basecol = chooseColor(found, count);
                col = getColor(camera, rd, pos, nor, lp, basecol) * .9;
            }
            col = mix(col, vec3(0.), (1.0 - smoothstep(0., 0.005, edist))*0.85);
            finalcol += col;
        }
    }
    finalcol /= (float(AA) * float(AA));

// ------------------------------------
// a little post-processing

    finalcol = mix(finalcol, 1. - exp(-finalcol), .35);
    glFragColor = vec4(sqrt(max(finalcol, 0.0)), 1.0);

}
