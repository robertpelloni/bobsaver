#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/tlBSzz

uniform int frames;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

///////////////////////////////////////////////////////////////////////////////////
// Raymarching an SDF, with a cute emoji for fun :) /////////////////////// peet //
///////////////////////////////////////////////////////////////////////////////////
// This is can exceed compilation time limits with many options enabled ///////////
// Setting both MSAA to 2.0 improves compilation time at expense for FPS //////////
// Remove STUFF2/SIDEWALLS/MRSPOO also if you're having problems viewing //////////
///////////////////////////////////////////////////////////////////////////////////
// Snippets of code taken from others, mostly SDF from IQ /////////////////////////
///////////////////////////////////////////////////////////////////////////////////

#define MARCH_ITERATIONS 30        

#define REFLECT_ITERATIONS 3    
#define MSAA_X 2.0                // Both set to 2.0 improves compilation time!
#define MSAA_Y 1.0                // Runs much faster at 1.0, but may not compile

///////////////////////////////////////////////////////////////////////////////////

#define TOO_FAR 100000000.0
#define NOT_CLOSE 4.0
#define EPSILON 0.0001
#define PI 3.14159

///////////////////////////////////////////////////////////////////////////////////

struct AnimObj
{
    vec3 pos;
    vec3 scale;
    vec3 rot;
    vec3 centre;
    float radius;
};

struct Material {
    vec3 colour;
    float diffuse;
    float specular;
};
    
struct Ray {
    vec3 pos;
    vec3 dir;
};

struct Sphere {
    vec3 pos;
    float radius;
    int matindex;
};

struct Torus {
    vec3 pos;
    float ring;
    float radius;
    int matindex;
};
        
struct Light {
    vec3 pos;
    vec3 colour;
};

struct Plane {
    vec3 pos;
    vec3 norm;
    int matindex;
};

struct RoundBox {
    vec3 pos;
    vec3 dimensions;
    float radius;
    int matindex;
};

struct VertCap {
    vec3 pos;
    float height;
    float radius;
    int matindex;
};
        
struct Result {
    vec3 pos;
    vec3 normal;
    float t;
    float mint;
    float travelled;
    Material mat;
};
    
struct SDFResult
{
    float dist;
    int matindex;
};

///////////////////////////////////////////////////////////////////////////////////
    
mat3 rotationmatrix(vec3 a)
{
    float cp=cos(a.x);
    float sp=sin(a.x);
    float cy=cos(a.y);
    float sy=sin(a.y);
    float cr=cos(a.z);
    float sr=sin(a.z);
    mat3 pitch = mat3(1, 0, 0, 0, cp, sp, 0, -sp, cp);
    mat3 yaw = mat3(cy, 0, -sy, 0, 1, 0, sy, 0, cy);
    mat3 roll = mat3(cr, sr, 0, -sr, cr, 0, 0, 0, 1);
    mat3 rotation = pitch*yaw*roll;    
    return rotation;
}

///////////////////////////////////////////////////////////////////////////////////
// SDF's & other spatial query functions

SDFResult opAdd( SDFResult r1, SDFResult r2 ) 
{
    return SDFResult((r1.dist<r2.dist)?r1.dist:r2.dist, (r1.dist<r2.dist)?r1.matindex:r2.matindex);
}

SDFResult opSmoothAdd( SDFResult r1, SDFResult r2, float k ) 
{
    float h = clamp( 0.5 + 0.5*(r2.dist-r1.dist)/k, 0.0, 1.0 );
    SDFResult res;
    res.dist = (mix( r2.dist, r1.dist, h ) - k*h*(1.0-h));
    res.matindex = ((r2.dist>r1.dist)?r1.matindex:r2.matindex);
    return res; 
}

SDFResult opSmoothSub( SDFResult r1, SDFResult r2, float k ) 
{
    float h = clamp( 0.5 - 0.5*(r2.dist+r1.dist)/k, 0.0, 1.0 );
    SDFResult res;
    res.dist = (mix( r2.dist, -r1.dist, h ) + k*h*(1.0-h));
    res.matindex = ((r2.dist>r1.dist)?r1.matindex:r2.matindex);
    return res; 
}

SDFResult sphereSDF(Sphere sphere, vec3 p) 
{
    vec3 diff = (sphere.pos - p);
    diff.y *= 0.65;
    return SDFResult(length(diff) - sphere.radius, sphere.matindex);
}

SDFResult sphereSDF2(Sphere sphere, vec3 p) 
{
    vec3 delta = sphere.pos - p;
    delta.xz += delta.y*delta.y*delta.y*10.0;
    return SDFResult(length(delta) - sphere.radius, sphere.matindex);
}

