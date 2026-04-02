#version 420

// original https://www.shadertoy.com/view/slXfWX

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.1415926535
#define TAU 2.0 * PI
#define E 2.718281828459045235360

#define EPSILON 0.001
#define MAX_STEPS 1000
#define MAX_DISTANCE 1000.0

//////////////////////////
#define MAX_REFLECTIONS 10
#define LIGHT vec3(10.0, 10.0, 10.0) * vec3(cos(time), 1, sin(time))

#define ZOOM 1.0
//////////////////////////

mat2 Rot(float a)
{
    float s = sin(a);
    float c = cos(a);
    return mat2(c, -s, s, c);
}

float Hash21(vec2 p) {
    p = fract(p*vec2(123.34, 456.21));
    p += dot(p, p+45.32);
    return fract(p.x*p.y);
}

vec3 Hash21Color(vec2 p)
{
    float r = Hash21(p);
    float g = Hash21(p * 123.456);
    float b = Hash21((p - 789.012) / 345.678);

    return vec3(r,g,b);
}

float sdGrid(vec3 p)
{
    float plane = p.y;
    plane += 0.025 * smoothstep(0.05, 0.0, abs(p.x - round(p.x)));
    plane += 0.025 * smoothstep(0.05, 0.0, abs(p.z - round(p.z)));

    return plane;
}

float sdSpheres(vec3 p)
{
    float off = /*TAU * */Hash21(round(p.xz));
    float sphereY = 0.2 * sin(time + off) + 1.0/* + off*/;
    vec3 pos = vec3(0,sphereY,0);
    p.xz = mod(p.xz, 2.0) - 1.0;
    
    return length(p - pos) - 0.4;
}

float GetDist(vec3 p)
{
    float grid = sdGrid(p);
    float spheres = sdSpheres(p);

    return min(grid, spheres);
}

vec3 GetNormal(vec3 p)
{
    float d = GetDist(p);
    vec2 e = vec2(EPSILON, 0);
    
    return normalize(d - vec3(GetDist(p - e.xyy),
                              GetDist(p - e.yxy),
                              GetDist(p - e.yyx)));
}

float GetLight(vec3 p, vec3 n)
{
    vec3 l = normalize(LIGHT - p);
    float diff = max(0.0, dot(n, l));

    return diff;
}

float RayMarch(vec3 ro, vec3 rd, float side)
{
    float dO = 0.0;
    
    for (int i = 0; i < MAX_STEPS; i++)
    {
        vec3 p = ro + rd * dO;
        float dS = side * GetDist(p);
        if (abs(dS) <= EPSILON || dO > MAX_DISTANCE) break;
        dO += dS;
    }
    
    return dO;
}

vec3 offset(vec3 n)
{
    return EPSILON * 2.0 * n;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy - resolution.xy * 0.5) / min(resolution.x, resolution.y);
    vec2 mouse;

    if (mouse*resolution.xy.x == 0.0 && mouse*resolution.xy.y == 0.0)
        mouse = vec2(0,0);
    else
        mouse = mouse*resolution.xy.xy / resolution.xy - 0.5;

    float yaw = mouse.x * TAU;
    float pitch = mouse.y * PI;
    vec4 cs = vec4(cos(yaw), sin(yaw), cos(pitch), sin(pitch));

    vec3 ro = vec3(0, 1, 0);
    vec3 lookAt = ro + cs.xwy * vec3(cs.z, 1, cs.z),
         f = normalize(lookAt - ro),
         r = normalize(cross(f, vec3(0,1,0))),
         u = cross(r, f),
         c = ro + f * ZOOM,
         i = c + uv.x * r + uv.y * u,
         rd = normalize(i - ro);

    vec3 col = vec3(0);
    vec3 n = vec3(0);  // vec3(0) so that the first offset is vec3(0) as well
    vec3 reflOri = ro;
    vec3 reflDir = rd;
    
    for (int r = 0; r <= MAX_REFLECTIONS; r++)
    {
        vec3 off = offset(n);
        reflOri += off;

        float d = RayMarch(reflOri, reflDir, 1.0);
        reflOri += reflDir * d;
        vec3 spec = vec3(0);

        if (sdGrid(reflOri) <= EPSILON)
            spec += mod(floor(reflOri.x) + floor(reflOri.z), 2.0);
        else if (sdSpheres(reflOri) <= EPSILON)
            spec += Hash21Color(round(reflOri.xz));
        else
            break;

        n = GetNormal(reflOri);
        float diff = GetLight(reflOri, n);
        spec += smoothstep(0.975, 1.0, diff);

        col += diff * spec * pow(0.4, float(r));
        //col += diff * spec / float(r + 1);

        // For the next iteration
        reflDir = reflect(reflDir, n);
    }
    
    glFragColor = vec4(col, 1.0);
}
