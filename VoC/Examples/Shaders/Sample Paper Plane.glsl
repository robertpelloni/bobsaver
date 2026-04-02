#version 420

// original https://www.shadertoy.com/view/slKGWW

uniform int frames;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define ZERO (min(frames,0))
#define MAX_FLOAT 1e6
#define MIN_FLOAT 1e-6
#define EPSILON 1e-4
#define UP vec3(0., 1., 0.)
#define rx(a) mat3(1.0, 0.0, 0.0, 0.0, cos(a),-sin(a), 0.0, sin(a), cos(a))
#define ry(a) mat3(cos(a), 0.0,-sin(a), 0.0, 1.0, 0.0, sin(a), 0.0, cos(a))
#define rz(a) mat3(cos(a),-sin(a), 0.0, sin(a), cos(a), 0.0, 0.0, 0.0, 1.0)
#define saturate(x) clamp(x, 0., 1.)

const float PI = acos(-1.);

struct Ray{vec3 o, dir;};
struct Sphere{vec3 o; float rad;};
struct Box{ vec3 o; vec3 size;};
struct PaperPlane{ Sphere boundingSphere; mat3 rotMat; };//TODO merge into single mat4

vec3 rayDirection(float fieldOfView, vec2 size) {
    vec2 xy = gl_FragCoord.xy - size / 2.0;
    float z = size.y / tan(radians(fieldOfView) / 2.0);
    return normalize(vec3(xy, -z));
}

mat3 viewMatrix(vec3 eye, vec3 center, vec3 up) {
    vec3 f = normalize(center - eye);
    vec3 s = normalize(cross(f, up));
    vec3 u = cross(s, f);
    return mat3(s, u, -f);
}

mat4 rotationMatrix(vec3 axis, float angle){
    // taken from http://www.neilmendoza.com/glsl-rotation-about-an-arbitrary-axis/
    angle = radians(angle);
    axis = normalize(axis);
    float s = sin(angle);
    float c = cos(angle);
    float oc = 1.0 - c;
    
    return mat4(oc * axis.x * axis.x + c,           oc * axis.x * axis.y - axis.z * s,  oc * axis.z * axis.x + axis.y * s,  0.0,
                oc * axis.x * axis.y + axis.z * s,  oc * axis.y * axis.y + c,           oc * axis.y * axis.z - axis.x * s,  0.0,
                oc * axis.z * axis.x - axis.y * s,  oc * axis.y * axis.z + axis.x * s,  oc * axis.z * axis.z + c,           0.0,
                0.0,                                0.0,                                0.0,                                1.0);
}

float sphere_hit(const in Sphere sphere, const in Ray inray) {
    vec3 oc = inray.o - sphere.o;
    float a = dot(inray.dir, inray.dir);
    float b = dot(oc, inray.dir);
    float c = dot(oc, oc) - sphere.rad*sphere.rad;
    float discriminant = b*b - a*c;
    if (discriminant > 0.) {
        return (-b - sqrt(discriminant))/a;
    }
    return -1.;
}

bool sphere_hit(const in Sphere sphere, const in Ray inray, out vec2 dst) {
    vec3 oc = inray.o - sphere.o;
    float a = dot(inray.dir, inray.dir);
    float b = dot(oc, inray.dir);
    float c = dot(oc, oc) - sphere.rad*sphere.rad;
    float discriminant = b*b - a*c;
    if (discriminant > 0.) {
        dst = (-b + vec2(-sqrt(discriminant), sqrt(discriminant)))/a;//(-b - sqrt(discriminant))/a;
        return true;
    }
    return false;
}

#define MIN x
#define MAX y
bool box_hit(const in Box inbox, in Ray inray){
    vec2 tx, ty, tz;
    vec3 maxbounds = inbox.o + vec3( inbox.size);
    vec3 minbounds = inbox.o + vec3(-inbox.size);
    tx = ((inray.dir.x >= 0.?vec2(minbounds.x, maxbounds.x):vec2(maxbounds.x, minbounds.x)) - inray.o.x) / inray.dir.x;
    ty = ((inray.dir.y >= 0.?vec2(minbounds.y, maxbounds.y):vec2(maxbounds.y, minbounds.y)) - inray.o.y) / inray.dir.y;
    if ((tx.MIN > ty.MAX) || (ty.MIN > tx.MAX))
        return false;
    tx = vec2(max(tx.MIN, ty.MIN), min(tx.MAX, ty.MAX));
    tz = ((inray.dir.z >= 0.?vec2(minbounds.z, maxbounds.z):vec2(maxbounds.z, minbounds.z)) - inray.o.z) / inray.dir.z;
    if ((tx.MIN > tz.MAX) || (tz.MIN > tx.MAX))
        return false;
    tx = vec2(max(tx.MIN, tz.MIN), min(tx.MAX, tz.MAX));
    
    if(tx.MIN >= 0.){
        return true;
    }
        
    return false;
}

