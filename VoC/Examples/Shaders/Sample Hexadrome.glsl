#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/wslXRr

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*

This is public domain. Do what you please with it :)

*/

struct ray_t
{
    vec3 pos;
    vec3 dir;
    vec3 dirInv;
    int level;
    vec4 contrib;
};
    
struct hit_t
{
    float t;
    vec3 pos;
    vec3 normal;
    int mat;
};
    
const int STANDARD_MATERIAL = 1;
const int CHECKER_MATERIAL = 2;
const int POLKA_MATERIAL = 3;
const int HONEYCOMB_MATERIAL = 4;

struct material_t
{
    int type;
    int flags;
    int attrib0;
    int attrib1;
    vec4 ambient;
    vec4 diffuse;
    vec4 specular;
    vec4 emission;
    vec4 reflection;
    vec4 transparent;
};
    
const int SPHERE_PRIMITIVE = 1;
const int PLANE_PRIMITIVE = 2;
const int RING_PRIMITIVE = 3;
const int BOX_PRIMITIVE = 4;

struct primitive_t
{
    int type;
    int mat;
    vec3 v0;
    vec3 v1;
    vec3 v2;
};
    
const float PI = 3.1415926535897932384626433832795;
const float INFINITE = 1e6;
const float EPSILON = 1e-6;
const float EPSILON4 = 1e-4;

vec3 viewFrom = vec3(0,-1,1);
vec3 viewAt = vec3(0,0,-1);
vec3 viewUp = vec3(0,0,1);
float viewFov = 45.0;

vec3 viewDir;
vec3 viewRight;
float viewTan;
float aspect = 1.33;
int oversample = 2;

vec4 skyColor = vec4(0.2,0.,0.5,1);
vec4 horizonColor = vec4(0.5,0.8,1,1);

const material_t material0 = material_t(STANDARD_MATERIAL,
                                   0,0,0, 
                                   vec4(.1,.1,.1,1), 
                                   vec4(.1,.1,.1,1), 
                                   vec4(1,1,1,100), 
                                   vec4(0,0,0,0), 
                                   vec4(0,0,0,0), 
                                   vec4(0,0,0,0));

const material_t material1 = material_t(STANDARD_MATERIAL,
                                   0,0,0, 
                                   vec4(0.5,0,1,1), 
                                   vec4(0.5,0,1,1), 
                                   vec4(1,1,1,100), 
                                   vec4(0,0,0,0), 
                                   vec4(0,0,0,0), 
                                   vec4(0,0,0,0));

const material_t material2 = material_t(
                                   HONEYCOMB_MATERIAL,
                                   0,0,1, 
                                   vec4(0.5,0.5,0.5,0), 
                                   vec4(0.001,0.001,0.001,0), 
                                   vec4(0,0,0,0), 
                                   vec4(0,0,0,0), 
                                   vec4(0,0,0,0), 
                                   vec4(0,0,0,0));

const material_t material3 = material_t(
                                   STANDARD_MATERIAL,
                                   0,0,0, 
                                   vec4(0,0,0,1), 
                                   vec4(0,0,0,1), 
                                   vec4(1,1,1,50), 
                                   vec4(0,0,0,0), 
                                   vec4(0.2,0.2,0.2,0), 
                                   vec4(0.6,0.6,0.6,1.54));

const material_t material4 = material_t(
                                   STANDARD_MATERIAL,
                                   0,0,0, 
                                   vec4(0.1,0.1,0.1,1), 
                                   vec4(0.1,0.1,0.1,1), 
                                   vec4(1,1,1,50), 
                                   vec4(0,0,0,0), 
                                   vec4(0.3,0.3,0.3,0), 
                                   vec4(0,0,0,0));

const material_t material5 = material_t(
                                   STANDARD_MATERIAL,
                                   0,0,0, 
                                   vec4(0,0,1,1), 
                                   vec4(0,0,1,1), 
                                   vec4(1,1,1,60), 
                                   vec4(0,0,0,0), 
                                   vec4(0,0,0,0), 
                                   vec4(0,0,0,0));

const material_t material6 = material_t(
                                   STANDARD_MATERIAL,
                                   0,0,0, 
                                   vec4(.8,.4,0,1), 
                                   vec4(.8,.4,0,1), 
                                   vec4(0.5,0.5,0.5,30), 
                                   vec4(0,0,0,0), 
                                   vec4(0.1,0.1,0.1,0), 
                                   vec4(0,0,0,0));

material_t materials[7] = material_t[7](material0, material1, material2, material3, material4, material5, material6);

