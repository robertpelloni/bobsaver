#version 420

// original https://www.shadertoy.com/view/WlXXzS

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

///////////////////////////////////////////////////////////////////////////////////
// Trying out some raymarching, and combining it with Schlicks Approximation //////
///////////////////////////////////////////////////////////////////////////////////

#define MARCH_EPSILON 0.01
#define MARCH_ITERATIONS 30

#define SMOOTH_DIST 0.5
#define MAT_CHANGE 0.1

#define TOO_FAR 10000.0

#define REFLECT_ITERATIONS 3
#define EPSILON 0.0001
#define MSAA 1.0

#define NUM_SPHERES 30

#define HURRY_UP 1.5

///////////////////////////////////////////////////////////////////////////////////

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
    Material mat;
};
    
struct Light {
    vec3 dir;
    vec3 colour;
};
    
struct Result {
    vec3 pos;
    vec3 normal;
    Material mat;
};

///////////////////////////////////////////////////////////////////////////////////

Material g_NoMaterial = Material(vec3(1.0, 0.0, 1.0), 0.0, 1.0);
    
///////////////////////////////////////////////////////////////////////////////////
        
Sphere g_spheres[NUM_SPHERES];

Light g_light = Light(normalize(vec3(1.0, -1.0, 1.0)), vec3(150.0, 100.0, 50.0));

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
// SDF's & other spatial query functions

float opSmoothUnion( float d1, float d2, float k ) 
{
    float h = clamp( 0.5 + 0.5*(d2-d1)/k, 0.0, 1.0 );
    return mix( d2, d1, h ) - k*h*(1.0-h); 
}

float sphereSDF(Sphere sphere, vec3 p) 
{
    return length(sphere.pos - p) - sphere.radius;
}

float sceneSDF(vec3 p)
{
    float mindist = TOO_FAR;
    for (int i=0; i<NUM_SPHERES; i++)
    {
        float dist = sphereSDF(g_spheres[i], p);
        dist = opSmoothUnion(mindist, dist, SMOOTH_DIST);
        if (dist < mindist)
        {
            mindist = dist;    
        }
    }
      
    return mindist;
}

Material materialAt(vec3 p)
{
    float mindist = TOO_FAR;
    float weight = 1.0f;
    Material mat = Material(vec3(0.0), 0.0, 0.0);
    
    for (int i=0; i<NUM_SPHERES; i++)
    {
        float dist = sphereSDF(g_spheres[i], p);
        if (dist < SMOOTH_DIST)
        {
            float scale = (SMOOTH_DIST-dist)/SMOOTH_DIST;
       
            mat.colour += g_spheres[i].mat.colour * scale;                    
            mat.diffuse += g_spheres[i].mat.diffuse * scale;                    
            mat.specular += g_spheres[i].mat.specular * scale;                    
            mindist = dist;
        }
    }
        
    if (mindist<SMOOTH_DIST)
        return mat;
    else
        return g_NoMaterial;
}

Result resultSDF(vec3 p)
{
    Result result;
    result.normal.x = sceneSDF(p + vec3(EPSILON, 0.0, 0.0)) - sceneSDF(p);
    result.normal.y = sceneSDF(p + vec3(0.0, EPSILON, 0.0)) - sceneSDF(p);
    result.normal.z = sceneSDF(p + vec3(0.0, 0.0, EPSILON)) - sceneSDF(p);
    result.normal = normalize(result.normal);
    result.mat = materialAt(p);
    result.pos = p;
    return result;
}

///////////////////////////////////////////////////////////////////////////////////
// raymarch query, returning intersection point, normal, surface colour

Result raymarch_query(Ray ray)
{
    Result result = Result(vec3(0.0, 0.0, 0.0), vec3(0.0, 0.0, 0.0), g_NoMaterial);
    for (int i=0; i<MARCH_ITERATIONS; i++)
    {
        float signeddist = sceneSDF(ray.pos);
        
        ray.pos += signeddist*ray.dir*1.4;       
    }
    result = resultSDF(ray.pos);
    return result;
}

