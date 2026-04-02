#version 420

// original https://www.shadertoy.com/view/WtfSzB

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//Copyright (c) 2019-07-13 - 2019-07-17 by Angelo Logahd
//Portfolio: https://angelologahd.wixsite.com/portfolio
//Based on https://www.iquilezles.org/www/articles/menger/menger.htm

//Copyright (c) 2019-07-13 - 2019-07-16 by Angelo Logahd
//My orginal version:
//http://glslsandbox.com/e#56191.0

#define saturate(x)         clamp(x, 0.0, 1.0)

#define MENGER_ITERATIONS    3
#define SOFT_SHADOW_STEPS     32

#define INTERSECT_STEPS        64
#define INTERSECT_MIN_DIST    0.002
#define INTERSECT_MAX_DIST    20.0

float smin(float a, float b, float k)
{
    float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
    return mix(b, a, h) - k * h * (1.0 - h);
}

vec2 rotate2D(vec2 p, float angle)
{
    float sRot = sin(angle);
    float cRot = cos(angle);
    return p * cRot + p.yx * sRot * vec2(-1.0, 1.0);
}

float sdEllipsoid(in vec3 p, in vec3 r)
{
    float k0 = length(p / r);
    return k0 * (k0 - 1.0) / length(p / (r * r));
}

float sdUnitBox(vec3 p)
{
    vec3 d = abs(p) - vec3(1.0);
    return min(max(d.x, max(d.y, d.z)), 0.0) + length(max(d, 0.0));
}

vec4 map(in vec3 p)
{    
    p.xz = mod(p.xz + 1.0, 2.0) -1.0;
    p.y = mod(p.y + 1.0, 1.0) - 1.0;
    
    float d = sdUnitBox(p);
    vec4 res = vec4(d, 1.0, 0.0, 0.0);
    
    float s = 1.5;
    for(int i = 0; i < MENGER_ITERATIONS; ++i)
    { 
        vec3 a = mod(p * s, 2.0) - 1.0;
        s *= 11.0;
        vec3 r = abs(1.0 - 4.0 * abs(a));
        float da = max(r.x, r.y);
        float db = max(r.y, r.z);
        float dc = max(r.z, r.x);
        float c = (min(da, min(db, dc)) - 0.5) / s;

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
    for (int i = 0; i < INTERSECT_STEPS; i++ )
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
        t += clamp(h, 0.01, 0.2);
    }
    return saturate(res);
}

vec3 calcNormal(in vec3 pos)
{
    vec3 eps = vec3(0.001, 0.0, 0.0);
    vec3 n;
    n.x = map(pos + eps.xyy).x - map(pos - eps.xyy).x;
    n.y = map(pos + eps.yxy).x - map(pos - eps.yxy).x;
    n.z = map(pos + eps.yyx).x - map(pos - eps.yyx).x;
    return normalize(n);
}

float fishAngle = 0.0;
float shark(vec3 p)
{
    vec3 q;
    float dMin;
    float dBodyA;
    float dBodyB;
    float dMouth;
    float dFin;
    float dFinTop;
    float dHands;
    float dEye;
    float d;

    p.x += 8.0;
    p.z += 1.5;

    fishAngle = 0.08 * sin (3.14 * time * 1.1);

    p.xz = rotate2D(p.xz, -1.5);
    p.x = abs(p.x);  
    p.z -= 3.0;
    p.yz = rotate2D(p.yz, fishAngle);
    q = p - vec3(0.0, 0.0, -0.65);
    dBodyA = sdEllipsoid(q, vec3 (0.7, 0.8, 2.4));
    
    q = p;
    q.z -= -1.8;
    q.yz = rotate2D(q.yz, fishAngle);
    q.z -= -1.6;
    dBodyB = sdEllipsoid(q, vec3(0.40, 0.5, 2.5));
    
    q.z -= -2.2;
    q.xy = rotate2D(q.xy, 2.0 * fishAngle);
    q.xz -= vec2(0.5, -0.5);
    q.yz = rotate2D(q.yz, 0.4);
    dFin = sdEllipsoid(q, vec3(0.7, 0.05, 0.3));
    
    q = p;
    q.xy = rotate2D(q.xy, 2.0 * fishAngle * 1.25);
    q.yz -= vec2(-0.3, 0.1);
    dHands = sdEllipsoid(q, vec3(1.8, 0.07, 0.4));
    
    dFinTop = 1.0;
    q = p;
    q.y -= 0.8;
    q.z -= -1.5;
    q.yz = rotate2D(q.yz, 0.5);
    q.xz = rotate2D(q.xz, 1.0);
    dFinTop = sdEllipsoid(q, vec3(0.2, 0.6, 0.1));
    
    dMin = smin(dBodyA, dBodyB,  0.1);
    dMin = smin(dMin,   dFin,    0.1);
    dMin = smin(dMin,   dHands,  0.1);
    dMin = smin(dMin,   dFinTop, 0.1);
    return dMin;
}