const primitive_t _floor = primitive_t(PLANE_PRIMITIVE, 2, vec3(0, 0, -3), vec3(0, 0, 1), vec3(0,0,0));
const primitive_t _sphere = primitive_t(SPHERE_PRIMITIVE, 4, vec3(-2, 0, 0), vec3(3, 0, 0), vec3(0,0,0));
const primitive_t _box = primitive_t(BOX_PRIMITIVE, 3, vec3(3.5, 0, -2.99), vec3(8.5, 5, 2), vec3(0,0,0));

const int NUM_PRIMS = 3;

primitive_t prims[NUM_PRIMS] = primitive_t[NUM_PRIMS](_floor, _sphere, _box);

ray_t primary_ray(float fx, float fy)
{
    ray_t ray;
    ray.pos = viewFrom;
    ray.dir = normalize(viewDir + viewRight * fx  * aspect + viewUp * fy);
    ray.dirInv = vec3(1) / ray.dir;
    ray.contrib = vec4(1,1,1,1);
    return ray;
}

vec4 background(ray_t ray)
{
    float t = 1.0 - ray.dir.z * ray.dir.z;
    t = pow(t, 30.0);
    return skyColor * (1.0-t) + horizonColor * t;
}

bool hit_sphere(vec3 center, float radius, int mat, ray_t ray, inout hit_t hit)
{
    vec3 q = ray.pos - center;
    float a = dot(ray.dir, ray.dir);
    float b = 2.0 * dot(q, ray.dir);
    float c = dot(q,q) - radius * radius;
    float d = b * b - 4.0 * a * c;
    if(d > EPSILON)
    {
        float t0 = (-b - sqrt(d)) / (2.0 * a);
        float t1 = (-b + sqrt(d)) / (2.0 * a);

        float t = INFINITE;
        
        if(t1 > EPSILON && t1 < t0)
        {
            t = t1;
        }
        else            
        {
            t = t0;
        }
        
        if(t < EPSILON)
        {
            t = INFINITE;
        }
        
        if(t != INFINITE)
        {
            hit.t = t;
            hit.pos = ray.pos + ray.dir * hit.t;
            hit.normal = normalize(hit.pos - center);
            hit.mat = mat;
            return true;
        }
    }
    return false;
}

bool hit_plane(vec3 p0, vec3 normal, int mat, ray_t ray, inout hit_t hit)
{
    float d = dot(normal, ray.dir);
    if(d > EPSILON || d < -EPSILON)
    {
        vec3 q = p0 - ray.pos;
        float t = dot(q, normal) / d;
        if(t > EPSILON)
        {
            hit.t = t;
            hit.pos = ray.pos + ray.dir * t;
            hit.normal = normal;
            hit.mat = mat;
            return true;
        }
    }
    return false;
}

bool hit_ring(vec3 p0, vec3 normal, float r1, float r2, int mat, ray_t ray, inout hit_t hit)
{
    float d = dot(normal, ray.dir);
    if(d > EPSILON || d < -EPSILON)
    {
        vec3 q = p0 - ray.pos;
        float t = dot(q, normal) / d;
        if(t > EPSILON)
        {
            vec3 p = ray.pos + ray.dir * t;
            vec3 r = p - p0;
            float e = dot(r, r);
            if(e < r1*r1 && e > r2*r2)
            {
                hit.t = t;
                hit.pos = p;
                hit.normal = normal;
                hit.mat = mat;
                return true;
            }
        }
    }
    return false;
}

bool hit_box(vec3 p0, vec3 p1, int mat, ray_t ray, inout hit_t hit)
{
    float txmin = (p0.x - ray.pos.x) * ray.dirInv.x;
    float txmax = (p1.x - ray.pos.x) * ray.dirInv.x;
    float tymin = (p0.y - ray.pos.y) * ray.dirInv.y;
    float tymax = (p1.y - ray.pos.y) * ray.dirInv.y;
    float tzmin = (p0.z - ray.pos.z) * ray.dirInv.z;
    float tzmax = (p1.z - ray.pos.z) * ray.dirInv.z;
    
    float tmin = max(max(min(txmin, txmax), min(tymin, tymax)), min(tzmin, tzmax));
    float tmax = min(min(max(txmin, txmax), max(tymin, tymax)), max(tzmin, tzmax));
    
    if(tmax < EPSILON || tmin > tmax)
    {
        return false;
    }
    
    if(tmin < EPSILON)
    {
        tmin = tmax; // inside the box
    }
    
    
    if(tmin > EPSILON)
    {
        hit.t = tmin;
        hit.pos = ray.pos + ray.dir * hit.t;
        
        if(hit.pos.x < p0.x+EPSILON4)
            hit.normal = vec3(-1, 0, 0);
        else if(hit.pos.x > p1.x-EPSILON4)
            hit.normal = vec3(1,0,0);
        else if(hit.pos.y < p0.y+EPSILON4)
            hit.normal = vec3(0, -1, 0);
        else if(hit.pos.y > p1.y-EPSILON4)
            hit.normal = vec3(0, 1, 0);
        else if(hit.pos.z < p0.z+EPSILON4)
            hit.normal = vec3(0, 0, -1);
        else if(hit.pos.z > p1.z-EPSILON4)
            hit.normal = vec3(0, 0, 1);
        
        hit.mat = mat;
        return true;
    }
    
    return false;
}

