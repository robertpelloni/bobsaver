#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/tsS3Dw

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float MAX_DIST = 100.0;

mat3 genCamera(vec3 camP, vec3 targetP, float tilt)
{
    vec3 zaxis = normalize(targetP - camP);
    vec3 up = vec3(0, 1, 0);
    vec3 xaxis = normalize(cross(up, zaxis));
    vec3 yaxis = normalize(cross(zaxis, xaxis));
    return mat3(xaxis, yaxis, zaxis);
}

float sphereSdf(vec3 p, float radius)
{
    return length(p) - radius;
}

float worldSdf(vec3 p)
{
    float theta = p.z / 5.0*sin(time);
    mat3 rot = mat3(vec3(cos(theta), sin(theta), 0.0), vec3(-sin(theta), cos(theta), 0.0), vec3(0.0, 0.0, 1.0));
    p = rot*p;
        
    float lowPlane = -5.0;
    float highPlane = 5.0;
    float distToPlane = min(p.y - lowPlane, highPlane - p.y);
    
    return distToPlane;
    //return length(p - vec3(3.0, 0.0, 20.0)) - 1.0;
}

vec3 worldNormal(vec3 p)
{
    float eps = 0.001;
    float dx = (worldSdf(p + vec3(eps, 0, 0)) - worldSdf(p - vec3(eps, 0, 0)));
    float dy = (worldSdf(p + vec3(0, eps, 0)) - worldSdf(p - vec3(0, eps, 0)));
    float dz = (worldSdf(p + vec3(0, 0, eps)) - worldSdf(p - vec3(0, 0, eps)));
    return normalize(vec3(dx, dy, dz));
}

float intersect(vec3 p, vec3 dir)
{
     float t = 0.0;
    while(t < MAX_DIST)
    {
        float dt = worldSdf(p);
        if(dt < 0.001) break;
        p = p + dt*dir;
        t += dt;
    }
    
    return t;
}

float random (vec2 p) {
    return fract(sin(dot(p.xy, vec2(12.9898,78.233)))*43758.5453123);
}

float noise(vec2 p)
{
    vec2 botLeft = floor(p);
    vec2 inside = fract(p);
    
    float a = random(botLeft);
    float b = random(botLeft + vec2(1.0, 0.0));
    float c = random(botLeft + vec2(0.0, 1.0));
    float d = random(botLeft + vec2(1.0, 1.0));
    
    inside = inside * inside * (3.0 - 2.0*inside);
    
    float result = mix(mix(a, b, inside.x), mix(c, d, inside.x), inside.y);
    return result;
}   

// technique from http://www.iquilezles.org
float fbm(vec2 p, float speed)
{
    float amp = 0.5;
    float v = 0.0;
    for(int i = 0; i < 8; i++)
    {
        vec2 off = vec2(0.0, 0.0);
        
        if(int(i) % 2 == 0)
        {
            off = vec2(1.0, 0.0);
        }
        else
        {
            off = vec2(0.0, 1.0);
        }
        
        off = speed * time * float(i) * off;
        
        vec2 np = p + off;
        v += amp*noise(np);
        p *= 2.0;
        amp *= 0.5;
    }
    
    return v;
}

void main(void)
{
    vec2 uv = 2.0*(gl_FragCoord.xy/resolution.xy) - 1.0;
    uv.x *= (resolution.x/resolution.y)/2.0;
    uv.y *= 0.5;
    
    vec3 camP = vec3(0.0, 0.0, 0.0);
    vec3 targetP = camP + vec3(0.0, 0.0, 1.0);
    mat3 cameraSpaceFromUnitSpace = genCamera(camP, targetP, 0.0);
    vec3 ray = normalize(vec3(uv, 4.0));
    float dist = intersect(camP, ray);
    vec3 hit = camP + dist*ray;
    
    if(dist < MAX_DIST) {
        vec3 normal = worldNormal(hit);
        float c = 5.0*dot(normal, -ray);
        vec2 p = 0.25*hit.xy;
        vec2 np = vec2(fbm(p, 1.0), fbm(p + vec2(3.5, 4.67), 1.0));
        vec2 nnp = vec2(fbm(p + 4.0*np, 1.0), fbm(p + 4.0*np + vec2(6.2, 1.6), 1.0));
        float t = fbm(np + 4.0*nnp, 1.0);
        glFragColor = 0.3*c*vec4(0.4, 0.4, 0.0, 1.0) + (hit.z/100.0)*vec4(t, t, 0.0, 1.0);
    } else {
        vec2 p = 1.0*hit.xy;
        vec2 np = vec2(fbm(p, 1.0), fbm(p + vec2(3.5, 4.67), 1.0));
        vec2 nnp = vec2(fbm(p + 4.0*np, 1.0), fbm(p + 4.0*np + vec2(6.2, 1.6), 1.0));
        float t = fbm(np + 4.0*nnp, 1.0);
        glFragColor = vec4(2.0*t, t, 0.0, 1.0);
    }
}