bool box_hit(const in Box inbox, in Ray inray, out vec2 dst){
    vec2 tx, ty, tz;
    vec3 maxbounds = inbox.o + vec3( inbox.size);
    vec3 minbounds = inbox.o + vec3(-inbox.size);
    tx = ((inray.dir.x >= 0.?vec2(minbounds.x, maxbounds.x):vec2(maxbounds.x, minbounds.x)) - inray.o.x) / inray.dir.x;
    ty = ((inray.dir.y >= 0.?vec2(minbounds.y, maxbounds.y):vec2(maxbounds.y, minbounds.y)) - inray.o.y) / inray.dir.y;
    if ((tx.MIN > ty.MAX) || (ty.MIN > tx.MAX))
        return false;
    tx = vec2(max(tx.MIN, ty.MIN), min(tx.MAX, ty.MAX));
    tz = ((inray.dir.z >= 0.?vec2(minbounds.z, maxbounds.z):vec2(maxbounds.z, minbounds.z)) - inray.o.z) / inray.dir.z;
    if ((tx.MIN > tz.MAX) || (tz.MIN > tx.MAX))
        return false;
    tx = vec2(max(tx.MIN, tz.MIN), min(tx.MAX, tz.MAX));
    
    if(tx.MIN >= 0. || tx.MAX >= 0.){
        dst = vec2(tx.MIN, tx.MAX);
        return true;
    }
        
    return false;
}

float sdTorus(vec3 p, vec2 t)
{
    vec2 q = vec2(length(p.xz) - t.x,p.y);
    return length(q)-t.y;
}

float sdEllipsoid(vec3 p, vec3 r){
    float k0 = length(p/r);
    float k1 = length(p/(r*r));
    return k0*(k0-1.0)/k1;
}

float sdBox( vec3 p, vec3 b )
{
    vec3 q = abs(p) - b;
    return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

float sdRoundBox(vec3 p, vec3 b, float r){
    vec3 q = abs(p) - b;
    return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0) - r;
}

float sdPlane(vec3 p, vec3 n, float h ) {
    return dot(p,n) + h;
}

//const float CUTOFF_PLANES_THICKNESS = .05;
float plane(vec3 pos, vec3 nrm, float dist, float thickness){
    return max(-sdPlane(pos, nrm, -dist + thickness),
               -sdPlane(pos, nrm * -1., dist + thickness));
}

float sdCapsule(vec3 p, float h, float r)
{
  p.x -= clamp( p.x, 0.0, h );
  return length( p ) - r;
}

