#version 420

// original https://www.shadertoy.com/view/DdS3DR

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*
    Is this the most optimzed code? Quite the opposite! This is mostly a 
    learning experience.
*/

// DEFINES -------------------------------------------------------------------//

// Ray marching-related
#define MAX_STEPS 1000
#define MAX_DIST 1e3
#define MIN_DIST 5e-3

// Optical-effect related
#define N_REFLS 2
#define SHADW_SHARPN 50
#define MIN_LIGHT .0125

// Other shader quantities
#define PERIOD 10.
#define BCKG_COL vec3(.3+.15*cos(p.x/1000.-time/PERIOD))

// Misc
#define PI 3.141593
#define TP 2.*PI
#define OFFSET (10.*MIN_DIST)
#define VECX vec3(1.,0.,0.)
#define VECY vec3(0.,1.,0.)
#define VECZ vec3(0.,0.,1.)

// MISC ----------------------------------------------------------------------//

mat3 rx(float t)
{
    float ct = cos(t);
    float st = sin(t);
    return mat3(1., 0., 0., 0., ct, -st, 0., st, ct);
}
mat3 ry(float t)
{
    float ct = cos(t);
    float st = sin(t);
    return mat3(ct, 0., st, 0., 1., 0., -st, 0., ct);
}
mat3 rz(float t)
{
    float ct = cos(t);
    float st = sin(t);
    return mat3(ct, -st, 0., st, ct, 0., 0., 0., 1);
}
vec3 lattice(vec3 p, vec3 c)
{
    return mod(p+0.5*c, c)-0.5*c;
}

// PRIMITIVE SIGNED DISTANCE FUNCTIONS (SDFs) AND OPERATIONS -----------------//

float SDFSphere(vec3 p, float r)
{
    return length(p)-r;
}

float SDFBox(vec3 p, vec3 b)
{
    vec3 q = abs(p) - b;
    return length(max(q, 0.)) + min(max(q.x, max(q.y,q.z)),0.);
}

float SDFInfColY(vec3 p, vec2 b)
{
    vec2 q = abs(p.xz) - b;
    return length(max(q, 0.)) + min(max(q.x, q.y),0.);
}

float DIntersect(float d0, float d1)
{
    return max(d0, d1);
}

float DSmoothIntersect(float d0, float d1, float k)
{
    return .5*(d0+d1+sqrt((d0-d1)*(d0-d1)+k));
}

float DUnite(float d0, float d1)
{
    return min(d0, d1);
}

float DSmoothUnite(float d0, float d1, float k)
{
    float h = clamp( 0.5 + 0.5*(d1-d0)/k, 0.0, 1.0 );
    return mix(d1, d0, h ) - k*h*(1.0-h);
}

float DSubtract(float d0, float d1)
{
    return max(d0, -d1);
}

float DSmoothSubtract(float d0, float d1, float k)
{
    return .5*(d0-d1+sqrt((d0+d1)*(d0+d1)+k));
}

// SURFACE -------------------------------------------------------------------//

struct Surface
{
    float d; // Distance from cast ray origin
    vec3 c; // Surface color
    float r; // Surface reflectance
};

Surface SIntersect(Surface s0, Surface s1)
{
    Surface s;
    if (abs(s0.d) < abs(s1.d))
        s = s0;
    else
        s = s1;
    s.d = max(s0.d, s1.d);
    return s;
}

Surface SSmoothIntersect(Surface s0, Surface s1, float k)
{
    float d = DSmoothIntersect(s0.d, s1.d, k);
    float h = d/s0.d;
    vec3 c = s1.c*(1.-h) + s0.c*h;
    float r = mix(s1.r, s0.r, h);
    return Surface(d, c, r);
}

Surface SUnite(Surface s0, Surface s1)
{
    if (s0.d < s1.d)
        return s0;
    return s1;
}

Surface SSmoothUnite(Surface s0, Surface s1, float k)
{
    float h = clamp(.5 + .5*(s1.d-s0.d)/k, 0.0, 1.0 );
    float d = mix(s1.d, s0.d, h ) - k*h*(1.0-h);
    vec3 c = s1.c*(1.-h) + s0.c*h;
    float r = mix(s1.r, s0.r, h);
    return Surface(d, c, r);
}

Surface SSubtract(Surface s0, Surface s1)
{
    return Surface(max(s0.d, -s1.d), s0.c, s0.r);
}

Surface SSmoothSubtract(Surface s0, Surface s1, float k)
{
    Surface s = s0;
    s.d = DSmoothSubtract(s0.d, s1.d, k);
    return s;
}

// GLOBAL SCENE SDF ----------------------------------------------------------//

