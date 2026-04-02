#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/WdsSzN

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
    int level;
    vec4 contrib;
};
    
struct hit_t
{
    float t;
    vec3 pos;
    vec3 normal;
    int prim;
    int mat;
};
    
const int STANDARD_MATERIAL = 1;
const int CHECKER_MATERIAL = 2;
const int STARS_MATERIAL = 6;
    
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
const int oversample = 1;

const vec4 skyColor = vec4(0,0.25,0.75,1);
const vec4 horizonColor = vec4(0.5,0.5,1,1);

const float fogNear = 10.;
const float fogFar = 50.;
const float fogDenom = 1. / (fogFar - fogNear);
const vec4 fogColor = horizonColor;

const material_t material0 = material_t(STANDARD_MATERIAL,
                                   0,0,0, 
                                   vec4(1,0.8,0,1), 
                                   vec4(1,0.8,0,1), 
                                   vec4(1,1,1,100), 
                                   vec4(0,0,0,0), 
                                   vec4(0,0,0,0),
                                   vec4(0,0,0,0));

const material_t material1 = material_t(STANDARD_MATERIAL,
                                   0,0,0, 
                                   vec4(.25,0,1,1), 
                                   vec4(.25,0,1,1), 
                                   vec4(0.5,0.5,0.5,30), 
                                   vec4(0,0,0,0), 
                                   vec4(0,0,0,0), 
                                   vec4(0,0,0,0));

const material_t material2 = material_t(
                                   STARS_MATERIAL,
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
                                   vec4(0.6,0.6,0.6,1.24));

const material_t material4 = material_t(
                                   STANDARD_MATERIAL,
                                   0,0,0, 
                                   vec4(0.3,0.3,0.3,1), 
                                   vec4(0.3,0.3,0.3,1), 
                                   vec4(1,1,1,50), 
                                   vec4(0,0,0,0), 
                                   vec4(0.6,0.6,0.6,0), 
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
                                   vec4(0,0,0,1), 
                                   vec4(0,0,0,1), 
                                   vec4(0.5,0.5,0.5,30), 
                                   vec4(0,0,0,0), 
                                   vec4(0.01,0.01,0.01,0), 
                                   vec4(1,0.1,0.1,1.54));

material_t materials[7] = material_t[7](material0, material1, material2, material3, material4, material5, material6);

const primitive_t _floor = primitive_t(PLANE_PRIMITIVE, 2, vec3(0, 0, -3), vec3(0, 0, 1), vec3(0,0,0));
const primitive_t _sphere = primitive_t(SPHERE_PRIMITIVE, 3, vec3(0, 0, -1), vec3(2, 0, 0), vec3(0,0,0));
const primitive_t _sphere2 = primitive_t(SPHERE_PRIMITIVE, 4, vec3(4, 2, -1.5), vec3(1.5, 0, 0), vec3(0,0,0));
const primitive_t _sphere3 = primitive_t(SPHERE_PRIMITIVE, 5, vec3(-4, -3, -2), vec3(1, 0, 0), vec3(0,0,0));
const primitive_t _sphere4 = primitive_t(SPHERE_PRIMITIVE, 6, vec3(-2, 4, -1.8), vec3(1.2, 0, 0), vec3(0,0,0));

const int NUM_PRIMS = 5;

primitive_t prims[NUM_PRIMS] = primitive_t[NUM_PRIMS](_floor, _sphere, _sphere2, _sphere3, _sphere4);

ray_t primary_ray(float fx, float fy)
{
    ray_t ray;
    ray.pos = viewFrom;
    ray.dir = normalize(viewDir + viewRight * fx  * aspect + viewUp * fy);
    ray.contrib = vec4(1,1,1,1);
    return ray;
}

vec4 background(ray_t ray)
{
    float t = 1.0 - ray.dir.z * ray.dir.z;
    t = pow(t, 60.0);
    return skyColor * (1.0-t) + horizonColor * t;
}

bool hit_sphere(int i, ray_t ray, inout hit_t hit)
{
    vec3 center = prims[i].v0;
    float radius = prims[i].v1.x;
    
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
            hit.mat = prims[i].mat;
            return true;
        }
    }
    return false;
}

bool hit_plane(int i, ray_t ray, inout hit_t hit)
{
    vec3 p0 = prims[i].v0;
    vec3 normal = prims[i].v1;
        
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
            hit.mat = prims[i].mat;
            return true;
        }
    }
    return false;
}

/*bool hit_ring(vec3 p0, vec3 normal, float r1, float r2, int mat, ray_t ray, inout hit_t hit)
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
}*/

vec4 ambientLight = vec4(0.2, 0.2, 0.1, 1);
//vec3 lightDirection = normalize(vec3(1,1,-1));
vec3 lightPosition = vec3(-10,-10,10);

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

