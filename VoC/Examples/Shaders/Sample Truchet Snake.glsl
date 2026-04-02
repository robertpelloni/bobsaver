#version 420

// original https://www.shadertoy.com/view/cll3Dr

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
#define sincos(x,s,c) s = sin(x),c = cos(x)
#define mul(x,y) (x*y)
#define atan2 atan
#define fmod mod

const float InvPI = 0.318309886f;
const float PId2 = 1.57079632f;
const float PI = 3.141592653f;
const float PI2 = 6.2831853f;
const float MaxDist = 100.f;
const float SurfaceDist = 0.0001f;
const float FloatMax = 3.402823466e+38F;

float2 hash(float2 p)
{
    float3 p3 = frac(float3(p.xyx) * float3(145.1031, 161.1030, 158.0973));
    p3 += dot(p3, p3.yzx + 33.33);
    return frac((p3.xx + p3.yz) * p3.zy);
}

float3 hash(float3 p3)
{
    p3 = frac(p3 * float3(155.1031, 132.1030, 144.0973));
    p3 += dot(p3, p3.yxz + 33.33);
    return frac((p3.xxy + p3.yxx) * p3.zyx);
}
float truchet(float2 p, float thickness)
{
    int2 idx = floor(p);
    float2 rand = hash(idx);
    
    p -= 0.5f + idx;
    p.x = rand.x > 0.5f ? p.x : -p.x;    
    p.y = rand.y > 0.5f ? p.y : -p.y;    
    p = p.y > -p.x ? p : -p;
    
    float dist = abs(length(p-0.5)-0.5) - thickness * 0.5;    
    return smoothstep(0.01f, 0.f, dist);
}

float2 truchetUVsym(float2 p, float thickness, float flow)
{
    int2 idx = floor(p);
    float2 rand = hash(idx);
    
    p -= 0.5f + idx;    
    p.x = rand.x > 0.5f ? p.x : -p.x;
    p.y = rand.y > 0.5f ? p.y : -p.y;    
    p = p.y > -p.x ? p : -p;
    
    p -= 0.5;    
    float hT = thickness*0.5;
    float v = clamp(length(p) - 0.5, -hT, hT) + hT;
    v /= thickness;
    v = abs(2.f*v-1.f);

    bool flip = bool((int(idx.x) + int(idx.y)) & 1); 
    float u = atan2(p.y, p.x) + (flip ? flow : -flow);
    u = flip ? -u : u;    

    return float2(frac(u/PI),v);
}

float2 truchetUV(float2 p, float thickness, float flow)
{
    int2 idx = floor(p);
    float2 rand = hash(idx);
    
    p -= 0.5f + idx;    
    bool flipX = rand.x > 0.5f, flipY  = rand.y > 0.5f;   
    p.x = flipX ? p.x : -p.x;
    p.y = flipY ? p.y : -p.y;    
    p = p.y > -p.x ? p : -p;
    
    p -= 0.5;   
    bool flip = bool((int(idx.x) + int(idx.y)) & 1); 
    float u = atan2(p.y, p.x) + (flip ? flow : -flow);
    u = flip ? -u : u;    
    
    float hT = thickness*0.5;
    float v = clamp(length(p) - 0.5, -hT, hT) + hT;
    v /= thickness;
    v = flip ^^ flipX ^^ flipY ? v : 1.f - v;

    return float2(frac(u/PI),v);
}

float minkowskiLength(float2 v, float p)
{
    v = abs(v);
    return pow(pow(v.x,p)+pow(v.y,p), 1.f / p);
}

float minkowskiTruchet(float2 p, float thickness, float k)
{
    int2 idx = floor(p);
    float2 rand = hash(idx);
    
    p -= 0.5f + idx;
    p.x = rand.x > 0.5f ? p.x : -p.x;    
    p.y = rand.y > 0.5f ? p.y : -p.y;    
    p = p.y > -p.x ? p : -p;
    
    float dist = abs(minkowskiLength(p-0.5,k)-0.5) - thickness * 0.5;    
    return smoothstep(0.01f, 0.f, dist);
}

float3 weaveTruchet(float2 p, float thickness, float flow)
{
    int2 idx = floor(p);
    float2 rand = hash(idx);
    
    p -= 0.5f + idx;
    bool flipX = rand.x > 0.5f, flipY  = rand.y > 0.5f;   
    p.x = flipX ? p.x : -p.x;
    p.y = flipY ? p.y : -p.y;    
    p = p.y > -p.x ? p : -p;
    
    p -= 0.5;   
    bool flip = bool((int(idx.x) + int(idx.y)) & 1); 
    float at = atan2(p.y, p.x);
    float u = at + (flip ? flow : -flow);
    at = flip ? -at : at;    
    u = flip ? -u : u;    
    
    float hT = thickness*0.5;
    float l = length(p) - 0.5;
    float v = clamp(l, -hT, hT) + hT;
    v /= thickness;
    v = flip ^^ flipX ^^ flipY ? v : 1.f - v;
    
    return float3(pow(smoothstep(thickness * 0.5,thickness * 0.1, abs(l)),0.45)*pow(cos(at)*0.5 + 0.5,0.78f),frac(u/PI),v);
}

float sdScale(vec2 fuv, vec2 off)
{
    fuv = fuv + off;
    
    fuv.x = (fuv.x - 0.3f)* 0.5 + 0.5f;
    fuv.y *= 0.5;
    fuv.y += 0.4;
    
    return max(length(fuv - vec2(0.5f,0.5f)), length(fuv - vec2(0.85f,0.5f)));
}

float texScales(vec2 uv)
{    
    vec2 fuv = fract(uv);    
    vec2 idx = floor(uv - fuv);
    
    fuv.x = bool(int(idx.y) & 1) ? fract(fuv.x + 0.5) : fuv.x;

    float dist = min(sdScale(fuv, vec2(0.f, 0.f)), sdScale(fuv, vec2(-0.5f,-1.f)));    
    dist = min(dist,sdScale(fuv, vec2(0.5f,-1.f)) );
    dist = min(dist,sdScale(fuv, vec2(1.f,0.f)));
    
    return smoothstep(0.6f,0.f,dist);    
}

float3 tex(float2 uv)
{
    return float3(texScales(uv.yx*float2(4.f,12.f)));
    //return texture(iChannel0, uv).rgb;
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.y *5.+ time;    

    vec3 col = vec3(0.f);
    float3 wt = weaveTruchet(uv, 0.4, time);
    float3 wto = weaveTruchet(uv+0.5, 0.4, time);
    col = tex(wt.yz)*wt.x + tex(wto.yz)*wto.x;

    glFragColor = vec4(col*2.,1.0);
}
