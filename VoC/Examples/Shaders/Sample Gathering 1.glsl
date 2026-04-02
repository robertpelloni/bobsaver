#version 420

// original https://www.shadertoy.com/view/llSSWt

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI  3.14159265359

mat2 rotate(float a)
{
    return mat2(cos(a), sin(a), -sin(a), cos(a));
}

// https://www.shadertoy.com/view/4tX3DS
vec2 fold(in vec2 p, in float a)
{
    p.x = abs(p.x);
    vec2 v = vec2(cos(a), sin(a));
    for(int i = 0; i < 5; i++)
    {
        p -= 2.0 * min(0.0, dot(p, v)) * v;
        v = normalize(vec2(v.x - 1.0, v.y));
    }
    return p;    
}

float map(in vec3 p)
{   
    p.yz *= rotate(time * 0.1);
    p.zx *= rotate(time * 0.05);   
    p.xy = fold(p.xy,  PI / 2.0);
    p.z = abs(p.z) - 0.5;
    p.z = abs(p.z) - 0.8;
    p.z = abs(p.z) - 0.7;
    p.z = abs(p.z) - 0.5;
    p.z += sin(length(p.xy) * 1.5 + time * 2.0)* 0.15;
    p.y += time * 0.5;
    p.y = mod(p.y, 0.4) - 0.2;
    return length(p) -  0.1;
}

vec3 calcNormal( in vec3 pos )
{
    vec2 e = vec2(1.0, -1.0) * 0.002;
    return normalize(
        e.xyy * map(pos + e.xyy) + 
        e.yyx * map(pos + e.yyx) + 
        e.yxy * map(pos + e.yxy) + 
        e.xxx * map(pos + e.xxx));
}

float intersect(in vec3 ro, in vec3 rd)
{
    const float maxd = 35.0;
    const float precis = 0.001;
    float h = 1.0;
    float t = 0.0;
    for(int i = 0; i < 128; i++)
    {
        if(h < precis || t > maxd) break;
        h = map(ro + rd * t);
        t += h;
    }
    if( t > maxd ) t=-1.0;
    return t;
}

void main(void)
{
    vec2 p = (2.0 * gl_FragCoord.xy - resolution.xy) / resolution.y;
    vec3 col = vec3(length(p) * 0.1);
    col.b += 0.05;
    vec3 ro = vec3(0.0, 0.0, 3.5);
    vec3 rd = normalize(vec3(p, -1.8));
    float t = intersect(ro, rd);
    if(t > -0.001)
    {
        vec3 pos = ro + t * rd;
        vec3 nor = calcNormal(pos);
        vec3 li = normalize(vec3(0.5, 0.8, 3.0));
        col = vec3(0.8, 0.1, 0.1);
        col *= max(dot(li, nor), 0.2);
        col += pow(max(dot(vec3(0, 0, 1), reflect(-li, nor)), 0.0), 30.0);
        col = pow(col, vec3(0.8)); 
    }
    glFragColor = vec4(col, 1.0);
}