const int SS_QUALITY = 8;
const int SS_SIZE = SS_QUALITY*SS_QUALITY;
const float SS_SCALE = 2. / float(SS_QUALITY-1);
const float SS_LIGHT_RADIUS = 0.75;

vec4 shadowIntersect(ray_t ray, inout hit_t hit)
{
    vec4 color = vec4(1);
    hit.t = INFINITE;
    
#pragma unroll 1
    
    for(int i = 0; i < NUM_PRIMS; i++)
    {
        hit_t h;
        int type = prims[i].type;
        bool result = false;
        
        switch(type)
        {
        case PLANE_PRIMITIVE:
            //result = hit_plane(prims[i].v0, prims[i].v1, prims[i].mat, ray, h);
            result = hit_plane(i, ray, h);
            break;
        case SPHERE_PRIMITIVE:
            //result = hit_sphere(prims[i].v0, prims[i].v1.x,  prims[i].mat, ray, h);            
            result = hit_sphere(i, ray, h);
            break;
        /*case RING_PRIMITIVE:
            result = hit_ring(prims[i].v0, prims[i].v1, prims[i].v2.x, prims[i].v2.y, prims[i].mat, ray, h);
            break;*/
        }
        
        if(result && h.t > EPSILON)
        {
            hit = h;
            hit.prim = i;
            if(materials[hit.mat].transparent == vec4(0))
            {
                 color = vec4(0);
                break;
            }
            else
            {
                color *= materials[hit.mat].transparent * -dot(ray.dir, hit.normal);
            }
        }
    }
    return color;
}

vec4 shade_standard(ray_t ray, hit_t hit)
{
    if(ray.level >= 4)
        return vec4(0,0,0,0);
    
    vec4 color = materials[hit.mat].ambient * ambientLight;
    
    vec3 rawLightDir = hit.pos - lightPosition;
    vec3 lightDirection = normalize(rawLightDir);
    
    ray_t sray;
    sray.pos = hit.pos - lightDirection * EPSILON;
    
    vec3 u = cross(lightDirection, vec3(0,0,1));
    vec3 v = normalize(cross(u, lightDirection));
    u = cross(lightDirection, v);
                       
    float shadow = 0.;
    vec4 shadowColor = vec4(0);
    float w = 0.;
    if(SS_QUALITY > 1)
    {
        for(int i = 0; i < SS_SIZE; i++)
        {
            sray.dir = -rawLightDir;

            int iu = i % SS_QUALITY;
            int iv = i / SS_QUALITY;
            float fu = (float(iu) * SS_SCALE) - 1.;
            float fv = (float(iv) * SS_SCALE) - 1.;
            sray.dir += (fu * u + fv * v) * SS_LIGHT_RADIUS;
            sray.dir = normalize(sray.dir);
            hit_t h;
            vec4 scolor = shadowIntersect(sray, h);
            float fw =(fu*fu+fv*fv);
            shadowColor += scolor;
            if(h.t != INFINITE)
            {            
                shadow += fw;
            }
            w += fw;
        }
    }
    else        
    {
        sray.dir = -lightDirection;
        hit_t h;
        vec4 scolor = shadowIntersect(sray, h);
        shadowColor = scolor;
        if(h.t != INFINITE)
        {            
            shadow = 1.;
        }
        w = 1.;
    }
    w = 1. / w;
    shadow *= w;
    //shadow = 1. - shadow;
    if(shadow <= 1.)
    {
        shadowColor *= w;
        float d = dot(-lightDirection, hit.normal);
        d = clamp(d, 0.0, 1.0);
        color += materials[hit.mat].diffuse * shadowColor * d;
        vec3 r = reflect(ray.dir, hit.normal);
        float s = dot(-lightDirection, r);
        s = clamp(s, 0.0, 1.0);
        s = pow(s, materials[hit.mat].specular.a);
        color.rgb += materials[hit.mat].specular.rgb * shadowColor.rgb * s;
    }
    
    color.rgb += materials[hit.mat].emission.rgb;
    
    vec3 refl = materials[hit.mat].reflection.rgb;
    if(dot(refl, refl) > 0.0)
    {
        ray_t rray;
        vec3 r = reflect(ray.dir, hit.normal);
        rray.pos = hit.pos + r * 0.001;
        rray.dir = r;
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
        rray.level = ray.level + 1;
        rray.contrib = vec4(trans, 1) * ray.contrib;
        enqueueRay(rray);
    }
    
    return color;
}

/*vec4 shade_checker(ray_t ray, hit_t hit)
{
    vec3 p = hit.pos * materials[hit.mat].ambient.xyz
        + materials[hit.mat].diffuse.xyz;

    int ix = int(floor(p.x)) & 0x01;
    int iy = int(floor(p.y)) & 0x01;
    int iz = int(floor(p.z)) & 0x01;

    hit.mat = ((ix ^ iy ^ iz) == 0) ? materials[hit.mat].attrib0 : materials[hit.mat].attrib1;

    return shade_standard(ray, hit);
}*/

