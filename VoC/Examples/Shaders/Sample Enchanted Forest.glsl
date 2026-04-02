#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/ttSXRW

uniform int frames;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

///////////////////////////////////////////////////////////////////////////////////
// Raymarching an IFS forest ////////////////////////////////////////////// peet //
///////////////////////////////////////////////////////////////////////////////////

#define MARCH_ITERATIONS 60        

#define REFLECT_ITERATIONS 2        // Drop me to 2 for more speed!    
#define MSAA_X 1.0
#define MSAA_Y 1.0

///////////////////////////////////////////////////////////////////////////////////
// optionals

#define LIGHTBULB
#define SOFTSHADOWS    
//#define DITHER

///////////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////////

#define TOO_FAR 100000000.0
#define NOT_CLOSE 1.0
#define EPSILON 0.001
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
    float selfillum;
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

mat3 rotaxis(vec3 axis, float a) 
{
    float s=sin(a);
    float c=cos(a);
    float oc=1.0-c;
    vec3 as=axis*s;
    mat3 p=mat3(axis.x*axis,axis.y*axis,axis.z*axis);
    mat3 q=mat3(c,-as.z,as.y,as.z,c,-as.x,-as.y,as.x,c);
    return p*oc+q;
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

#define BASIC 0
#define GRASS 1
#define TREES 2
#define MAGEN 3

const Material g_basic = Material(vec3(0.0, 1.5, 0.0), 0.0, 0.0, 1.0);
const Material g_grass = Material(vec3(0.0, 0.0, 0.0), 0.0, 0.25, 0.0);
const Material g_trees = Material(vec3(0.7, 0.3, 0.1), 0.2, 0.1, 0.0);
const Material g_magen = Material(vec3(1.5, 0.0, 1.5), 1.0, 0.1, 0.0);

Material g_mats[10];

///////////////////////////////////////////////////////////////////////////////////

#ifdef LIGHTBULB
const vec3 g_lightpivot = vec3(1.0, 3.75, 0.0);
const vec3 g_lightpos = vec3(1.0, 0.75, 0.0);

Light g_light = Light(vec3(1.3, 1.0, -0.5), vec3(100.0, 80.0, 60.0)*1.5);
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

SDFResult backgroundSDF( vec3 p )
{
    // floor at y=-1.0
    SDFResult res = planeSDF(Plane(vec3(0.0, -0.1, 0.0), vec3(0.0, 1.0, 0.0), TREES), p);
    // back wall at z=4.0
    //res = opAdd(res, boxSDF2(RoundBox(vec3(0.0, 0.0, 4.1), vec3(20.0, 20.0, 0.1), 0.0, BASIC), p));
    return res;
}

///////////////////////////////////////////////////////////////////////////////////
// IFS test

SDFResult testSDF(vec3 p)
{
    const vec3 basepos = vec3(0.0, 0.0, 0.0);
    vec3 porig = p;
    const float space = 2.2;
    p.xz = mod(p.xz + vec3(space*0.5).xz, space) - vec3(space*0.5).xz;
    vec3 delta = p - basepos;
    
    float thingy = sin(time+porig.x+porig.z*1.41);
    
    mat3 mat = rotaxis(vec3(-1.0, 0.0, 1.0)*0.85, 0.4+thingy*0.1);
    mat3 matt = rotaxis(vec3(0.0, 1.0, 0.0), sin(time*0.6)*0.5);
    mat = mat*matt;
    
    float baselen = 0.5;
    float baseradius = 0.1;
    SDFResult res = vertcapSDF( VertCap(basepos, baselen, baseradius, TREES), delta );
    
    for (int i=0; i<6; i++)
    {
        baselen *= 0.9;
        baseradius *= 0.8;
        delta.x = abs(delta.x);
        delta.z = abs(delta.z);     
        delta.y -= baselen;
        delta = delta*mat;    
        res = opSmoothAdd(res, vertcapSDF( VertCap(basepos, baselen, baseradius, TREES), delta ), baseradius);                
    }

    if (porig.z<5.0)
        res = opAdd(sphereSDF( Sphere(basepos + vec3(0.0, baselen*1.1, 0.0), baseradius*1.5, BASIC), delta ), res);                
       
    return res;    
}

///////////////////////////////////////////////////////////////////////////////////
// SDF scene

SDFResult sceneSDF(vec3 p )
{
    SDFResult res = backgroundSDF(p);   
    res = opSmoothAdd( res, testSDF(p), 0.5 );
    return res;
}

///////////////////////////////////////////////////////////////////////////////////
// SDF system

Result resultSDF(vec3 p)
{
    Result result = Result(vec3(0.0, 0.0, 0.0), vec3(0.0, 0.0, 0.0), TOO_FAR, TOO_FAR, 0.0, g_magen);
    SDFResult res2 = SDFResult(TOO_FAR, MAGEN);
    res2 = sceneSDF(p);

    // normal calculation
    result.normal = vec3(0.0);
    for( int i=min(frames,0); i<4; i++ )
    {
        vec3 e = 0.5773*(2.0*vec3((((i+3)>>1)&1), ((i>>1)&1), (i&1))-1.0);
        result.normal += e*sceneSDF(p+EPSILON*e).dist;
    }
    result.normal = normalize(result.normal);        
    
    SDFResult res = SDFResult(TOO_FAR, MAGEN);    
    res = sceneSDF(p);
                
    result.mat=g_mats[res.matindex];
        
    result.pos = p;
    result.t = res2.dist;
    return result;
}

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
// environment colour

vec3 environment(vec3 d)
{
    return mix(vec3(1.0, 1.0, 1.0), vec3(0.2, 0.2, 0.5), pow(abs(d.y), 0.5))*100.0;    
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
        
    vec3 lightpos = g_light.pos;
    
    for (int i=0; i<REFLECT_ITERATIONS; i++)
    {
        Result result = raymarch_query(ray, 10.0);

        vec3 tolight = lightpos - result.pos;
        tolight = normalize(tolight);
                
        if (result.t > NOT_CLOSE)
        {
            vec3 spotlight = drawlights(ray)*3000.0;
            
//          ambient = texture(iChannel1, ray.dir).xyz*100.0;
            ambient = vec3(0.0);
//            ambient = environment(ray.dir);
                       
            colour += mask * (ambient + spotlight);                             
            break;
        }
        else
        {   
            prevcolour = result.mat.colour.rgb;
            
            vec3 r0 = result.mat.colour.rgb * result.mat.specular;
            float hv = clamp(dot(result.normal, -ray.dir), 0.0, 1.0);
            fresnel = r0 + (1.0 - r0) * pow(1.0 - hv, 5.0);
            mask *= fresnel;            
            
            vec3 possiblelighting = clamp(dot(result.normal, tolight), 0.0, 1.0) * g_light.colour
                    * result.mat.colour.rgb * result.mat.diffuse
                    * (1.0 - fresnel) * mask / fresnel;
            
            possiblelighting += environment(reflect(ray.dir, result.normal)) * dot(result.normal, -ray.dir)*0.35;
            
            float falloff = 1.0 - clamp(length(ray.pos)*0.1, 0.0, 1.0);
            possiblelighting *= falloff;
            
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
            
            float falloff2 = 1.0 - clamp(length(ray.pos)*0.3, 0.0, 1.0);
            vec3 selfillum = result.mat.selfillum*result.mat.colour.rgb*40.0*clamp(dot(result.normal, -ray.dir), 0.0, 1.0);            
            colour += selfillum*falloff2;
            
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
// main loop, iterate over the pixels, doing MSAA

void main(void)
{               
    glFragColor = vec4(0.0, 0.0, 0.0, 1.0);
    float factor = 1.0/(MSAA_X*MSAA_Y);
        
    // light
    vec3 pivot = g_lightpivot;
    vec3 pos = g_lightpos;
    pos.x += sin(time*2.0*1.5)*0.5;
    pos.z += cos(time*1.5)*0.5;
    pos = normalize(pos-pivot)*3.0 + pivot;
    g_light.pos=pos;
    
    // materials
    g_mats[BASIC]=g_basic;
    g_mats[GRASS]=g_grass;
    g_mats[TREES]=g_trees;
    g_mats[MAGEN]=g_magen;
    
    for (float x=0.0; x<MSAA_X; x++)
    {
        for (float y=0.0; y<MSAA_Y; y++)
        {
            vec2 uv = gl_FragCoord.xy / resolution.xy * 2.0 - 1.0;
            uv.y *= resolution.y / resolution.x;

            uv.x += (1.0/(resolution.x*MSAA_X))*x;
            uv.y += (1.0/(resolution.y*MSAA_Y))*y;
            
            
            vec3 p0 = vec3(0.5, 0.25, -2.0);
            vec3 p1 = vec3(0.0+sin(time*0.5), 1.0+cos(time*0.75)*0.1, 0.0);
            vec3 dir = (p1-p0);
            dir = normalize(dir);
            vec3 up = vec3(0.0, 1.0, 0.0);
            up = normalize(up);
            vec3 right = -cross(dir, up);
            right = normalize(right);
            up = -cross(right, dir);
            up = normalize(up);  
            
            Ray ray;
            ray.pos = p0;
            ray.dir = dir*0.9 + up*(uv.y + (1.0/(resolution.y*MSAA_Y))*y) + right*(uv.x + (1.0/(resolution.x*MSAA_X))*x);
            ray.dir = normalize(ray.dir);                       
                        
#ifdef DITHER            
            float dither = hashfloat(uint(gl_FragCoord.x+resolution.x*gl_FragCoord.y)+uint(resolution.x*resolution.y)*uint(frames));//Updated with frames dimension    
            ray.pos += ray.dir*dither*0.01;
#endif //DITHER            
            
            glFragColor.xyz += raymarch(ray)*factor;            
            //glFragColor.xyz += drawlights(ray)*factor;
        }        
    }    
}

///////////////////////////////////////////////////////////////////////////////////
