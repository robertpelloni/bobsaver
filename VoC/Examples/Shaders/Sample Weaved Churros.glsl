#version 420

// original https://www.shadertoy.com/view/ml2yDD

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
#define float3x3 mat3
#define float4x4 mat4
#define saturate(x) clamp(x,0.,1.)
#define lerp mix
#define CurrentTime (time)
#define sincos(x,s,c) s = sin(x),c = cos(x)
#define mul(x,y) (x*y)
#define atan2 atan
#define fmod mod
#define static
#define MaxDist 100.f
#define SurfaceDist 0.0001f
#define FloatMax 3.402823466e+38f
#define raymarchDepth 200
#define raymarchDistMax 200.f
#define InvPI 0.318309886f
#define PId2 1.57079632f
#define PI 3.141592653f
#define PI2 6.2831853f
#define UpVector float3(0.f, 1.f, 0.f)
#define RightVector float3(1.f, 0.f, 0.f)
#define LookVector float3(0.f, 0.f, 1.f)

float4 hash42(float2 p)
{
    float4 p4 = frac(float4(p.xyxy) * float4(154.1031, 166.1030, 178.0973, 144.1099));
    p4 += dot(p4, p4.wzxy + 17.93);
    return frac((p4.xxyz + p4.yzzw) * p4.zywx);
}

float3x3 viewMatrix(float3 look)
{
    float3 right = normalize(cross(UpVector, look));
    float3 up = cross(look, right);
    return transpose(float3x3(right, up, look));
}

float sdf3dInfCylinder(float3 _point, float4 cylinder, float3 cylinderDirection)
{
    _point -= cylinder.xyz;
    return length(_point - dot(_point, cylinderDirection) * cylinderDirection) - cylinder.w;
}

float sdf3dTorusV(float3 _point, float4 torus, float3 torusPlaneNormal, out float v)
{
    _point -= torus.xyz;
    float projPlaneFactor = dot(_point, torusPlaneNormal);
    float3 projPlane = _point - projPlaneFactor * torusPlaneNormal;
    float projPlaneToTorus = length(projPlane) - torus.w;
    float dist = sqrt(projPlaneToTorus * projPlaneToTorus + projPlaneFactor * projPlaneFactor);
    v = acos(projPlaneToTorus / dist);
    return dist;
}

void swap(inout float a, inout float b)
{
    float tmp = a;
    a = b;
    b = tmp;
}

void swap(inout int a, inout int b)
{
    int tmp = a;
    a = b;
    b = tmp;
}

float2x2 rot2D(float t)
{
    float s, c;
    sincos(-t, s, c);
    return float2x2(c, s, -s, c);
}

float drawLine(float2 uv, int left, int right, out float2 tuv, float t, float py,float sgn)
{
    bool flipX = false;
    if (left == 2)
    {
        swap(left, right);
        uv.x = -uv.x;
        flipX = true;
    }
    
    if (left == 0)
    {
        uv = mul(uv, rot2D(PI / 3.f));
    }
    
    tuv.x = (uv.x + sqrt(3.f) / 2.f) * (1.f / sqrt(3.f));
    tuv.x = frac(flipX ? -tuv.x : tuv.x);
     
    float s = sin(tuv.x * PI);
    py -= s * s * t * sgn;
    
    tuv.y = atan2(py,uv.y);    
    return sdf3dInfCylinder(float3(uv.x, py, uv.y), float4(0.f), float3(1.f, 0.f, 0.f));
}

float drawSmallArc(float2 uv, int left, int right, out float2 tuv, float t, float py, float sgn)
{
    bool flipY = false;
    if (left == 2)
    {
        uv.y = -uv.y;
        flipY = true;
    }

    uv.y -= 1.f;
    
    tuv.x = (atan2(uv.y, uv.x) + PI / 6.f) * (3.f / PI2);
    tuv.x = frac(tuv.x);

    float s = sin(tuv.x * PI), c;
    py -= s * s * t * sgn;
    
    float dist = sdf3dTorusV(float3(uv.x, py, uv.y), float4(0.f,0.f,0.f, 0.5), float3(0.f, 1.f, 0.f), tuv.y);
    tuv.y = flipY ? tuv.y : PI -tuv.y;
    return dist;
}

float drawLargeArc(float2 uv, int left, int right, out float2 tuv, float t, float py, float sgn)
{
    bool flipX = false;
    if (left == 1)
    {
        swap(left, right);
        uv.x = -uv.x;
        flipX = true;
    }
    
    bool flipY = false;
    if (left == 2)
    {
        uv.y = -uv.y;
        flipY = true;
    }
    
    uv -= float2(sqrt(3.f), 3.f) * 0.5;
    
    tuv.x = (atan2(uv.y, uv.x) + PI / 6.f) * (3.f / PI);    
    tuv.x = frac(flipX ? -tuv.x : tuv.x);
    
    float s = sin(tuv.x * PI), c;
    py -= s * s * t * sgn;

    float dist = sdf3dTorusV(float3(uv.x, py, uv.y), float4(0.f,0.f,0.f, 1.5), float3(0.f, 1.f, 0.f), tuv.y);    
    tuv.y = flipY ? tuv.y : PI-tuv.y;    
    return dist;
}