Surface sceneSDF(vec3 p)
{
    float t = TP*time/PERIOD;
    p = rx(t+.5*p.x)*(p);
    p.y = abs(p.y)-5.-1.*sin(t);
    float h = 10.+6.*sin(t/4.);
    vec3 pb = lattice(p-h*fract(t)*VECX, h*VECX);//*ry(p.y*sin(t));
    Surface s1 = Surface(SDFInfColY(pb, vec2(.5)), VECX, 0.25);
    s1.d -= .25;
    s1.d -= 2.*sin( .5*p.y - t)*(.5+.5*sin(t/4.));
    Surface s2 = Surface(SDFSphere(p+VECY*(2.), 4.), vec3(1.,.5,0.), .75);
    s2.d -= .25*sin(5.*p.x+25.*t);
    Surface pl = Surface(p.y+2., vec3(.6,.3,.15), 0.25);
    pl.d += .1*sin(p.x*10.+20.*t)+.1*sin(p.z*5.-20.*t);
    s1 = SSmoothUnite(s1, s2, 4.+2.*sin(2.*t));
    float x = .5;//1.+.9*sin(t/2.);
    s1.d -= x;
    pl = SSmoothSubtract(pl, s1, 0.5);
    s1.d += x;
    s1 = SUnite(s1, pl);
    float m = sin(t)*sin(.5*p.y-5.*t)+cos(t)*sin(0.25*p.x-.5*t);
    s1.d = DSmoothIntersect(
        s1.d, 
        SDFBox(p-vec3(0.,0.,0), vec3(MAX_DIST, 6., 3.+2.*m)),
        0.125
    );
    s1.d /= 7.5;
    return s1;
}

// RAY MARCHING RELATED ------------------------------------------------------//

struct Ray 
{
    vec3 orig; // Ray origin
    vec3 dir; // Ray direction
    float af; // Attenuation factor
    int n; // Number of bounces
};

Ray newRay(vec3 orig, vec3 dir)
{
    return Ray(orig, dir, 1., 0);
}

Ray cameraRay(vec2 uv, vec3 cp, vec3 la, float zoom)
{
    vec3 f = normalize(la-cp);
    vec3 r = normalize(cross(vec3(0.,1.,0.),f));
    vec3 u = normalize(cross(f, r));
    vec3 c = cp + f*zoom;
    return newRay(cp, normalize(c + uv.x * r + uv.y * u-cp));
}

Surface rayMarch(Ray ray, out float pn)
{
    Surface s;
    float d, dd, dd0 = MIN_DIST;
    pn = 1.;
    for (int iter = 0; iter < MAX_STEPS; iter++)
    {
        dd0 = dd; // I am not using dd0 for anything, I know...
        s = sceneSDF(ray.orig + ray.dir*d);
        dd = s.d;
        if (dd > 0. && dd <= MIN_DIST || d >= MAX_DIST)
            break;
        pn = min(pn, float(SHADW_SHARPN)*dd/d);
        d += dd;
    }
    s.d = d;
    return s;
}

Surface rayMarch(Ray ray) // Overload without penumbra inout
{
    float tmp;
    return rayMarch(ray, tmp);
}

vec3 getNormal(vec3 p)
{
    float d = sceneSDF(p).d;
    vec2 e = vec2(OFFSET, 0.);
    vec3 n = d - vec3
        (
            sceneSDF(p-e.xyy).d,
            sceneSDF(p-e.yxy).d,
            sceneSDF(p-e.yyx).d
        );
    return normalize(n);
}

float getLighting(vec3 p, inout vec3 n)
{
    // Light source position
    vec3 lp = vec3(-.5, 0, -40.);
    n = getNormal(p);
    p += n*OFFSET;
    vec3 dir = normalize(lp-p);
    float pn;
    if (rayMarch(newRay(p, dir), pn).d < length(lp-p))
        return MIN_LIGHT;
    return max(abs(dot(n, dir)*pn), MIN_LIGHT);
}

void propagate(inout Ray ray, inout vec3 col)
{
    // If the ray is fully attenuated, stop propagating
    if (ray.af == 0.)
        return;
    Surface s = rayMarch(ray);
    vec3 p = ray.orig + ray.dir*s.d;
    //ray.af *= exp(s.d);
    vec3 lCol, n;
    lCol = BCKG_COL;
    if (s.d < MAX_DIST)
        lCol = max(getLighting(p, n), 0.)*s.c;
    // If at the last reflection, set reflectance of hit surface to 0
    // so it is rendered as fully opaque
    s.r *= float(ray.n<N_REFLS);
    // Cumulate col
    col += lCol*ray.af*(1.0-s.r);
    // Adjust attenuation by currently hit surface and prepare for next
    // propagation
    ray.af *= s.r;
    if (ray.af != 0.)
    {
        ray.orig = p+n*OFFSET;
        ray.dir = reflect(ray.dir, n);
    }
    ray.n++;
}

vec3 render(Ray r)
{
    // Base pass
    vec3 col = vec3(0.);
    propagate(r, col);
    // Reflection passes
    for (int i = 0; i < N_REFLS; i++)
    {
        propagate(r, col);
    }
    col = pow(col, vec3(.4545));
    return col;
}

// MAIN ----------------------------------------------------------------------//

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
    // Camera position, look-at point and resulting ray
    float t = TP*time/PERIOD;
    vec3 cp = vec3(-25.*sin(t/2.), 1., -25.);
    vec3 la = vec3(0., 0., 0.);
    Ray ray = cameraRay(uv, cp, la, 1.);
    // Render pixel
    glFragColor = vec4(render(ray),1.);
}
