#version 420

// original https://www.shadertoy.com/view/ddsyzS

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float M_PI = 3.14159265358979323846264338327950288;
const float M_PI_T2 = M_PI * 2.0;
const float M_PI_2 = 1.57079632679489661923132169163975144;
const vec3 LIGHT = normalize(vec3(1.0));

float sqr(float x) { return x * x; }

vec3 point_on_curve(float t, float phase, float stretch)
{
    float sn = sin(t + phase);
    float cs = cos(t + phase);
    return vec3(cs, t * stretch, sn * cs);
}

float dist_to_point_on_curve(vec3 p, float t, float phase, float stretch)
{
    return length(point_on_curve(t, phase, stretch) - p);
}

float dist_to_point_on_curve_dt(vec3 p, float t, float phase, float stretch)
{
    float sn = sin(t + phase);
    float cs = cos(t + phase);
    return 2.0 * (sn * (p.x - cs) + (sqr(sn) - sqr(cs)) * (p.z - sn * cs) - stretch * (p.y - stretch * t));
}

float nearest_point_on_curve(vec3 p, float phase, float stretch)
{
    float t = p.y / stretch;
    for (int i = 0; i < 16;i++)
    {
        float dt = dist_to_point_on_curve_dt(p, t, phase, stretch);
        t -= dt * 0.1;
    }
    return t;
}

float dist_to_curve(vec3 p, float phase, float stretch)
{
    float t = nearest_point_on_curve(p, phase, stretch);
    return dist_to_point_on_curve(p, t, phase, stretch);
}

float approximate_curve_length(float t, float phase, float stretch)
{
    return t * (pow(stretch * 2.2, 1.8) + 9.9)/10.0 - sin((t + phase) * 2.0) * 0.1 * ((0.95 - cos(2.0 * (t + phase))) * 0.83) + sin(phase * 2.0) * 0.095;
}

vec3 curve_transform(vec3 p, float phase, float stretch, float radius, float target_radius)
{
    float t = nearest_point_on_curve(p, phase, stretch);
    float l = approximate_curve_length(t, phase, stretch);
    vec3 pp = point_on_curve(t, phase, stretch);
    
    float sn = sin(t + phase);
    float cs = cos(t + phase);
    
    vec3 ny = normalize(vec3(-sn, stretch, cs * cs - sn * sn));
    vec3 nz = normalize(vec3(0.0, 0.0, 1.0));
    vec3 nx = normalize(cross(ny, nz));
    nz = normalize(cross(nx, ny));
    
    float scale = (1.0 + target_radius) / radius;
    return vec3(dot(p - pp, nx), l, dot(p - pp, nz)) * scale;
}

float sd_curve(vec3 p, float phase, float stretch, float radius)
{
    return (dist_to_curve(p, phase, stretch) - radius) * 0.5;
}

vec4 op(vec4 a, vec4 b)
{
    return a.w < b.w ? a : b;
}

vec2 uv = vec2(0.0);

vec4 map(vec3 p)
{
    p.xyz = p.yxz;
    float a = time * 0.9;
    vec4 res = vec4(0.0, 0.0, 0.0, 1000.0);
    
    float stretch = 1.5;
    
    for (int i = 0; i < 3; i++)
    {
        vec3 pp = curve_transform(p, M_PI * 4.0 / 3.0 * float(i), stretch, 0.45, 0.55);
        
        if (length(vec2(pp.x, pp.z)) > 2.0)
        {
            res = op(res, vec4(vec3(0.0), length(vec2(pp.x, pp.z)) - 0.0));
            continue;
        }
        
        float f = (sqr(sin(time + float(i) * 3.14 / 3.0)) + time) * 0.8;
        for (int j = 0; j < 3; j++)
        {            
            vec3 ppp = curve_transform(pp, M_PI * 4.0 / 3.0 * float(j) + f, stretch, 0.55, 0.55);
            
            if (length(vec2(ppp.x, ppp.z)) > 2.0)
            {
                res = op(res, vec4(vec3(0.0), length(vec2(ppp.x, ppp.z)) - 0.0));
                continue;
            }
            
            for (int k = 0; k < 3; k++)
            {
                vec3 pppp = curve_transform(ppp, M_PI * 4.0 / 3.0 * float(k) + f / 0.2, stretch, 0.55, 0.3);
                vec3 col = vec3(0.5 + float(i) * 0.1, 0.8 + float(j) * 0.07, 0.4 + float(k) * 0.1);
                float index = float(i * 9 + j * 3 + k);
                float t1 = (sin(time / 32.0) * 0.5 + 0.5) * 27.0;
                float t2 = (sin(time / 32.0 + 16.0) * 0.5 + 0.5) * 27.0;
                col = mix(vec3(0.4, 1.1, 1.8), col, clamp(sqr(index - t1), 0.0, 1.0));
                col = mix(vec3(1.9, 0.99, 0.5), col, clamp(sqr(index - t2), 0.0, 1.0));
                res = op(res, vec4(col, (length(vec2(pppp.x, pppp.z)) - 0.9)));
            }
        }
    }
    
    res.w *= 0.03;
    return res;
}

vec4 trace(vec3 origin, vec3 dir)
{
    float t = 0.0;
    for (int i = 0; i < 80; i++)
    {
        vec4 h = map(origin);
        origin += dir * h.w;
        t += h.w;
        if (h.w < 0.01) return vec4(h.rgb, t);
        if (origin.z < -50.0) break;
    }

    return vec4(-1.0);
}

// https://iquilezles.org/articles/normalsSDF
vec3 calcNormal( in vec3 pos )
{
    vec2 e = vec2(1.0,-1.0)*0.5773*0.02;
    return normalize(e.xyy*map(pos + e.xyy).w +
                     e.yyx*map(pos + e.yyx).w +
                     e.yxy*map(pos + e.yxy).w +
                     e.xxx*map(pos + e.xxx).w);   
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    uv = gl_FragCoord.xy/resolution.xy;
    vec2 ratio = resolution.xy / resolution.y;
    
    vec3 dir = normalize(vec3((uv - 0.5) * ratio, -1.0));
    vec3 origin = vec3(0.0 + time * 0.1, 0.0, 4.0);
    
    vec4 res = trace(origin, dir);
    if (res.w > 0.0)
    {
        vec3 n = calcNormal(origin + res.w * dir);
        float l = clamp(dot(LIGHT, n), 0.0, 1.0) * 0.8 + 0.2;
        glFragColor = vec4(res.rgb * l,1.0);
        return;
    }

    glFragColor = vec4(vec3(0.0),1.0);
}
