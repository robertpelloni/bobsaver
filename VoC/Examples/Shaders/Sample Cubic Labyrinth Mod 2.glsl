#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//Copyright (c) 2019-07-13 - 2019-07-17 by Angelo Logahd
//Portfolio: https://angelologahd.wixsite.com/portfolio
//Based on https://www.iquilezles.org/www/articles/menger/menger.htm

//Copyright (c) 2019-07-13 by Angelo Logahd
//http://glslsandbox.com/e#56104.0

#define true                1
#define false                0

#define PI 3.14

#define saturate(x)         clamp(x, 0.0, 1.0)

#define MENGER_ITERATIONS    2
//#define SOFT_SHADOW_STEPS     32
#define SOFT_SHADOW_STEPS     20

#define INTERSECT_STEPS        150

//#define INTERSECT_MIN_DIST    0.002
#define INTERSECT_MIN_DIST    0.0025

//#define INTERSECT_MAX_DIST    20.0
#define INTERSECT_MAX_DIST    10.0

#define MOVING_BRICKS        false

vec2 rotate2D(vec2 p, float angle)
{
    float sRot = sin(angle);
    float cRot = cos(angle);
    return p * cRot + p.yx * sRot * vec2(-1.0, 1.0);
}

float sdUnitBox(vec3 p)
{
    vec3 d = abs(p) - vec3(1.0);
    return min(max(d.x, max(d.y, d.z)), 0.0) + length(max(d, 0.0));
}

vec4 map(in vec3 p)
{    
    //p.xz = mod(p.xz + 1.0, 2.0) -1.0;
    //p.xz = mod(p.xz + 0.5, 2.0) -1.0;
    p.xz = mod(p.xz + 4.0, 2.0) -1.0;
    
    //p.y = mod(p.y + 1.0, 2.0) - 1.0;
    p.y = mod(p.y + 1.0, 2.0) - 1.0;
    //p.y = mod(p.y + 1.0, 2.0) - 1.0;
    
    
    float d = sdUnitBox(p);
    vec4 res = vec4(d, 1.0, 0.01, 0.0);
    
    //float s = 1.5;
    float s = 2.5;
    
    for(int i = 0; i < MENGER_ITERATIONS; ++i)
    {     
        #if MOVING_BRICKS
        p.x += time * 0.05;
        #endif
        
        vec3 a = mod(p * s, 2.0) - 1.0;
        s *= 11.0;
        //vec3 r = abs(1.0 - 4.0 * abs(a));
        vec3 r = abs(1.0 - 5.0 * abs(a));
        
        float da = max(r.x, r.y);
        float db = max(r.y, r.z);
        float dc = max(r.z, r.x);
        float c = (min(da, min(db, dc)) - 0.85) / s;
        

        if(c > d)
        {
            d = c;
            res = vec4(d, min(res.y, 0.2 * da * db * dc), 0.0, 1.0);
        }
    }
    
    return res;
}

vec4 intersect(in vec3 ro, in vec3 rd)
{
    float t = 0.0;
    vec4 res = vec4(-1.0);
    vec4 h = vec4(1.0);
    for (int i = 0; i < INTERSECT_STEPS; ++i)
    {
        if(h.x < INTERSECT_MIN_DIST || t > INTERSECT_MAX_DIST) 
        {
            break;
        }
    
        h = map(ro + rd * t);
        res = vec4(t, h.yzw);
        t += h.x;
    }

    if (t > INTERSECT_MAX_DIST) 
    {
        res = vec4(-1.0);
    }
    
    return res;
}

float softshadow(in vec3 ro, in vec3 rd)
{
    float res = 1.0;
    float t = 0.0;
    for (int i = 0; i < SOFT_SHADOW_STEPS; ++i)
    {
        vec3 pos = ro + rd * t;
        float h = map(pos).x;
        res = min(res, float(SOFT_SHADOW_STEPS) * h / t);
        if(res < 0.101)
        {
            break;
        }
        t += clamp(h, 0.01, 0.05);
    }
    return saturate(res);
}

vec3 calcNormal(in vec3 pos)
{
    //vec3 eps = vec3(0.001, 0.0, 0.0);
    vec3 eps = vec3(0.001, 0.0, 0.0);
    
    
    vec3 n;
    n.x = map(pos + eps.xyy).x - map(pos - eps.xyy).x;
    n.y = map(pos + eps.yxy).x - map(pos - eps.yxy).x;
    n.z = map(pos + eps.yyx).x - map(pos - eps.yyx).x;
    return normalize(n);
}

vec3 render(in vec3 ro, in vec3 rd, float intensity)
{
    vec3 color = vec3(0.5);
    vec4 res = intersect(ro,rd);
    if(res.x > 0.0)
    {
        const vec3 light1 = vec3(0.5, 0.8, 0.5);
        
        vec3 pos = ro + res.x * rd;
    
        //vec3 baseColor = vec3(saturate(sin(time * 0.5)), saturate(cos(time * 0.3)), saturate(sin(time * 0.4)));
        //vec3 baseColor = vec3(saturate( 0.9), saturate( 0.3), saturate( 0.7));
        vec3 baseColor = vec3( 0.9,  0.3,  0.7);
        
        
        vec3 ambient = vec3(0.3) * baseColor;
        
        vec3 normal = calcNormal(pos);
        vec3 reflection = reflect(rd, normal);
        
    
        float occ = res.y;
        //float shadow1 = softshadow(pos + 0.001 * normal, light1);
        float shadow1 = softshadow(pos + 0.0005 * normal, light1);
    
        vec3 diffuse = baseColor * shadow1 * occ;
        
        color = diffuse + ambient;        
        color += 0.8 * smoothstep(0.0, 0.5, reflection.y) * softshadow(pos + 0.01 * normal, reflection);
    }

    return pow(color * intensity, vec3(0.4545));
}

void main(void)
{
    vec2 p = 2.0 * (gl_FragCoord.xy / resolution.xy) - 1.0;
    p.x *= resolution.x / resolution.y;
    
    // camera
    vec3 ro = vec3(8.75, 2.9, -0.0);
    #if !MOVING_BRICKS
       ro.x -= 0.1 * time;
    #endif
    vec3 ww = normalize(vec3(0.0) - ro);
    //ww.xz = rotate2D(ww.xz, mouse*resolution.xy.x * 2.0 * PI);
    vec3 uu = normalize(cross(vec3(0.0, 1.0, 0.0), ww));
    vec3 vv = normalize(cross(ww, uu));
    vec3 rd = normalize(p.x * uu + p.y * vv + 2.0 * ww);

    //vec3 color = render(ro + vec3(0.0, -1.0, 0.0), rd, 1.0);
    vec3 color = render(ro + vec3(0.0, -1.0, 0.0), rd, 0.50);
    
    glFragColor = vec4(color, 1.0);
}
