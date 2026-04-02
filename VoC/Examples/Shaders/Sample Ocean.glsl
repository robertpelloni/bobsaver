#version 420

// original https://www.shadertoy.com/view/lsXcz8

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Created by Pheema - 2017
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

#define M_PI (3.14159265358979)
#define GRAVITY (9.80665)
#define EPS (1e-3)
#define USE_ROUGHNESS_TEXTURE
#define WAVENUM (32)

const float kSensorWidth = 36e-3;
const float kSensorDist = 18e-3;

const vec2 wind = vec2(0.0, 1.0);
const float kOceanScale = 10.0;

struct Ray
{
    vec3 o;
    vec3 dir;
};

struct HitInfo
{
    vec3 pos;
    vec3 normal;
    float dist;
    Ray ray;
};

float rand(vec2 n) { 
    return fract(sin(dot(n, vec2(12.9898, 4.1414))) * 43758.5453);
}

float rand(vec3 n)
{
    return fract(sin(dot(n, vec3(12.9898, 4.1414, 5.87924))) * 43758.5453);
}

float Noise2D(vec2 p)
{
    vec2 e = vec2(0.0, 1.0);
    vec2 mn = floor(p);
    vec2 xy = fract(p);
    
    float val = mix(
        mix(rand(mn + e.xx), rand(mn + e.yx), xy.x),
        mix(rand(mn + e.xy), rand(mn + e.yy), xy.x),
        xy.y
    );  
    
    val = val * val * (3.0 - 2.0 * val);
    return val;
}

float Noise3D(vec3 p)
{
    vec2 e = vec2(0.0, 1.0);
    vec3 i = floor(p);
    vec3 f = fract(p);
    
    float x0 = mix(rand(i + e.xxx), rand(i + e.yxx), f.x);
    float x1 = mix(rand(i + e.xyx), rand(i + e.yyx), f.x);
    float x2 = mix(rand(i + e.xxy), rand(i + e.yxy), f.x);
    float x3 = mix(rand(i + e.xyy), rand(i + e.yyy), f.x);
    
    float y0 = mix(x0, x1, f.y);
    float y1 = mix(x2, x3, f.y);
    
    float val = mix(y0, y1, f.z);
    
    val = val * val * (3.0 - 2.0 * val);
    return val;
}

float SmoothNoise(vec3 p)
{
    float amp = 1.0;
    float freq = 1.0;
    float val = 0.0;
    
    for (int i = 0; i < 4; i++)
    {   
        amp *= 0.5;
        val += amp * Noise3D(freq * p - float(i) * 11.7179);
        freq *= 2.0;
    }
    
    return val;
}

float Pow5(float x)
{
    return (x * x) * (x * x) * x;
}

// Schlick approx
// Ref: https://en.wikipedia.org/wiki/Schlick's_approximation
float FTerm(float LDotH, float f0)
{
    return f0 + (1.0 - f0) * Pow5(1.0 - LDotH);
}

float OceanHeight(vec2 p)
{    
    float height = 0.0;
    vec2 grad = vec2(0.0, 0.0);
    float t = time;

    float windNorm = length(wind);
    float windDir = atan(wind.y, wind.x);

    for (int i = 1; i < WAVENUM; i++)
    {   
        float rndPhi = windDir + asin(2.0 * rand(vec2(0.141 * float(i), 0.1981)) - 1.0);
        // float kNorm = 2.0 * M_PI * (rand(vec2(0.81765 * float(i), 0.873)) * float(WAVENUM)) / kOceanScale;
        float kNorm = 2.0 * M_PI * float(i) / kOceanScale;
        vec2 kDir = vec2(cos(rndPhi), sin(rndPhi)); 
        vec2 k = kNorm * kDir;
        float l = (windNorm * windNorm) / GRAVITY;
        float amp = exp(-0.5 / (kNorm * kNorm * l * l)) / (kNorm * kNorm);
        float omega = sqrt(GRAVITY * kNorm + 0.01 * sin(p.x));
        float phi = 2.0 * M_PI * rand(vec2(0.6814 * float(i), 0.7315));

        vec2 p2 = p;
        p2 -= amp * k * cos(dot(k, p2) - omega * t + phi);
        height += amp * sin(dot(k, p2) - omega * t + phi);
    }
    // return PNoise(p - t);
    return height;
}

vec3 OceanNormal(vec2 p, vec3 camPos)
{
    vec2 e = vec2(0, 1.0 * EPS);
    float l = 20.0 * distance(vec3(p.x, 0.0, p.y), camPos);
    e.y *= l;
    
    float hx = OceanHeight(p + e.yx) - OceanHeight(p - e.yx);
    float hz = OceanHeight(p + e.xy) - OceanHeight(p - e.xy);
    return normalize(vec3(-hx, 2.0 * e.y, -hz));
}

