#version 420

// original https://www.shadertoy.com/view/sdlBW2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define int2 vec2
#define float2 vec2
#define int3 vec3
#define float3 vec3
#define int4 vec4
#define float4 vec4
#define frac fract
#define float2x2 mat2
#define saturate(x) clamp(x,0.,1.)
#define lerp mix
#define CurrentTime (time*0.3)

const float MaxDist = 100.f;
const float SurfaceDist = 0.0001f;
const float PI = 3.141592653f;
const float PI2 = 6.2831853f;

float2 hash(float2 p)
{
    p = float2(dot(p, float2(127.1f, 311.7f)), dot(p, float2(269.5f, 183.3f)));
    return 2.f * frac(sin(p) * 43758.5453123f) - 1.f;
}

float3 hash(float3 p)
{
    p = float3(dot(p, float3(127.1f, 311.7f, 74.7f)), dot(p, float3(269.5f, 183.3f, 246.1f)), dot(p, float3(113.5f, 271.9f, 124.6f)));
    return 2.f * frac(sin(p) * 43758.5453123) - 1.f;
}

float sdf3dInfPlane(float3 _point, float3 plane, float3 planeNormal)
{
    return dot((_point - plane), planeNormal);
}

float kaleidoscopeTunnel(float3 ray)
{
    float dist = sdf3dInfPlane(ray, float3(0.f, 0.f, 0.f), float3(0.f, 1.f, 0.f));
    dist = min(dist, sdf3dInfPlane(ray, float3(4.f, 4.f, 0.f), float3(-sin(PI2 / 3.f), cos(PI2 / 3.f), 0.f)));
    dist = min(dist, sdf3dInfPlane(ray, float3(-4.f, 4.f, 0.f), float3(cos(-PI / 6.f), sin(-PI / 6.f), 0.f)));
    
    return dist;
}

float2 minX(float2 a, float2 b)
{
    return a.x < b.x ? a : b;
}

float2 GetDist(float3 ray)
{
    float2 minDist = float2(kaleidoscopeTunnel(ray), 0.f);
    minDist = minX(minDist, float2(sdf3dInfPlane(ray, float3(0.f, 0.f, CurrentTime + 10.f), float3(0.f, 0.f, -1.f)), 1.f));
    
    return minDist;
}

float2 RayMarching(float3 origin, float3 dir)
{
    float hitDist = 0.f;
    float mat = 0.f;
    for (int i = 0; i < 100; ++i)
    {
        float3 ray = origin + hitDist * dir;
        float2 curr = GetDist(ray);
        if (hitDist > MaxDist || curr.x < SurfaceDist)
            break;
        hitDist += curr.x;
        mat = curr.y;
    }
    
    return float2(hitDist,mat);
}

float3 GetNormal(float3 ray)
{
    float2 k = float2(1.f, -1.f);
      
    return normalize(k.xyy * GetDist(ray + k.xyy * SurfaceDist).x +
                     k.yyx * GetDist(ray + k.yyx * SurfaceDist).x +
                     k.yxy * GetDist(ray + k.yxy * SurfaceDist).x +
                     k.xxx * GetDist(ray + k.xxx * SurfaceDist).x);
}

float2 kaleidoReflect(inout float3 rayPoint, float3 normal, float3 rayDir)
{
    float3 rfl = reflect(rayDir, normal);
    float2 curr = RayMarching(rayPoint + rfl * 0.1f, rfl);
    rayPoint = rayPoint + rfl * curr.x;
    normal = GetNormal(rayPoint);
    
    int reflectCnt = 1;
    for (; reflectCnt < min(14,int(time*3.0)) && curr.y == 0.f; ++reflectCnt)
    {
        rfl = reflect(rfl, normal);
        curr = RayMarching(rayPoint + rfl * 0.1f, rfl);
        rayPoint = rayPoint + rfl * curr.x;
        normal = GetNormal(rayPoint);
    }
    
    rayDir = rfl;
    return curr;
}

float simplexNoise(float3 p)
{
    const float k1 = 0.333333f;
    const float k2 = 0.166667f;
    
    int3 idx = floor(p + (p.x + p.y + p.z) * k1);
    float3 a = p - (float3(idx) - float(idx.x + idx.y + idx.z) * k2);
    
    const int3 tb1Arr[8] =
    vec3[8]( int3(0, 0, 1), int3(0, 1, 0), int3 (0), int3(0, 1, 0), int3(0, 0, 1), int3 (0), int3(1, 0, 0), int3(1, 0, 0) );
    const int3 tb2Arr[8] =
    vec3[8]( int3(0, 1, 1), int3(0, 1, 1), int3 (0), int3(1, 1, 0), int3(1, 0, 1), int3( 0), int3(1, 0, 1), int3(1, 1, 0) );
    
    uint tbIdx = (uint(a.x > a.y) << 2) | (uint(a.x > a.z) << 1) | uint(a.y > a.z);
    
    int3 tb1 = tb1Arr[tbIdx], tb2 = tb2Arr[tbIdx];
    
    float3 b = a - tb1 + k2;
    float3 c = a - tb2 + k2 * vec3(2.f);
    float3 d = a - vec3(1) + k2 * vec3(3.f);
    
    float4 kernel = max(0.5f - float4(dot(a, a), dot(b, b), dot(c, c), dot(d, d)), 0.f);
    kernel *= kernel;
    kernel *= kernel;
    float4 noise = kernel * float4(dot(a, hash(idx)), dot(b, hash(idx + tb1)), dot(c, hash(idx + tb2)), dot(d, hash(idx + vec3(1))));
    
    return dot(vec4(52.f), noise);
}

float3 kaleidoColor(float3 p)
{
    p.y -= 4.f;
    float2 v = lerp(hash(floor(p.zz)), hash(floor(p.zz + vec2(1))), frac(p.z));
    
    p.xy *= v * 4.f;
    p.x *= sin(p.x);
    p.y *= cos(p.y);
    float s, c;
    //sincos(p.z, s, c);
    s = sin(p.z);
    c = cos(p.z);
    float2x2 rot = float2x2(s, c, -s, c);
    
    //[unroll]
    for (int i = 0; i < 3; ++i)
    {
        p.yz = p.xy* rot;
        p[i] = simplexNoise(p * v.xyx);
        p *= length(p.xy);
    }
    
    return abs(p);
}

void main(void)
{
   vec2 uv = 2.f*(gl_FragCoord.xy/resolution.xy)-1.f;
   uv.x *= resolution.x/resolution.y;

    float3 rayOrigin = float3(0.f, 8.f, CurrentTime - 20.f);
    float3 rayDir = normalize(float3(uv, 1.f));
    
    float2 march = RayMarching(rayOrigin, rayDir);
    float3 rayPoint = rayOrigin + rayDir * march.x;
    float3 normal = GetNormal(rayPoint);
    
    if(march.y == 0.f)
        march = kaleidoReflect(rayPoint, normal, rayDir);
    
    glFragColor = float4(vec3(0.f), 1.f);
    if(march.y == 1.f)
    glFragColor.rgb = kaleidoColor(rayPoint);
}