SDFResult torusSDF( Torus torus, vec3 p )
{
    p -= torus.pos;
    
    vec2 q = vec2(length(p.xz)-torus.ring,p.y);
    return SDFResult(length(q)-torus.radius, torus.matindex);
}

SDFResult torusSDF2( Torus torus, vec3 p )
{
    p -= torus.pos;
    
    const float scale = 0.05;
    float topdiff = clamp((0.1 - p.y), 0.0, scale);
    float botdiff = clamp((p.y - ((p.x*p.x*2.0)-scale)), 0.0, scale);
    
    if ( topdiff>0.0 && botdiff>0.0 )
    {
        float v = min(topdiff, botdiff)/scale;
        v = 3.0*v*v - 2.0*v*v*v;
        p.z-=v*scale*0.5;
    }
    
    vec2 q = vec2(length(p.xz)-torus.ring,p.y);
    return SDFResult(length(q)-torus.radius, torus.matindex);
}

SDFResult planeSDF( Plane plane, vec3 p )
{
    return SDFResult(dot(plane.norm, p) - dot(plane.pos, plane.norm), plane.matindex);
}

SDFResult roundboxSDF( RoundBox box, vec3 p )
{
    p -= box.pos;
    vec3 d = abs(p) - box.dimensions;
    SDFResult res;
    res.dist = length(max(d,0.0)) - box.radius + min(max(d.x,max(d.y,d.z)),0.0);
    res.matindex = box.matindex;
    return res;
}

SDFResult vertcapSDF( VertCap cap, vec3 p )
{
    p -= cap.pos;
    p.y -= clamp( p.y, 0.0, cap.height );
    return SDFResult(length( p ) - cap.radius, cap.matindex);
}

SDFResult vertcapSDF2( VertCap cap, vec3 axis, vec3 p )
{
    p -= cap.pos;
    float y = dot(axis, p);
    p -= axis*clamp( y, 0.0, cap.height);
    return SDFResult(length( p ) - cap.radius, cap.matindex);
}

SDFResult planeSDF2( Plane plane, vec3 p )
{
    float ly = dot((p-plane.pos), plane.norm);
    vec3 local = p - (plane.pos + plane.norm*ly);
    
    float ridgex = mod(local.x, 1.0)-0.5;
    float ridgey = mod(local.y, 1.0)-0.5;
    float ridgez = mod(local.z, 1.0)-0.5;
    ridgex = clamp(ridgex*ridgex*10.0, 0.0, 0.005)*0.5;
    ridgey = clamp(ridgey*ridgey*10.0, 0.0, 0.005)*0.5;
    ridgez = clamp(ridgez*ridgez*10.0, 0.0, 0.005)*0.5;
    
    return SDFResult(ly - ridgex - ridgey - ridgez, plane.matindex);
}

SDFResult boxSDF2( RoundBox box, vec3 p )
{    
    p -= box.pos;
    vec3 d = abs(p) - box.dimensions;
    float l = length(max(d,0.0)) + min(max(d.x,max(d.y,d.z)),0.0);

    float ridgex = mod(p.x, 1.0)-0.5;
    float ridgey = mod(p.y, 1.0)-0.5;
    float ridgez = mod(p.z, 1.0)-0.5;
    ridgex = clamp(ridgex*ridgex*10.0, 0.0, 0.005)*0.5;
    ridgey = clamp(ridgey*ridgey*10.0, 0.0, 0.005)*0.5;
    ridgez = clamp(ridgez*ridgez*10.0, 0.0, 0.005)*0.5;    
 
    return SDFResult((l - ridgex - ridgey - ridgez), box.matindex);
}

///////////////////////////////////////////////////////////////////////////////////

float hashfloat( uint n ) 
{
    // integer hash copied from Hugo Elias
    n = (n << 13U) ^ n;
    n = n * (n * n * 15731U + 789221U) + 1376312589U;
    return float( n & uvec3(0x7fffffffU))/float(0x7fffffff);
}

///////////////////////////////////////////////////////////////////////////////////
// IQ's sierpinski

const vec3 g_va = vec3(  0.0, -0.95,  0.0 );
const vec3 g_vb = vec3(  0.0, 0.55,  1.15470 );
const vec3 g_vc = vec3(  1.0, 0.55, -0.57735 );
const vec3 g_vd = vec3( -1.0, 0.55, -0.57735 );