float softshadow(in vec3 ro, in vec3 rd, in float k)
{
    float res = 1.0;
    float t = 0.0;
    for (int i = 0; i < SOFT_SHADOW_STEPS; ++i)
    {
        vec3 pos = ro + rd * t;
        float h = map(pos).y;
        res = min(res, k * h / t);
        if(res < 0.001)
        {
            break;
        }
        t += clamp(h, 0.01, 0.2);
    }
    return saturate(res);
}

vec2 castRay(in vec3 ro, in vec3 rd)
{
     float tmin = 1.0;
     float tmax = 40.0;
    
     float precis = 0.002;
     float t = tmin;
     float m = -1.0;
     for (int i = 0; i < 70; ++i)
     {
         float res = shark(ro + rd * t);
         if (res < precis || t > tmax)
         {
             break;
         }
             t += res;
         m = res;
     }

     if (t > tmax)
     {
         m = -1.0;
     }
    
     return vec2(t, m);
}

vec3 renderShark(in vec3 ro, in vec3 rd)
{ 
    vec3 color = vec3(0.0);    
    vec2 res = castRay(ro, rd);
    if (res.y > -0.5)
    {
         const vec3 light1 = vec3(0.5, 0.5, -0.5);
        
         vec3 pos = ro + res.x * rd;
    
         float red   = clamp(sin(time * 0.8), 0.2, 0.8);
         float green = clamp(cos(time * 0.4), 0.2, 0.8);
         float blue  = clamp(sin(time * 0.2), 0.2, 0.8);
        
        vec3 baseColor = vec3(red, green, blue);
         vec3 ambient = vec3(0.5) * baseColor;    
        
         vec3 normal = calcNormal(pos);
        
         float shadow1 = softshadow(pos + 0.001 * normal, light1, 32.0);    
         vec3 diffuse = baseColor * shadow1 * vec3(0.2, 0.0, 10.0);
        
         color = diffuse + ambient;
    }    
    return color;
}

vec3 render(in vec3 ro, in vec3 rd)
{
    vec3 color = vec3(0.5);
    vec4 res = intersect(ro,rd);
    if(res.x > 0.0)
    {
        const vec3 light1 = vec3(0.0, 0.0, -0.5);
        
        vec3 pos = ro + res.x * rd;
    
        vec3 baseColor = vec3(0.0, 0.2, 0.6);
        vec3 ambient = vec3(0.2) * baseColor;
        
        vec3 normal = calcNormal(pos);
        vec3 reflection = reflect(rd, normal);
    
        float occ = res.y;
        float shadow1 = softshadow(pos + 0.001 * normal, light1);
    
        vec3 diffuse = baseColor * shadow1 * occ;
        
        color = diffuse + ambient;
    }

    return pow(color, vec3(0.4545));
}

void main(void)
{
    vec2 p = 2.0 * (gl_FragCoord.xy / resolution.xy) - 1.0;
    p.x *= resolution.x / resolution.y;
    
    // camera
    vec3 ro = vec3(3.5 * 3.5, 2.9, -2.0);
    vec3 ww = normalize(vec3(0.0) - ro);
    vec3 uu = normalize(cross(vec3(0.0, 1.0, 0.0), ww));
    vec3 vv = normalize(cross(ww, uu));
    vec3 rd = normalize(p.x * uu + p.y * vv + 2.0 * ww);

    ro.x -= time * 0.1; //Camera / Ray moving
    
    vec3 color = render(ro + vec3(0.0, -1.0, 0.0), rd);
    
    color += vec3(0.0, 0.1, 0.25);
    
    color += renderShark(ro, rd);
    color += renderShark(ro + vec3(10.5, -1.3, 4.5), rd);
    color += renderShark(ro + vec3(15.5, -1.3, -4.5), rd);
    
    glFragColor = vec4(color, 1.0);
}