vec4 ambientLight = vec4(0.2, 0.2, 0.2, 1);
vec3 lightDirection = normalize(vec3(1,1,-1));

ray_t rayQueue[16];
int rayHead = 0;
int rayTail = 0;

void enqueueRay(ray_t ray)
{
    if((rayTail+1) % 16 != rayHead)
    {
        rayQueue[rayTail] = ray;
        rayTail++;
        rayTail %= 16;
    }
}

bool dequeueRay(inout ray_t ray)
{
    if(rayHead != rayTail)
    {
        ray = rayQueue[rayHead];
        rayHead++;
        rayHead %= 16;
        return true;
    }
    return false;
}

void resetRayQueue()
{
    rayHead = rayTail = 0;
}

void intersect(ray_t ray, inout hit_t hit);

vec4 shade_standard(ray_t ray, hit_t hit)
{
    if(ray.level >= 8)
        return vec4(0,0,0,0);
    
    vec4 color = materials[hit.mat].ambient * ambientLight;
    
    ray_t sray;
    sray.pos = hit.pos - lightDirection * EPSILON;
    sray.dir = -lightDirection;
    hit_t h;
    intersect(sray, h);
    if(h.t == INFINITE)
    {    
        float d = dot(-lightDirection, hit.normal);
        d = clamp(d, 0.0, 1.0);
        color += materials[hit.mat].diffuse * d;
        vec3 r = reflect(ray.dir, hit.normal);
        float s = dot(-lightDirection, r);
        s = clamp(s, 0.0, 1.0);
        s = pow(s, materials[hit.mat].specular.a);
        color.rgb += materials[hit.mat].specular.rgb * s;
    }
    
    color.rgb += materials[hit.mat].emission.rgb;
    
    vec3 refl = materials[hit.mat].reflection.rgb;
    if(dot(refl, refl) > 0.0)
    {
        ray_t rray;
        vec3 r = reflect(ray.dir, hit.normal);
        rray.pos = hit.pos + r * 0.001;
        rray.dir = r;
        rray.dirInv = vec3(1) / rray.dir;
        rray.level = ray.level + 1;
        rray.contrib = vec4(refl, 1) * ray.contrib;
        enqueueRay(rray);
    }
    
    vec3 trans = materials[hit.mat].transparent.rgb;
    if(dot(trans, trans) > 0.0)
    {
        float ior = materials[hit.mat].transparent.a;
        if(dot(ray.dir, hit.normal) < 0.0)
            ior = 1.0 / ior;
        
        ray_t rray;
        rray.pos = hit.pos + ray.dir * 0.001;
        rray.dir = refract(ray.dir, hit.normal, ior);
        rray.dirInv = vec3(1) / rray.dir;
        rray.level = ray.level + 1;
        rray.contrib = vec4(trans, 1) * ray.contrib;
        enqueueRay(rray);
    }
    
    return color;
}

vec4 shade_checker(ray_t ray, hit_t hit)
{
    vec3 p = hit.pos * materials[hit.mat].ambient.xyz
        + materials[hit.mat].diffuse.xyz;

    int ix = int(floor(p.x)) & 0x01;
    int iy = int(floor(p.y)) & 0x01;
    int iz = int(floor(p.z)) & 0x01;

    hit.mat = ((ix ^ iy ^ iz) == 0) ? materials[hit.mat].attrib0 : materials[hit.mat].attrib1;

    return shade_standard(ray, hit);
}

vec4 shade_polka(ray_t ray, hit_t hit)
{
    vec3 p = hit.pos * materials[hit.mat].ambient.xyz
        + materials[hit.mat].diffuse.xyz;

    int iy = int(floor(p.y)) & 0x01;
    if((iy & 0x01) == 1)
        p.x += 0.5;

    vec3 p2 = mod(p, vec3(1.));
    p2 *= 2.;
    p2 -= 1.;
        
    float d = dot(p2,p2);

    hit.mat = (d < (.666*.666)) ? materials[hit.mat].attrib0 : materials[hit.mat].attrib1;

    return shade_standard(ray, hit);
}