float sdCappedCylinder( vec3 p, float h, float r )
{
  vec2 d = abs(vec2(length(p.yz),p.x)) - vec2(h,r);
  return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

float smax(float a, float b, float k)
{
    return log(exp(k*a)+exp(k*b))/k;
}

//by iq

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

vec3 voronoi( in vec2 x )
{
    vec2 n = floor(x);
    vec2 f = fract(x);

    //----------------------------------
    // first pass: regular voronoi
    //----------------------------------
    vec2 mg, mr;

    float md = 8.0;
    for( int j=-1; j<=1; j++ )
    for( int i=-1; i<=1; i++ )
    {
        vec2 g = vec2(float(i),float(j));
        vec2 o = hash( n + g );
        #ifdef ANIMATE
        o = 0.5 + 0.5*sin( time + 6.2831*o );
        #endif    
        vec2 r = g + o - f;
        float d = dot(r,r);

        if( d<md )
        {
            md = d;
            mr = r;
            mg = g;
        }
    }

    //----------------------------------
    // second pass: distance to borders
    //----------------------------------
    md = 8.0;
    for( int j=-2; j<=2; j++ )
    for( int i=-2; i<=2; i++ )
    {
        vec2 g = mg + vec2(float(i),float(j));
        vec2 o = hash( n + g );
        #ifdef ANIMATE
        o = 0.5 + 0.5*sin( time + 6.2831*o );
        #endif    
        vec2 r = g + o - f;

        if( dot(mr-r,mr-r)>0.00001 )
        md = min( md, dot( 0.5*(mr+r), normalize(r-mr) ) );
    }

    return vec3( md, mr );
}

#define LIGHT_DIR normalize(vec3(1., 2., .3))

float paperplane(vec3 pos, PaperPlane paperPlane){
    pos -= paperPlane.boundingSphere.o + vec3(.2, .1, 0.);
    pos *= paperPlane.rotMat;
    pos.z = abs(pos.z);
    vec3 originalPos = pos;
    
    float res = MAX_FLOAT;
    {
        float base = plane(pos, vec3(-.17, .75, -1.5), -.13, .005);
        base = max(base, pos.y);
        base = max(base, sdPlane(pos, normalize(vec3(-1., 0., 0.)), -.75));
        res = min(base, res);
    }
    
    {
        float wings = plane(pos, vec3(0., 1., 0.), 0., .001);
        wings = max(wings, sdPlane(pos, normalize(vec3(1., 0., 2.)), -.35));
        wings = max(wings, sdPlane(pos, normalize(vec3(-1., 0., 0.)), -.75));
        wings = max(wings, sdPlane(pos, normalize(vec3(-1., 0., -9.)), .085));
        res = min(wings, res);
    }
    
    {
        float h = sdBox(pos + vec3(.3, 0., -.4), vec3(.2, .1, .01));
        h = max(h, pos.y);
        vec3 mpos = pos + vec3(.6, .15, -.4);
        float eng = sdCapsule(mpos, .5, .15 + .15 * pos.x * step(pos.x, 0.));
        h = max(h, -eng);
        float innerCyl = sdCappedCylinder(mpos, .1 + .05 * pos.x * step(pos.x, 0.), 1.);
        eng = max(eng, -innerCyl);
        res = min(res, eng);
        res = min(res, h);
        
        pos = pos + vec3(.05, .125, -.4);
        pos *= rx(time * 5.);
        vec2 pol = vec2(length(pos.zy), atan(pos.z, pos.y));
        pol.y = mod(pol.y, PI * .15);
        mpos.zy = pol.x * vec2(sin(pol.y), cos(pol.y));
        mpos.x -= .55;
        mpos *= 2.;
        
        float e = sdBox(mpos, vec3(.02, .2, .02));
        res = min(e, res);
        res = min(sdEllipsoid(originalPos + vec3(.3, .15, -.4), vec3(.35, .065, .065)), res);
    }
    
    return res;
}

float trail(vec3 pos, PaperPlane paperPlane){
    pos -= paperPlane.boundingSphere.o + vec3(.2, .1, 0.);
    pos *= paperPlane.rotMat;
    pos.z = abs(pos.z);
    
    vec3 mpos = pos + vec3(5.2, .15, -.4);
    float innerCyl = sdCappedCylinder(mpos, .1 - .05 * pos.x * step(pos.x, 0.), 5.);
    
    return innerCyl;
}

float marchTrail(in Ray r, PaperPlane paperPlane){
    float t = .01;
    for(int i = 0; i <= 64; i++){
        vec3 p = r.o + r.dir * t;
        float dst = trail(p, paperPlane);
        if(abs(dst) < .01)
            return t;
        t += dst;
    }
    return -1.;
}

vec3 normals(vec3 pos, PaperPlane paperPlane){
    vec2 eps = vec2(0.0, EPSILON);
    vec3 n = normalize(vec3(
        paperplane(pos + eps.yxx, paperPlane) - paperplane(pos - eps.yxx, paperPlane),
        paperplane(pos + eps.xyx, paperPlane) - paperplane(pos - eps.xyx, paperPlane),
        paperplane(pos + eps.xxy, paperPlane) - paperplane(pos - eps.xxy, paperPlane)));
    return n;
}

const int MAX_MARCHING_STEPS = 256;
float march(in Ray r, PaperPlane paperPlane, float minDst, float maxDst){
    float t = minDst;
    for(int i = 0; i <= MAX_MARCHING_STEPS; i++){
        vec3 p = r.o + r.dir * t;
        float dst = paperplane(p, paperPlane);
        if(dst < .0001)
            return t;
        t += dst * .5;
        if(t > maxDst)
            break;
    }
    return -1.;
}

vec4 getPaperPlane(PaperPlane pl, Ray r){
    vec2 dst = vec2(MAX_FLOAT);
    float planeHit = MAX_FLOAT;
    if(sphere_hit(pl.boundingSphere, r, dst)){
        planeHit = march(r, pl, dst[0], dst[1]);
        if(planeHit >= 0.){
            vec3 pos = r.o + r.dir * planeHit;
            return vec4(vec3(1.) * max(dot(normals(pos, pl), LIGHT_DIR), .1), planeHit);
        }else
            return vec4(MAX_FLOAT);
    }
    
    return vec4(planeHit);
}

// http://iquilezles.org/www/articles/rmshadows/rmshadows.htm
float calcSoftShadow(PaperPlane pl, Ray r, in float mint, in float tmax )
{
    // bounding volume
    float tp = (-r.o.y)/r.dir.y; if( tp>0.0 ) tmax = min( tmax, tp );

    float res = 1.0;
    float t = mint;
    for( int i=ZERO; i<32; i++ )
    {
        float h = paperplane(r.o + r.dir*t, pl);
        float s = clamp(8.0*h/t,0.0,1.0);
        res = min( res, s*s*(3.0-2.0*s) );
        t += clamp( h, 0.005, 0.025 );
        if( res<0.004 || t>tmax ) break;
    }
    return clamp( res, 0.0, 1.0 );
}

float shadow(PaperPlane pl, Ray r, float maxDst){
    //float e = .005;
    return step(maxDst, getPaperPlane(pl, r).w);
    
    //+ step(maxDst, getPaperPlane(pl, Ray(r.o, normalize(r.dir + vec3(0., 0., e)))).w)
    //+ step(maxDst, getPaperPlane(pl, Ray(r.o, normalize(r.dir + vec3(e, 0., 0.)))).w)
    //+ step(maxDst, getPaperPlane(pl, Ray(r.o, normalize(r.dir + vec3(0., 0., -e)))).w)
    //+ step(maxDst,getPaperPlane(pl, Ray(r.o, normalize(r.dir + vec3(-e, 0., 0.)))).w);
    //return n/5.;
}

float groundClr(vec2 pos){
    const vec2 size = vec2(.15, 0.);

    float s11 = smoothstep(.2, 0., voronoi(pos).x);
    float s01 = smoothstep(.2, 0., voronoi(pos + vec2(-.01, 0.)).x);
    float s21 = smoothstep(.2, 0., voronoi(pos + vec2(.01, 0.)).x);//noised(uv + off.zy).x + trail(groundPos.xz + vec2(-.4, 0.));
    float s10 = smoothstep(.2, 0., voronoi(pos + vec2(0., -.01)).x);//noised(uv + off.yx).x + trail(groundPos.xz + vec2(.0, .4));
    float s12 = smoothstep(.2, 0., voronoi(pos + vec2(0., .01)).x);//noised(uv + off.yz).x + trail(groundPos.xz + vec2(.0, -.4));
    vec3 va = normalize(vec3(size.xy, s21-s01));
    vec3 vb = normalize(vec3(size.yx, s12-s10));
    vec4 bump = vec4( cross(va,vb), s11 );
    vec3 nor =  bump.xzy;
    
    return dot(nor, LIGHT_DIR);
}

float time2;
const PaperPlane staticPlane = PaperPlane(Sphere(vec3(0.), 1.), mat3(1.));
void main(void)
{
    time2 = time * .5;
    vec3 lookAt = vec3(0.);
    //float a = mouse*resolution.xy.x/resolution.x * 5.;
    float a = noised(vec2(time2 + 317.) * .1).x * 10.;
    vec3 eye = vec3(12. * sin(a), 2., 12. * cos(a));
    vec3 viewDir = rayDirection(30., resolution.xy);
    vec3 worldDir = viewMatrix(eye, lookAt, vec3(0., 1., 0.)) * viewDir;

    Ray r = Ray(eye, worldDir);
    vec3 color = vec3(0.);
    
    PaperPlane pl = staticPlane;
    vec3 horNoise = noised(vec2(time2));
    vec3 vertNoise = noised(vec2(time2 * .5) + 1037.23);
    pl.boundingSphere.o.z += horNoise.x * 3.;
    pl.rotMat *= rx(-horNoise.y);
    pl.boundingSphere.o.y += vertNoise.x * 2.;
    pl.rotMat *= rz(-vertNoise.y * .25);
    
    vec4 planeHit = getPaperPlane(pl, r);
    if(planeHit.w < MAX_FLOAT){
        vec3 planePos = r.o + r.dir * planeHit.w;
        color = planeHit.rgb
              * max(calcSoftShadow(pl, Ray(planePos, LIGHT_DIR), EPSILON, 1.), .25);
    }
    
    float trail = marchTrail(r, pl);
    if(trail >= 0.){
        vec3 trailPos = r.o + r.dir * trail;
        vec3 pr = noised(trailPos.xy * vec2(15., 10.) + vec2(time2 * .2));
        r.dir = normalize(r.dir + vec3(pr.y, pr.z, 0.) * .01);
    }
    
    float hitFloor = (-1.5-r.o.y)/r.dir.y;
    if(hitFloor < planeHit.w){
        vec3 floorPos = r.o + r.dir * hitFloor;
        color = vec3(0.051,0.400,0.447)
              * max(shadow(pl, Ray(floorPos, LIGHT_DIR), MAX_FLOAT - MIN_FLOAT), .25);
              
        color = mix(vec3(0.898,0.804,0.604), color * groundClr((floorPos.xz + vec2(time * 20., 0.)) * .5), smoothstep(50., 15., distance(floorPos.xz, vec2(0., 0.))));
              
    }
    
    glFragColor =  vec4(color, 1.);
}
