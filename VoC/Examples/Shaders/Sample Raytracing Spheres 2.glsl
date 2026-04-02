#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/XdscDS

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI  3.14159265
#define PI2 6.28318531
#define SIZE 25
#define DELTA PI2/float((SIZE-1)>>1)
#define BACKCOLOR_LOWER vec4(0.1,0.3,0.45,1)
#define BACKCOLOR_UPPER vec4(0,0.025,0.05,1)

vec3 centers[SIZE];
float radii[SIZE];
vec3 albedo[SIZE];
vec3 ambient[SIZE];
vec3 lightDir;

struct ray_hit
{
    int hit_idx;
    float hit_dist;
};

ray_hit raySphereIntersect(in vec3 start, in vec3 direction, in vec3 center, in float radius)
{
    vec3 L = center - start;
    float proj = dot(direction, L);
    if(proj < 0.0) return ray_hit(-1,proj);
    float dis = sqrt(dot(L,L) - proj*proj);
    if(dis > radius) return ray_hit(-1,proj);
    float db = sqrt(radius*radius - dis*dis);
    return ray_hit(0, proj - db);
}

ray_hit sceneIntersect(vec3 start, vec3 direction, int begin, int end, int except)
{
    ray_hit res = ray_hit(-1,1e12);
    for(int i = begin; i < end; i++){
        if(i != except){
            ray_hit ires = raySphereIntersect(start, direction, centers[i], radii[i]);
            if(ires.hit_idx >= 0 && ires.hit_dist < res.hit_dist) res = ray_hit(i, ires.hit_dist);
        }
    }
    return res;
}

vec3 rotfn(float val, float val2)
{
    float cosval = cos(val);
    return normalize(vec3(cos(val2)*cosval,sin(val2)*cosval,sin(val)));
}

vec4 simplephong(vec3 start, vec3 direction, float dist, int idx)
{
    vec3 point = start + dist * direction;
    ray_hit lightRes = sceneIntersect(point, -lightDir, 0, SIZE, idx);
    vec3 normal = normalize(point - centers[idx]);
    float fresnel = 0.2*pow(1.0+dot(direction,normal), 4.0);
    if(lightRes.hit_idx < 0)
    {
        float diffuse = max(dot(-lightDir, normal), 0.0);
        float specular = pow(max(0.0, -dot(direction, reflect(lightDir, normal))), 70.0);
        return vec4((diffuse+fresnel)*albedo[idx] + ambient[idx] + specular*vec3(1,1,1),1);
    }
    else
        return vec4(fresnel*albedo[idx]+ambient[idx],1);
}

vec4 reflectivephong(vec3 start, vec3 direction, float dist, int idx)
{
    vec3 point = start + dist * direction;
    ray_hit lightRes = sceneIntersect(point, -lightDir, 0, SIZE, idx);
    vec3 normal = normalize(point - centers[idx]);
    vec4 reflected = vec4(0,0,0,1);
    vec3 refDir = reflect(direction, normal);
    ray_hit refRes = sceneIntersect(point, refDir, 0, SIZE, idx);
    if(refRes.hit_idx >= 0){
        reflected = simplephong(point, refDir, refRes.hit_dist, refRes.hit_idx);
    } else {
        reflected = mix(BACKCOLOR_LOWER,BACKCOLOR_UPPER,(refDir.y+1.0)/2.0);
    }
    float fresnel = 0.2*pow(1.0+dot(direction,normal), 4.0);
    if(lightRes.hit_idx < 0)
    {
        float diffuse = max(-dot(lightDir, normal), 0.0);
        float specular = pow(max(0.0, -dot(direction, reflect(lightDir, normal))), 70.0);
        return vec4((diffuse+fresnel)*albedo[idx] + ambient[idx] + 0.9*reflected.rgb + specular*vec3(1,1,1),1);
    }
    else
        return vec4(fresnel*albedo[idx]+ambient[idx] + 0.9*reflected.rgb,1);
}

vec3 coord2dir(vec2 coord)
{
    float aspectRatio = resolution.x/resolution.y;
    vec2 uv = coord / resolution.xy;
    uv = (2.0*uv - 1.0)*vec2(aspectRatio,1);
    return normalize(vec3(uv, 1.0));
}

void main(void)
{
    const vec3 start = vec3(0,0,0);
    
    float stime = time/4.0;
    
    lightDir = normalize(vec3(cos(stime),cos(stime),sin(stime)));
    
    const vec3 mainCenter = vec3(0,0,20);
    const float rotationRadius = 12.0;
    const float mainRadius = 10.0;
    const float subRadius = 1.0;
    
    const vec3 albedo1 = vec3(0.6,0.05,0.1);
    const vec3 ambient1 = vec3(0.1,0,0.05);
    const vec3 albedo2 = vec3(0.05,0.6,0.1);
    const vec3 ambient2 = vec3(0,0.1,0.05);
    
    centers[0] = mainCenter;
    radii[0] = mainRadius;
    albedo[0] = vec3(0.6,0.5,0.05);
    ambient[0] = vec3(0.1,0.1,0.05);
    for(int i = 1; i < SIZE/2+1; i++){
        centers[i] = mainCenter - rotationRadius*rotfn(stime+DELTA*float(i), stime+PI/4.0);
        radii[i] = subRadius;
        albedo[i] = albedo1;
        ambient[i] = ambient1;
    }
    for(int i = SIZE/2+1; i < SIZE; i++){
        centers[i] = mainCenter - rotationRadius*rotfn(stime+DELTA*float(i)+ DELTA/2.0, stime-PI/4.0);
        radii[i] = subRadius;
        albedo[i] = albedo2;
        ambient[i] = ambient2;
    }
    
    glFragColor = vec4(0);
    for(int i = -1; i < 2; i++){
        for(int j = -1; j < 2; j++) {
            vec3 direction = coord2dir(gl_FragCoord.xy+vec2(i,j)/2.0);
            ray_hit res = sceneIntersect(start, direction, 0, SIZE, -1);
            if(res.hit_idx == -1) 
                glFragColor += mix(BACKCOLOR_LOWER,BACKCOLOR_UPPER,(direction.y+1.0)/2.0);
            else
                glFragColor += reflectivephong(start, direction, res.hit_dist, res.hit_idx);
        }
    }
    glFragColor /= 9.0;
}