const float SIN60 = 0.86602540378443864676372317075294;

vec4 shade_honeycomb(ray_t ray, hit_t hit)
{
    vec3 p = hit.pos * materials[hit.mat].ambient.xyz
        + materials[hit.mat].diffuse.xyz;

    //int iy = int(floor(p.y)) & 0x01;
    //if((iy & 0x01) == 1)
    //     p.x += 0.5;
    p.y += floor(p.x) * 0.5;
    
    vec3 p2 = mod(p, vec3(1.));
    p2 *= 2.;
    p2 -= 1.;
    p2 *= vec3(1.1,1.2,1.);
    p2 = abs(p2);
        
    //float d = dot(p2,p2);
    float d = max((p2.x*SIN60+p2.y*0.5),p2.y);
    
    hit.mat = (d < (1.)) ? materials[hit.mat].attrib0 : materials[hit.mat].attrib1;

    return shade_standard(ray, hit);
}

vec4 shade(ray_t ray, hit_t hit)
{
    vec4 color;
    
    if(hit.t != INFINITE)
    {    
        int type = materials[hit.mat].type;

        switch(type)
        {
        case STANDARD_MATERIAL:
            color = shade_standard(ray, hit);
            break;
        case CHECKER_MATERIAL:
            color = shade_checker(ray, hit);
            break;
        case POLKA_MATERIAL:
            color = shade_polka(ray, hit);
            break;
        case HONEYCOMB_MATERIAL:
            color = shade_honeycomb(ray, hit);
            break;            
        }
        
        // fog

        float f = (hit.t - 10.0) / (50.0-10.0);
        f = clamp(f, 0.0, 1.0);
        color = mix(color, horizonColor, f);
    }
    else
    {
        color = background(ray);
    }
    
    return color * ray.contrib;
}

void intersect(ray_t ray, inout hit_t hit)
{
    hit.t = INFINITE;
    
    for(int i = 0; i < NUM_PRIMS; i++)
    {
        hit_t h;
        int type = prims[i].type;
        bool result = false;
        
        switch(type)
        {
        case PLANE_PRIMITIVE:
            result = hit_plane(prims[i].v0, prims[i].v1, prims[i].mat, ray, h);
            break;
        case SPHERE_PRIMITIVE:
            result = hit_sphere(prims[i].v0, prims[i].v1.x,  prims[i].mat, ray, h);            
            break;
        case RING_PRIMITIVE:
            result = hit_ring(prims[i].v0, prims[i].v1, prims[i].v2.x, prims[i].v2.y, prims[i].mat, ray, h);
            break;
        case BOX_PRIMITIVE:
            result = hit_box(prims[i].v0, prims[i].v1, prims[i].mat, ray, h);
        }
        
        if(result && h.t < hit.t)
        {
            hit = h;
        }
    }    
}

vec4 raytrace(ray_t ray)
{
    hit_t hit;
    
    intersect(ray, hit);
    
    return shade(ray, hit);
}

void main(void)
{
    viewFrom = vec3(sin(time*.5)*14.0, -10.-cos(time*.5)*4.0, 2. + sin(time*1.5)*3.);
    
    
    aspect = resolution.x / resolution.y;
    viewTan = tan(((viewFov/180.0)*PI)/2.0);    
    vec2 uv = gl_FragCoord.xy/resolution.xy * vec2(2,2) - vec2(1,1);
    uv *= viewTan;
    viewDir = normalize(viewAt-viewFrom);
    viewRight = cross(viewDir, viewUp);
    viewUp = cross(viewRight, viewDir);
    
    
    vec4 color = vec4(0,0,0,0);
    float sx = (1.0 / float(oversample)) / resolution.x;
    float sy = (1.0 / float(oversample)) / resolution.y;
    
    for(int i = 0; i < oversample; i++)
    {
        for(int j = 0; j < oversample; j++)
        {
            ray_t ray = primary_ray(uv.x + float(i) * sx, uv.y + float(j) * sy);
            resetRayQueue();
            enqueueRay(ray);
            
            while(dequeueRay(ray))
                color += raytrace(ray);
        }
    }
    
    // vignette    
    float d = pow(1. - dot(uv,uv), 3.);
    color *= d;
    
    color /= float(oversample*oversample);
    glFragColor = color;
}