vec3 raymarch(Ray inputray)
{
    const float exposure = 1e-2;
    const float gamma = 2.2;
    const float intensity = 100.0;
    const vec3 ambient = vec3(0.3, 0.4, 0.5) *1.0* intensity / gamma;

    vec3 colour = vec3(0.0, 0.0, 0.0);
    vec3 mask = vec3(1.0, 1.0, 1.0);
    vec3 fresnel = vec3(1.0, 1.0, 1.0);
    
    Ray ray=inputray;
        
    for (int i=0; i<REFLECT_ITERATIONS; i++)
    {
        Result result = raymarch_query(ray);

        if (result.mat.diffuse==0.0)
        {
            vec3 spotlight = vec3(1e4) * pow(clamp(dot(ray.dir, -g_light.dir),0.0,1.0), 250.0);

            colour += mask * (ambient + spotlight); 
            break;
        }
        else
        {              
            vec3 r0 = result.mat.colour.rgb * result.mat.specular;
            float hv = clamp(dot(result.normal, -ray.dir), 0.0, 1.0);
            fresnel = r0 + (1.0 - r0) * pow(1.0 - hv, 5.0);
            mask *= fresnel;            
                        
            colour += clamp(dot(result.normal, -g_light.dir), 0.0, 1.0) * g_light.colour
                * result.mat.colour.rgb * result.mat.diffuse
                * (1.0 - fresnel) * mask / fresnel;
                        
            Ray reflectray;
            reflectray.pos = result.pos + result.normal*MARCH_EPSILON*2.0f;
            reflectray.dir = reflect(ray.dir, result.normal);
            ray = reflectray;
        }
    }
        
    colour.xyz = vec3(pow(colour * exposure, vec3(1.0 / gamma)));    
    return colour;    
}

///////////////////////////////////////////////////////////////////////////////////
// initialise all the primitives

void setupscene()
{   
    // scene definition    
    for (int i=0; i<NUM_SPHERES; i++)
    {
        vec3 origin;
        origin.x = 2.0 - perlin(HURRY_UP*time*0.212, float(i) + 1.0)*4.0;
        origin.y = 2.0 - perlin(HURRY_UP*time*0.341, float(i) + 2.0)*4.0;
        origin.z = 4.0 + 1.0 - perlin(HURRY_UP*time*0.193, float(i) + 3.0)*4.0;
        float radius = 0.3 + perlin(HURRY_UP*time*0.999, float(i) + 6.0)*0.3;

        vec3 colour;
        colour.x = perlin(float(i)*0.212+(time*MAT_CHANGE), float(i) + 1.0)*3.5;
        colour.y = perlin(float(i)*0.341+(time*MAT_CHANGE), float(i) + 2.0)*3.5;
        colour.z = perlin(float(i)*0.193+(time*MAT_CHANGE), float(i) + 3.0)*3.5;
        float diffuse = 0.1f + perlin(float(i)*0.341+(time*MAT_CHANGE), float(i) + 4.0)*0.9f;
        float specular = pow(perlin(float(i)*0.193+(time*MAT_CHANGE), float(i) + 5.0), 3.0);
        
        g_spheres[i].pos = origin;
        g_spheres[i].radius = radius;
        g_spheres[i].mat = Material(colour, diffuse, specular);        
    }    
}

///////////////////////////////////////////////////////////////////////////////////
// main loop, iterate over the pixels, doing MSAA

void main(void)
{           
    setupscene();
    
    glFragColor = vec4(0.0, 0.0, 0.0, 1.0);
    float factor = 1.0/(MSAA*MSAA);
    
    for (float x=0.0; x<MSAA; x++)
    {
        for (float y=0.0; y<MSAA; y++)
        {
            vec2 uv = gl_FragCoord.xy / resolution.xy * 2.0 - 1.0;
            uv.y *= resolution.y / resolution.x;

            uv.x += (1.0/(resolution.x*MSAA))*x;
            uv.y += (1.0/(resolution.y*MSAA))*y;
            
            Ray ray;
            ray.pos = vec3(0.0, 0.0, 0.0);
            ray.dir = uv.xyx;
            ray.dir.z = 1.0;
            ray.dir = normalize(ray.dir);

            glFragColor.xyz += raymarch(ray)*factor;
        }        
    }
}

///////////////////////////////////////////////////////////////////////////////////