const int POINTS = 5;
const float ANGLE = PI*2./float(POINTS);

vec4 shade_stars(ray_t ray, hit_t hit)
{
    vec3 p = hit.pos * materials[hit.mat].ambient.xyz
        + materials[hit.mat].diffuse.xyz;

    vec3 p2 = mod(p, vec3(1.));
    p2.x += floor(p2.y) * 0.5;

    p2 *= 2.;
    p2 -= 1.;
            
    float acc = 0.;
    
    float a = ANGLE;    
    
    for(int i = 0; i < POINTS; i++)
    {
        vec2 sc = vec2(sin(a), cos(a));
        float test = dot(sc, p2.xy-sc*0.25);
        acc += test > 0. ? 0.5 : 0.;
        a += ANGLE;
    }
    
    hit.mat = (acc < 1.) ?  materials[hit.mat].attrib0 : materials[hit.mat].attrib1;

    return shade_standard(ray, hit);
}

vec4 shade(ray_t ray, hit_t hit)
{
    vec4 color;
    
    if(hit.t != INFINITE)
    {    
        int type = materials[hit.mat].type;

        if(type == STANDARD_MATERIAL)
        {
            color = shade_standard(ray, hit);
        }
        /*else if(type == CHECKER_MATERIAL) 
        {
            color = shade_checker(ray, hit);
        }*/
        else if(type == STARS_MATERIAL)
        {
            color = shade_stars(ray, hit);
        }
        
        // fog
        if(ray.level != 0)
        {
            float f = (hit.t - fogNear) * fogDenom;
            f = clamp(f, 0.0, 1.0);
            color = mix(color, fogColor, f);
        }
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

#pragma unroll 1
    
    for(int i = 0; i < NUM_PRIMS; i++)
    {
        hit_t h;
        int type = prims[i].type;
        bool result = false;
        
        switch(type)
        {
        case PLANE_PRIMITIVE:
            //result = hit_plane(prims[i].v0, prims[i].v1, prims[i].mat, ray, h);
            result = hit_plane(i, ray, h);
            break;
        case SPHERE_PRIMITIVE:
            //result = hit_sphere(prims[i].v0, prims[i].v1.x,  prims[i].mat, ray, h);            
            result = hit_sphere(i, ray, h);
            break;
        /*case RING_PRIMITIVE:
            result = hit_ring(prims[i].v0, prims[i].v1, prims[i].v2.x, prims[i].v2.y, prims[i].mat, ray, h);
            break;*/
        }
        
        if(result && h.t < hit.t)
        {
            hit = h;
            hit.prim = i;
        }
    }    
}

vec4 raytrace(ray_t ray)
{
    hit_t hit;
    
    intersect(ray, hit);
    
    vec4 color = shade(ray, hit);
    color.w = hit.t;
    return color;
}

void main(void)
{
    viewFrom = vec3(sin(time*.5)*14.0, -cos(time*.5)*14.0, 2. + sin(time*1.5)*3.);
    
    
    aspect = resolution.x / resolution.y;
    viewTan = tan(((viewFov/180.0)*PI)/2.0);    
    vec2 uv = gl_FragCoord.xy/resolution.xy * vec2(2,2) - vec2(1,1);
    uv *= viewTan;
    viewDir = normalize(viewAt-viewFrom);
    viewRight = cross(viewDir, viewUp);
    viewUp = cross(viewRight, viewDir);
    
    
    float ovs = float(oversample);
    vec4 color = vec4(0,0,0,0);
    float sx = 1.0 / (ovs * resolution.x);
    float sy = 1.0 / (ovs * resolution.y);       
    
    float fog = 0.;

#pragma unroll 1

    for(int i = 0; i < oversample; i++)
    {
#pragma unroll 1
        
        for(int j = 0; j < oversample; j++)
        {
            ray_t ray = primary_ray(uv.x + float(i) * sx, uv.y + float(j) * sy);
            resetRayQueue();
            enqueueRay(ray);
            
            float t = 0.;
            
            while(dequeueRay(ray))
            {
                vec4 col = raytrace(ray);
                if(ray.level == 0 && (col.w != INFINITE || ray.dir.z*ray.dir.z < EPSILON4))
                {
                    t = col.w;
                    float f = (t - fogNear) * fogDenom;
                    f = clamp(f, 0.0, 1.0);
                    fog += f;
                }
                color += col;
            }
        }
    }
    
    float ovsInv = 1. / (ovs*ovs);
    color *= ovsInv;
    fog *= ovsInv;
    color = (mix(color, horizonColor, fog));
    glFragColor = color;
}
