#version 420

// original https://www.shadertoy.com/view/tdGfWV

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define MAX_MARCH 50.0
#define MIN_DISTANCE 0.00001
#define AMBIENT_LIGHT 0.5
#define MAX_DISTANCE 500.0
#define OCCLUSION_FACTOR 0.75

#define ANGLE1 2.443461
#define ANGLE2 0.7
#define ANGLE3 3.141593
#define SCALE 1.967213
#define OFFSET vec3(1.557378, 3.442622, -6.721312)
#define ITERATION_COUNT 10

struct RayMarchData
{
    vec3 pos;
    float dist;
    vec3 color;
    float marchCnt;
};

void mengerFold(inout vec4 z)
{
    float a = min(z.x - z.y, 0.0);
    z.x -= a;
    z.y += a;
    a = min(z.x - z.z, 0.0);
    z.x -= a;
    z.z += a;
    a = min(z.y - z.z, 0.0);
    z.y -= a;
    z.z += a;
}
void rotX(inout vec3 z, float a)
{
    float s = sin(a), c = cos(a);
    z.yz = vec2(c * z.y + s * z.z, c * z.z - s * z.y);
}
void rotY(inout vec3 z, float a)
{
    float s = sin(a), c = cos(a);
    z.xz = vec2(c * z.x - s * z.z, c * z.z + s * z.x);
}
void rotZ(inout vec3 z, float a)
{
    float s = sin(a), c = cos(a);
    z.xy = vec2(c * z.x + s * z.y, c * z.y - s * z.x);
}
float DE_Cube(vec4 p, vec3 s)
{
    vec3 a = abs(p.xyz) - s;
    return (min(max(max(a.x, a.y), a.z), 0.0) + length(max(a, 0.0))) / p.w;
}

float DistanceEstimator(vec3 q)
{
    vec4 p = vec4(q, 1.0);
    for (int i = 0; i < ITERATION_COUNT; ++i) {
        p.xyz = abs(p.xyz);
        rotZ(p.xyz, ANGLE1);
        mengerFold(p);
        rotX(p.xyz, ANGLE2);
        mengerFold(p);
        rotY(p.xyz, ANGLE3);
        p *= SCALE;
        p.xyz += OFFSET;
    }
    return DE_Cube(p, vec3(6.0));
}

RayMarchData RayMarch(vec3 srcPos, vec3 dir)
{
    RayMarchData rmData;
    rmData.pos = srcPos;
    rmData.dist = 0.0;
    rmData.color = vec3(0.0);
    rmData.marchCnt = 0.0;
    
    while (rmData.marchCnt < MAX_MARCH)
    {
        float d = DistanceEstimator(rmData.pos);
        rmData.dist += d;
        vec3 newPos = srcPos + dir * rmData.dist;
        rmData.pos = newPos;
        if (d < MIN_DISTANCE || rmData.dist > MAX_DISTANCE)
            break;
    }
    
    return rmData;
}

void main(void)
{
    float t = time * 0.5;
    vec2 eps = vec2(MIN_DISTANCE, 0.0);
    vec2 uv = (gl_FragCoord.xy * 2.0 - resolution.xy) / resolution.y;
    vec3 srcPos = vec3(sin(t), -0.75, cos(t)) * -10.0;
    vec3 raydir = normalize(vec3(uv, 2.0));
    rotX(raydir, -0.5);
    rotY(raydir, -t);
    RayMarchData rmData = RayMarch(srcPos, raydir);
    vec3 normal = normalize(vec3(
        DistanceEstimator(rmData.pos - eps.xyy) - DistanceEstimator(rmData.pos + eps.xyy),
        DistanceEstimator(rmData.pos - eps.yxy) - DistanceEstimator(rmData.pos + eps.yxy),
        DistanceEstimator(rmData.pos - eps.yyx) - DistanceEstimator(rmData.pos + eps.yyx)));
    float color = (rmData.dist < MAX_DISTANCE) ?
        dot(raydir, normal) * (1.0 - AMBIENT_LIGHT) + AMBIENT_LIGHT : 0.0;
    color *= (1.0 - rmData.marchCnt / MAX_MARCH) * OCCLUSION_FACTOR + (1.0 - OCCLUSION_FACTOR);

    glFragColor = vec4(color, color, color, 1.0);
}