float getPattern(float2 uv, int left, int right, out float2 tuv, float t, float py,float sgn)
{
    if (left + right == 2)
        return drawLine(uv, left, right, tuv, t, py,sgn);
    else if (left - right == 0)
        return drawSmallArc(uv, left, right, tuv, t, py, sgn);
    else
        return drawLargeArc(uv, left, right, tuv, t, py, sgn);
}

float WeavedChurros(float3 p, float thickness, float flow)
{
    const float2 k = float2(1.f, sqrt(3.f));
    
    float2 pk = p.xz / k;
    float2 aIdx = floor(pk);
    float2 a = (pk - aIdx) * k - k * 0.5;
    
    pk = (p.xz - k * 0.5) / k;
    float2 bIdx = floor(pk);
    float2 b = (pk - bIdx) * k - k * 0.5;
    
    float2 hexUv = dot(a, a) < dot(b, b) ? a : b;
    float2 hexIdx = dot(a, a) < dot(b, b) ? aIdx : (bIdx + 0.5);
    float4 rand = hash42(hexIdx);
    
    int rot = int((rand.x + rand.y) * 0.5f * 3.f);
    //hexUv = mul(hexUv, rot2D(PI/3.f * float(rot)));
    
    float hT = thickness * 0.5f;
    float2 tuv, tuvTmp;
    
    int lRemain[3] = int[3]( 0, 1, 2 );
    int rRemain[3] = int[3]( 0, 1, 2 );
    
    int left = int(rand.x * 3.f);
    int right = int(rand.z * 3.f);
    
    hexUv *= k.y;       
    float dist = getPattern(hexUv, lRemain[left], rRemain[right], tuv, thickness, p.y, thickness*2.);
    
    swap(lRemain[left], lRemain[2]);
    swap(rRemain[right], rRemain[2]);
    left = int(rand.y * 2.f);
    right = int(rand.w * 2.f);
    
    float d1 = getPattern(hexUv, lRemain[left], rRemain[right], tuvTmp, thickness, p.y, 0.f);
    if (dist > d1)
    {
        dist = d1;
        tuv = tuvTmp;
    }
        
    float d2 = getPattern(hexUv, lRemain[1 - left], rRemain[1 - right], tuvTmp, thickness, p.y, -thickness*2.);
    if (dist > d2)
    {
        dist = d2;
        tuv = tuvTmp;
    }
    
    float sx = sin(tuv.x* PI2 + flow);
    float sy = sin(tuv.y * 5.+flow*3.f);
    return (dist - hT*0.5 - sy*sy*0.02 - sx*sx*0.08) * 0.5;
}

float GetSignDistance(float3 p)
{
     float cw = lerp(0.1, 0.5, (sin(p.x + sin(p.z)) + sin(p.z * .35)) * .25 + .5);
     cw = 0.4;  
    return WeavedChurros(p, cw, time*2.);
}

float RayMarching(float3 rayOrigin, float3 rayDir)
{
    float dist = 0.f;
    for (int i = 0; i < raymarchDepth; ++i)
    {
        float3 p = rayOrigin + rayDir * dist;
        float curr = GetSignDistance(p);
        
        dist += curr;
        if (curr < SurfaceDist || dist > raymarchDistMax)
        {
            dist = curr < SurfaceDist ? dist : FloatMax;
            break;
        }
    }
    
    return dist;
}

float3 GetSDFNormal(float3 p)
{
    return normalize(float3(+1.f, -1.f, -1.f) * GetSignDistance(p + float3(+1.f, -1.f, -1.f) * SurfaceDist) +
                     float3(-1.f, -1.f, +1.f) * GetSignDistance(p + float3(-1.f, -1.f, +1.f) * SurfaceDist) +
                     float3(-1.f, +1.f, -1.f) * GetSignDistance(p + float3(-1.f, +1.f, -1.f) * SurfaceDist) +
                     float3(+1.f, +1.f, +1.f) * GetSignDistance(p + float3(+1.f, +1.f, +1.f) * SurfaceDist));
}

void main(void)
{
    vec2 uv = (2.0*(gl_FragCoord.xy)-resolution.xy)/resolution.y;

    float3 ro = float3(0.01f, 2.f, -2.f+time*0.5);
    float3 rt = float3(0.01f, 0.f, 0.f + time*0.5);
    float3 rd = mul(transpose(viewMatrix(normalize(rt - ro))), normalize(float3(uv, 1.)));
    
    float t = RayMarching(ro, rd);    
    
    float3 col = float3(0.f);
    
    if(t < FloatMax)
    {
        float3 p = ro + t * rd;
        float3 n = GetSDFNormal(p);

        col = float3((dot(n,normalize(float3(0.f,1.f,-1.f)))));
    }
    
    glFragColor = vec4(col,1.0);
}