SDFResult sierSDF( vec3 p, int matindex, float time )
{
    mat3 rot = rotationmatrix(vec3(time, time*1.1, time*1.22));
    vec3 va = rot * g_va * 0.7;
    vec3 vb = rot * g_vb * 0.7;
    vec3 vc = rot * g_vc * 0.7;
    vec3 vd = rot * g_vd * 0.7;
    
    p -= vec3(2.0, 1.9, 2.0);
    
    if (length(p) > 1.2)
        return SDFResult(TOO_FAR, matindex);
    
    float a = 0.0;
    float s = 1.0;
    float r = 1.0;
    float dm;
    vec3 v;
    for( int i=0; i<6; i++ )
    {
        float d, t;
        d = dot(p-va,p-va);              v=va; dm=d; t=0.0;
        d = dot(p-vb,p-vb); if( d<dm ) { v=vb; dm=d; t=1.0; }
        d = dot(p-vc,p-vc); if( d<dm ) { v=vc; dm=d; t=2.0; }
        d = dot(p-vd,p-vd); if( d<dm ) { v=vd; dm=d; t=3.0; }
        p = v + 2.0*(p - v); r*= 2.0;
    }
    
    return SDFResult(((sqrt(dm)-1.0)/r), matindex);
}

///////////////////////////////////////////////////////////////////////////////////
// More stuff -> longer compilation times (may timeout)

#define POO
#define MRSPOO
#define STUFF
#define SIDEWALLL
//#define SIDEWALLR
//#define EYESOCKETS
//#define STUFF2        // just some minor details, which can be freely disabled

///////////////////////////////////////////////////////////////////////////////////
// optionals

#define FOLLOWCAM
//#define ROUGH
#define LIGHTBULB
#define SOFTSHADOWS    
//#define ENCLOSED
//#define DITHER

///////////////////////////////////////////////////////////////////////////////////

#define TILES 0
#define WHITE 1
#define EYEBL 2
#define EYEWH 3
#define CHROM 4
#define SIERP 5
#define BROWN 6
#define GREY  7
#define MAGEN 8

const Material g_brown = Material(vec3(0.4, 0.2, 0.1), 0.3, 0.044);
const Material g_white = Material(vec3(1.0, 1.0, 1.0), 4.5, 0.08);
const Material g_eyebl = Material(vec3(0.0, 0.0, 0.0), 0.9, 0.04);
const Material g_eyewh = Material(vec3(1.0, 1.0, 1.0), 0.9, 0.04);
const Material g_chrom = Material(vec3(0.2, 0.25, 0.3), 0.1, 0.99);
const Material g_sierp = Material(vec3(0.2, 0.5, 0.1), 4.5, 0.04);
const Material g_tiles = Material(vec3(0.6, 0.9, 0.8), 0.9, 0.2);
const Material g_grey = Material(vec3(1.0, 0.3, 1.0), 1.6, 0.004);
const Material g_magen = Material(vec3(1.0, 0.0, 1.0), 1.0, 0.0);

Material g_mats[10];

AnimObj g_poo;
AnimObj g_poo2;

///////////////////////////////////////////////////////////////////////////////////

#ifdef LIGHTBULB
const vec3 g_lightpivot = vec3(2.0, 3.75, -1.0);
const vec3 g_lightpos = vec3(2.0, 0.75, -1.0);

Light g_light = Light(vec3(1.3, 1.0, -0.5), vec3(100.0, 100.0, 100.0)*0.25);
#else
Light g_light = Light(normalize(vec3(1.0, -1.0, 1.0)), vec3(100.0, 100.0, 100.0));
#endif

///////////////////////////////////////////////////////////////////////////////////
    
float blerp(float x, float y0, float y1, float y2, float y3) {
    float a = y3 - y2 - y0 + y1;
    float b = y0 - y1 - a;
    float c = y2 - y0;
    float d = y1;
    return a * x * x * x + b * x * x + c * x + d;
}