bool RayMarchOcean(Ray ray, out HitInfo hit) {
    vec3 rayPos = ray.o;
    float dl = rayPos.y / abs(ray.dir.y);
    rayPos += ray.dir * dl;
    hit.pos = rayPos;
    hit.normal = OceanNormal(rayPos.xz, ray.o);
    hit.dist = length(rayPos - ray.o);
    return true;
}

#define CLOUD_ITER (16)
vec3 RayMarchCloud(Ray ray, vec3 sunDir, vec3 bgColor)
{
    float cloudHeight = 50.0;
    
    vec3 rayPos = ray.o;
    rayPos += ray.dir * (cloudHeight - rayPos.y) / ray.dir.y;
    
    float c = clamp(dot(sunDir, -ray.dir), 0.0, 1.0);
    
    float dl = 1.0;
    float scatter = 0.0;
    vec3 t = bgColor;
    for(int i = 0; i < CLOUD_ITER; i++) {
        rayPos += dl * ray.dir;
        float dens = SmoothNoise(vec3(0.05, 0.001 - 0.001 * time, 0.1) * rayPos - vec3(0,0, 0.2 * time)) * 
            SmoothNoise(vec3(0.01, 0.01, 0.01) * rayPos);
        t -= 0.01 * t * dens * dl;
        t += 0.02 * dens * dl;
    }
    return t;
}

vec3 BGColor(vec3 dir, vec3 sunDir) {
    vec3 color = vec3(0);
    
    color += mix(
        vec3(0.094, 0.2266, 0.3711),
        vec3(0.988, 0.6953, 0.3805),
           clamp(0.0, 1.0, dot(sunDir, dir) * dot(sunDir, dir)) * smoothstep(-0.1, 0.1, sunDir.y)
    );
    
    dir.x += 0.01 * sin(312.47 * dir.y + time) * exp(-40.0 * dir.y);
    dir = normalize(dir);
    
    color += smoothstep(0.995, 1.0, dot(sunDir, dir)); 
    return color;
}

void main(void)
{
    vec2 uv = ( gl_FragCoord.xy / resolution.xy ) * 2.0 - 1.0;
    float aspect = resolution.y / resolution.x;
    
    // Camera settings
    vec3 camPos = vec3(0, 1.0, -10.0 * time);
    vec3 camDir = vec3(0.002 * (rand(vec2(time, 0.0)) - 0.5), 0.002 * (rand(vec2(time, 0.1)) - 0.5), -1);
    vec3 camTarget = vec3(camPos + camDir);
    
    vec3 up = vec3(0.2 * (SmoothNoise(vec3(0.2 * time, 0.0, 0.0)) - 0.5), 1.0, 0.0);
    
    vec3 camForward = normalize(camTarget - camPos);
    vec3 camRight = cross(camForward, up);
    vec3 camUp = cross(camRight, camForward);
    
    Ray ray;
    ray.o = camPos;
    ray.dir = normalize(
        kSensorDist * camForward + 
        kSensorWidth * 0.5 * uv.x * camRight + 
        kSensorWidth * 0.5 * aspect * uv.y * camUp
    );
    
    vec3 lightPos = normalize(vec3(0, 0.1, -1));
    
    float mouseY = 0.0;//mouse*resolution.xy.y;
    if (mouseY <= 0.0) mouseY = 0.5 * resolution.y;
    vec3 sunDir = normalize(vec3(0, -0.1 + 0.3 * mouseY / resolution.y, -1));
    
    
    vec3 color = vec3(0);
    HitInfo hit;
    float l = 1.0;
    if (ray.dir.y < 0.0 && RayMarchOcean(ray, hit)) {
        vec3 baseColor = vec3(0.0, 0.2648, 0.4421) * dot(-ray.dir, vec3(0, 1, 0));
        
        vec3 refDir = reflect(ray.dir, hit.normal);
        refDir.y = abs(refDir.y);
        l = (0.0 - camPos.y) / ray.dir.y;
        float roughness = clamp(0.0, 1.0, 1.0 - 1.0 / (0.1 * l));
        color = baseColor + BGColor(refDir, sunDir) * FTerm(dot(refDir, hit.normal), 0.5);
    } else {
        vec3 bgColor = BGColor(ray.dir, sunDir);
        if (ray.dir.y > 0.0)
        {
            color += RayMarchCloud(ray, sunDir, bgColor);
        }
        l = (100.0 - camPos.y) / ray.dir.y;
    }
    
    color = mix(color, BGColor(ray.dir, sunDir), 1.0 - exp(-0.0001 * l));
    color = smoothstep(0.2, 0.9, color);
    glFragColor = vec4(color, 1.0);
}