float rand(vec2 co){
  return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

float perlin(float x, float h) {
    float a = floor(x);
    return blerp(mod(x, 1.0),
        rand(vec2(a-1.0, h)), rand(vec2(a-0.0, h)),
        rand(vec2(a+1.0, h)), rand(vec2(a+2.0, h)));
}

///////////////////////////////////////////////////////////////////////////////////
// IQ's texture based noise function (37,17) FTW!

float noise( in vec3 x )
{
    x *= 5.0;
    vec3 p = floor(x);
    vec3 f = fract(x);
    f = f*f*(3.0-2.0*f);
    vec2 uv = (p.xy+vec2(37.0,17.0)*p.z) + f.xy;
    vec2 rg = vec2(0.0);//textureLod( iChannel0, (uv+ 0.5)/256.0, 0. ).yx;
    return mix( rg.x, rg.y, f.z );
}

///////////////////////////////////////////////////////////////////////////////////
// composite SDF's

SDFResult lightSDF( vec3 p )
{
    float cablelen = g_lightpivot.y - g_lightpos.y;
    vec3 vecY = g_light.pos - g_lightpivot;
    vecY = normalize(vecY);
        
    SDFResult res = vertcapSDF2(VertCap(g_lightpivot, cablelen-0.1, 0.005, WHITE), vecY, p);
    return res;
}

SDFResult wallsSDF( vec3 p )
{
    // floor
    SDFResult res = boxSDF2(RoundBox(vec3(0.0, -1.1, 0.0), vec3(7.0, 0.1, 2.0), 0.0, TILES), p);
    // back
    res = opAdd(boxSDF2(RoundBox(vec3(0.0, 1.0, 3.5), vec3(7.0, 3.0, 2.0), 0.0, TILES), p), res);          
#ifdef SIDEWALLR
    // RHS
    res = opAdd(boxSDF2(RoundBox(vec3(4.6, 1.0, 0.0), vec3(0.1, 2.0, 1.5), 0.0, TILES), p), res);              
#endif //SIDEWALLR
#ifdef SIDEWALLL
    // LHS
    res = opAdd(boxSDF2(RoundBox(vec3(-1.6, 1.0, 0.0), vec3(0.1, 2.0, 1.5), 0.0, TILES), p), res);          
#endif //SIDEWALLL
    
#ifdef ENCLOSED
    res = opAdd(planeSDF2(Plane(vec3(0.0, 0.0, -3.5), vec3(0.0, 0.0, 1.0), TILES), p), res);          
    res = opAdd(planeSDF2(Plane(vec3(0.0, 3.0, 0.0), vec3(0.0, -1.0, 0.0), TILES), p), res);          
#endif //ENCLOSED
    
#ifdef LIGHTBULB    
    res = opAdd(lightSDF(p), res);
#endif //LIGHTBULB
    
#ifdef MRSPOO
    // recess
    res = opSmoothSub(roundboxSDF(RoundBox(vec3(2.0, 2.0, 2.5), vec3(1.1, 1.1, 1.0), 0.05, SIERP), p), res, 0.05);          
#endif //MRSPOO
        
    return res;
}

// eyes
SDFResult eyeSDF( vec3 p )
{
#ifdef EYESOCKETS    
    const float eyeoffset=0.0;        
#else
    const float eyeoffset=-0.1;    
#endif
    SDFResult res = sphereSDF(Sphere(vec3(0.15, 0.6, eyeoffset-0.31), 0.12, EYEWH), p);
    res = opSmoothAdd(sphereSDF(Sphere(vec3(-0.15, 0.6, eyeoffset-0.31), 0.12, EYEWH), p), res, 0.01);      
    res = opSmoothAdd(sphereSDF(Sphere(vec3(0.15, 0.6, eyeoffset-0.41), 0.06, EYEBL), p), res, 0.01); 
    res = opSmoothAdd(sphereSDF(Sphere(vec3(-0.15, 0.6, eyeoffset-0.41), 0.06, EYEBL), p), res, 0.01);      
    return res;    
}
   
// poop //
SDFResult pooSDF( vec3 p, AnimObj obj, int matindex )
{   
    p-=obj.pos;    // p from world space into local space
    SDFResult res = SDFResult(TOO_FAR, MAGEN);

    if (length(p-obj.centre) < obj.radius)
    {   
        p /= obj.scale;
        
        // poop
        res = torusSDF2(Torus(vec3(0.0, 0.2, 0.0), 0.5, 0.2, matindex), p);      
        res = opSmoothAdd(sphereSDF(Sphere(vec3(-0.2, 1.05, 0.1), 0.08, matindex), p), res, 0.01);
        res = opSmoothAdd(torusSDF(Torus(vec3(0.0, 0.8, 0.0), 0.1, 0.2, matindex), p), res, 0.2);      
        res = opSmoothAdd(torusSDF(Torus(vec3(0.0, 0.5, 0.0), 0.3, 0.2, matindex), p), res, 0.1);      
#ifdef EYESOCKETS
        // eye sockets        
        res = opSmoothSub(sphereSDF(Sphere(vec3(0.15, 0.6, -0.5), 0.15, matindex), p), res, 0.1);      
        res = opSmoothSub(sphereSDF(Sphere(vec3(-0.15, 0.6, -0.5), 0.15, matindex), p), res, 0.1);      
#endif //EYESOCKETS
#ifdef ROUGH        
        res -= clamp(noise(p*10.0), 0.0, 0.5)*0.005;
#endif        
        res = opSmoothAdd(eyeSDF(p), res, 0.01); 
    }
    return res;
}

// brush
SDFResult brushSDF( vec3 p )
{
    vec3 orig = vec3(0.8, -1.0, 1.2);        
    // handle
    SDFResult res = vertcapSDF(VertCap(vec3(-0.0, -0.0, .0)+orig, 0.75, 0.02, CHROM), p);
    res = opSmoothAdd(vertcapSDF(VertCap(vec3(0.0, 0.0, 0.0)+orig, 0.2, 0.1, CHROM), p), res, 0.01);
    return res;
}

SDFResult tapsSDF( vec3 p )
{
    SDFResult res = SDFResult(TOO_FAR, MAGEN);
    res = roundboxSDF(RoundBox(vec3(2.0, 0.4, 1.5), vec3(0.04, 0.14, 0.01), 0.01, CHROM), p);
    res = opSmoothAdd(roundboxSDF(RoundBox(vec3(2.0, 0.5, 1.5), vec3(0.04, 0.01, 0.09), 0.01, CHROM), p), res, 0.01);
    res = opSmoothAdd(roundboxSDF(RoundBox(vec3(2.0, 0.55, 1.5), vec3(0.04, 0.005, 0.09), 0.01, CHROM), p), res, 0.01);    
    return res;
}

// sink
SDFResult sinkSDF( vec3 p )
{
    SDFResult res = SDFResult(TOO_FAR, MAGEN);  
    vec3 orig = vec3(2.0, -1.0, 1.0);        

    vec3 centre = vec3(0.0, 1.0, 0.0)+orig;
    const float radius = 1.3;
    if (length(p-centre) < radius) 
    {   
        // pedestal
        res = roundboxSDF(RoundBox(vec3(0.0, 0.2, 0.4)+orig, vec3(0.2, 0.6, 0.1), 0.1, WHITE), p);
        // bowl 
        res = opSmoothAdd(roundboxSDF(RoundBox(vec3(0.0, 1.2, 0.2)+orig, vec3(0.5, 0.2, 0.15), 0.15, WHITE), p), res, 0.1);
        res = opSmoothSub(roundboxSDF(RoundBox(vec3(0.0, 1.7, 0.2)+orig, vec3(0.5, 0.2, 0.15), 0.15, MAGEN), p), res, 0.1);
        // base
        res = opSmoothAdd(roundboxSDF(RoundBox(vec3(0.0, 0.0, 0.6)+orig, vec3(0.3, 0.05, 0.35), 0.05, WHITE), p), res, 0.1);
        // taps
#ifdef STUFF2
        res = opSmoothAdd(tapsSDF(p), res, 0.01);
#endif //STUFF2
    }
    return res;
}

// bath
SDFResult bathSDF( vec3 p )
{
    SDFResult res = SDFResult(TOO_FAR, MAGEN);   
    vec3 orig = vec3(3.75, -1.0, 0.2);        

    vec3 centre = vec3(0.0, 0.5, 0.0)+orig;
    const float radius = 2.3;
    if (length(p-centre) < radius) 
    {   
        // pedestal
        res = roundboxSDF(RoundBox(vec3(0.0, 0.5, 0.0)+orig, vec3(0.55, 0.5, 1.0), 0.1, WHITE), p);    
    }
    return res;
}

// toilet
SDFResult toiletSDF( vec3 p )
{
    SDFResult res = SDFResult(TOO_FAR, MAGEN);    
    vec3 orig = vec3(0.0, -1.0, 1.0);        

    vec3 centre = vec3(0.1, 1.0, 0.0)+orig;
    const float radius = 1.3;
    if (length(p-centre) < radius) 
    {   
        // pedestal
        res = roundboxSDF(RoundBox(vec3(0.0, 0.2, 0.0)+orig, vec3(0.2, 0.5, 0.2), 0.1, WHITE), p);
        // bowl and lid
        res = opSmoothAdd(roundboxSDF(RoundBox(vec3(0.0, 0.6, -0.1)+orig, vec3(0.5, 0.2, 0.3), 0.05, WHITE), p), res, 0.1);
        res = opSmoothSub(roundboxSDF(RoundBox(vec3(0.0, 0.78, -0.1)+orig, vec3(0.5, 0.000002, 0.3), 0.05, WHITE), p), res, 0.001);
        // reservoir
        res = opSmoothAdd(roundboxSDF(RoundBox(vec3(0.0, 1.4, 0.5)+orig, vec3(0.5, 0.5, 0.1), 0.05, WHITE), p), res, 0.1);
        res = opSmoothSub(roundboxSDF(RoundBox(vec3(0.0, 1.8, 0.5)+orig, vec3(0.5, 0.000002, 0.1), 0.05, WHITE), p), res, 0.001);
        // base
        res = opSmoothAdd(roundboxSDF(RoundBox(vec3(0.0, 0.0, 0.0)+orig, vec3(0.3, 0.05, 0.35), 0.05, WHITE), p), res, 0.1);
#ifdef STUFF2
        // button & brush
        res = opSmoothAdd(roundboxSDF(RoundBox(vec3(0.0, 1.93, 0.5)+orig, vec3(0.05, 0.02, 0.05), 0.05, WHITE), p), res, 0.01);
        res = opSmoothAdd(brushSDF(p), res, 0.1);
#endif //STUFF2
    }
    return res;
}

///////////////////////////////////////////////////////////////////////////////////
// SDF scene

SDFResult sceneSDF(vec3 p )
{
    SDFResult res = wallsSDF(p);   
#ifdef POO    
    res = opSmoothAdd(pooSDF(p, g_poo, BROWN), res, 0.01);
#endif //POO
#ifdef STUFF
    res = opSmoothAdd(toiletSDF(p), res, 0.01);
    res = opSmoothAdd(sinkSDF(p), res, 0.01);
    res = opSmoothAdd(bathSDF(p), res, 0.01);
#endif //STUFF
#ifdef MRSPOO
    //res = opAdd(sierSDF(p, SIERP, time), res);
    res = opAdd(pooSDF(p, g_poo2, GREY), res);
#endif //MRSPOO            
    return res;
}

///////////////////////////////////////////////////////////////////////////////////
// SDF system

Result resultSDF(vec3 p)
{
    Result result = Result(vec3(0.0, 0.0, 0.0), vec3(0.0, 0.0, 0.0), TOO_FAR, TOO_FAR, 0.0, g_magen);
    SDFResult res2 = SDFResult(TOO_FAR, MAGEN);
    res2 = sceneSDF(p);
    result.normal.x = sceneSDF(p + vec3(EPSILON, 0.0, 0.0)).dist - res2.dist;
    result.normal.y = sceneSDF(p + vec3(0.0, EPSILON, 0.0)).dist - res2.dist;
    result.normal.z = sceneSDF(p + vec3(0.0, 0.0, EPSILON)).dist - res2.dist;
    result.normal = normalize(result.normal);        
    
    SDFResult res = SDFResult(TOO_FAR, MAGEN);    
    res = wallsSDF(p);
    
#ifdef POO    
    res = opAdd(SDFResult(TOO_FAR, MAGEN), res);    // WHY DO I NEED THIS?!?!?!?! THERE'S A BUG HERE SOMEWHERE
    res = opAdd(pooSDF(p, g_poo, BROWN), res);
#endif //POO        
#ifdef STUFF    
    res = opAdd(toiletSDF(p), res);
    res = opAdd(sinkSDF(p), res);
    res = opAdd(bathSDF(p), res);
#endif //STUFF
#ifdef STUFF2    
    res = opAdd(tapsSDF(p), res);
    res = opAdd(brushSDF(p), res);
#endif //STUFF    
#ifdef MRSPOO
    //res = opAdd(sierSDF(p, SIERP, time), res);
    res = opAdd(pooSDF(p, g_poo2, GREY), res);
#endif //MRSPOO
            
    result.mat=g_mats[res.matindex];
        
    result.pos = p;
    result.t = res2.dist;
    return result;
}
//aa
///////////////////////////////////////////////////////////////////////////////////
// quick light visualisation

vec3 drawlights( Ray ray )
{   
    vec3 delta = g_light.pos - ray.pos;
    vec3 closest = ray.pos + ray.dir*dot(delta, ray.dir);
    float len = length(g_light.pos-closest);

    vec3 colour = 0.5*g_light.colour/(len*300.0);
    return colour;
}

///////////////////////////////////////////////////////////////////////////////////
// raymarch world query

Result raymarch_query(Ray ray, float maxdist)
{
    float mint=TOO_FAR;
    float maxt=0.0;
    float travelled=0.0;
    for (int i=0; i<MARCH_ITERATIONS; i++)
    {
        SDFResult res = sceneSDF(ray.pos);
        
          maxt = max(maxt, res.dist);    
           if (res.dist<maxt)    
        {
            mint = min(mint, res.dist);            
        }
                
        ray.pos += res.dist*ray.dir; 
        travelled += res.dist;
        
        if (travelled>maxdist)
            break;
    }     

    Result result = resultSDF(ray.pos);
    result.mint = mint;
    result.travelled=travelled;
    return result;
}

///////////////////////////////////////////////////////////////////////////////////
// raymarch light integrator

vec3 raymarch(Ray inputray)
{
    const float exposure = 1e-2;
    const float gamma = 2.2;
    const float intensity = 100.0;
    vec3 ambient = vec3(0.2, 0.3, 0.6) *6.0* intensity / gamma;

    vec3 prevcolour = vec3(0.0, 0.0, 0.0);
    vec3 colour = vec3(0.0, 0.0, 0.0);
    vec3 mask = vec3(1.0, 1.0, 1.0);
    vec3 fresnel = vec3(1.0, 1.0, 1.0);
    
    Ray ray=inputray;
        
#ifdef LIGHTBULB    
    vec3 lightpos = g_light.pos;
#else
    vec3 lightpos = -g_light.pos*200000000000.0;    // 'directional'
#endif
    
    for (int i=0; i<REFLECT_ITERATIONS; i++)
    {
        Result result = raymarch_query(ray, 10.0);

        vec3 tolight = lightpos - result.pos;
        tolight = normalize(tolight);
                
        if (result.t > NOT_CLOSE)
        {
#ifdef LIGHTBULB            
            vec3 spotlight = drawlights(ray)*600.0;
#else            
            vec3 spotlight = vec3(1e4) * pow(clamp(dot(ray.dir, tolight),0.0,1.0), 75.0);
#endif //LIGHTBULB           
            
//          ambient = texture(iChannel1, ray.dir).xyz*100.0;
            ambient = mix(vec3(1.0, 1.0, 1.0), vec3(0.2, 0.2, 0.5), pow(abs(ray.dir.y), 0.5))*300.0;
                       
            colour += mask * (ambient + spotlight);     
            
            //colour += drawlights(ray)*80.0;
            
            break;
        }
        else
        {   
            //result.mat.colour.rgb *= noise(ray.pos);
            prevcolour = result.mat.colour.rgb;
            
            vec3 r0 = result.mat.colour.rgb * result.mat.specular;
            float hv = clamp(dot(result.normal, -ray.dir), 0.0, 1.0);
            fresnel = r0 + (1.0 - r0) * pow(1.0 - hv, 5.0);
            mask *= fresnel;            
            
            vec3 possiblelighting = clamp(dot(result.normal, tolight), 0.0, 1.0) * g_light.colour
                    * result.mat.colour.rgb * result.mat.diffuse
                    * (1.0 - fresnel) * mask / fresnel;
            
            if (length(possiblelighting) > 0.01f)
            {
                Ray shadowray = Ray(result.pos+result.normal*0.01, tolight);
                Result shadowresult = raymarch_query(shadowray, length(lightpos - result.pos)*0.9);
#ifdef SOFTSHADOWS                
                colour += possiblelighting*clamp(shadowresult.mint*4.0, 0.0, 1.0);
#else
                if (shadowresult.travelled >= length(lightpos - result.pos)*0.9)
                    colour += possiblelighting;
#endif
            }
            
            Ray reflectray;
            reflectray.pos = result.pos + result.normal*0.02f;
            reflectray.dir = reflect(ray.dir, result.normal);
            ray = reflectray;
        }
    }
        
    colour.xyz = vec3(pow(colour * exposure, vec3(1.0 / gamma)));    
    return colour;    
}

///////////////////////////////////////////////////////////////////////////////////
// Update trajectory and scaling

AnimObj UpdateObj(float time)
{
    AnimObj obj;    
    float t = time*3.5;
    float trans = mod(t, 4.0*PI) / PI;
    
    float tt1 = floor(t/(2.0*PI));
    float tt2 = floor(t/(2.0*PI))+1.0;
    vec2 src = 1.0 - vec2(perlin(tt1*37.0, 1.0), perlin(tt1*37.0, 2.0))*2.0;
    vec2 dst = 1.0 - vec2(perlin(tt2*37.0, 1.0), perlin(tt2*37.0, 2.0))*2.0;
    
    if (trans < 1.0)
        trans = trans;
    else if (trans <2.0)
        trans = 1.0;
    else if (trans<3.0)
        trans = trans-2.0;
    else
        trans = 1.0;
    
    float mysin = sin(t);
    float ypos = clamp(mysin, 0.0, 1.0) - 1.0;
    float scale = 1.0 + clamp(mysin, -1.0, 0.0)*0.5;
    
    vec2 loc = mix(src, dst, trans);
    
    obj.pos = vec3(1.0 + loc.x*1.25, ypos, loc.y*0.0 + 0.25); 
    obj.centre = vec3(0.0, 0.6, 0.0);
    obj.radius = 1.3;
    obj.scale.x = 1.0/sqrt(scale);
    obj.scale.y = scale;
    obj.scale.z = 1.0/sqrt(scale);    
    return obj;
}

///////////////////////////////////////////////////////////////////////////////////
// main loop, iterate over the pixels, doing MSAA

void main(void)
{               
    glFragColor = vec4(0.0, 0.0, 0.0, 1.0);
    float factor = 1.0/(MSAA_X*MSAA_Y);
    
    // poo
    AnimObj pp1,pp2,pp3;
    pp1 = UpdateObj(time);
    pp2 = UpdateObj(time+0.1);
    pp3 = UpdateObj(time+0.2);
    g_poo = pp1;
    g_poo.pos = pp1.pos*0.4 + pp2.pos*0.3 + pp3.pos*0.3;
    g_poo.scale = pp1.scale*0.4 + pp2.scale*0.3 + pp3.scale*0.3;

    AnimObj qq1;
    qq1 = UpdateObj(time*1.31 + 1234.0);
    g_poo2 = qq1;
    g_poo2.pos *= 0.5;
    g_poo2.pos.y -= 0.6;
    g_poo2.pos.z -= 1.0;
    g_poo2.scale *= 0.5;
    g_poo2.radius *= 0.5;
    g_poo2.centre *= 0.5;
    g_poo2.pos += vec3(1.6, 2.0, 3.0);
 
    
    // light
    vec3 pivot = g_lightpivot;
    vec3 pos = g_lightpos;
    pos.x += sin(time*2.0*1.5);
    pos.z += cos(time*1.5);
    pos = normalize(pos-pivot)*3.0 + pivot;
    g_light.pos=pos;
    
    // materials
    g_mats[TILES]=g_tiles;
    g_mats[WHITE]=g_white;
    g_mats[EYEBL]=g_eyebl;
    g_mats[EYEWH]=g_eyewh;
    g_mats[CHROM]=g_chrom;
    g_mats[SIERP]=g_sierp;
    g_mats[BROWN]=g_brown;
    g_mats[GREY ]=g_grey;
    g_mats[MAGEN]=g_magen;

#ifdef FOLLOWCAM
    // eval past camera path
    float weight=0.0;
    vec3 camtarget = vec3(0.0);
    for (float t=-1.0; t<=0.0; t++)
    {
        AnimObj h = UpdateObj(time+t);
        camtarget+=h.pos;
        weight+=1.0;
    }
    camtarget.y*=0.3;
    camtarget /= weight;
#endif //FOLLOWCAM
    
    for (float x=0.0; x<MSAA_X; x++)
    {
        for (float y=0.0; y<MSAA_Y; y++)
        {
            vec2 uv = gl_FragCoord.xy / resolution.xy * 2.0 - 1.0;
            uv.y *= resolution.y / resolution.x;

            uv.x += (1.0/(resolution.x*MSAA_X))*x;
            uv.y += (1.0/(resolution.y*MSAA_Y))*y;
            
            Ray ray;
            ray.pos = vec3(2.0, 0.0, -3.0);
            ray.dir = uv.xyx;
            ray.dir.z = 1.0;
            ray.dir = normalize(ray.dir);
            
#ifdef FOLLOWCAM
            vec3 p0 = vec3(1.0, 0.0, -2.5);
            vec3 p1 = (camtarget + vec3(1.0, 0.25, 1.0))*0.5;
            vec3 dir = (p1-p0);
            dir = normalize(dir);
            vec3 up = vec3(0.0, 1.0, 0.0);
            up = normalize(up);
            vec3 right = -cross(dir, up);
            right = normalize(right);
            up = -cross(right, dir);
            up = normalize(up);  
            
            ray.pos = p0;
            ray.dir = dir*1.0 + up*(uv.y + (1.0/(resolution.y*MSAA_Y))*y) + right*(uv.x + (1.0/(resolution.x*MSAA_X))*x);
            ray.dir = normalize(ray.dir);
#endif //FOLLOWCAM
            
#ifdef DITHER            
            float dither = hashfloat(uint(gl_FragCoord.x+resolution.x*gl_FragCoord.y)+uint(resolution.x*resolution.y)*uint(frames));//Updated with frames dimension    
            ray.pos += ray.dir*dither*0.1;
#endif //DITHER            
            
            glFragColor.xyz += raymarch(ray)*factor;            
            glFragColor.xyz += drawlights(ray)*factor;
        }        
    }    
}

///////////////////////////////////////////////////////////////////////////////////
