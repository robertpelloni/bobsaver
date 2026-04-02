#version 420

// original https://www.shadertoy.com/view/Xts3zf

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI    3.14159265359
#define PI2    ( PI * 2.0 )

bool Flag = false;
int M;

mat2 rotate(float a)
{
    return mat2(cos(a), sin(a), -sin(a), cos(a));    
}

vec3 hsv(float h, float s, float v)
{
  return mix( vec3( 1.0 ), clamp( ( abs( fract(
    h + vec3( 3.0, 2.0, 1.0 ) / 3.0 ) * 6.0 - 3.0 ) - 1.0 ), 0.0, 1.0 ), s ) * v;
}

float map1(in vec3 p)
{     
    p.y += 0.8;
    p.yz *= rotate(0.2);
    p.zx *= rotate(time * 0.3);
    return length(vec3(vec2(abs(abs(abs(abs(abs(length(p.xz)-3.0)-1.0)-0.8)-0.4)-0.2)-0.1, sin(atan(p.z,p.x)*12.0)/5.0), p.y*1.5).xzy)-0.07;
}

float map2(in vec3 p)
{     
      p.yz *= rotate(time * 0.3);
    float a = atan(p.z, p.y);
    p.yz *= rotate(a);
    p.y -= 1.2;
    p.x = abs(p.x) - 2.0;
    p.xy *= rotate(a * 2.0);
    return abs(p.x) + abs(p.y) - 0.15;
}

float map3(in vec3 p)
{     
    p.xy *= rotate(PI * 0.5);
    p.yz *= rotate(PI * 0.5);
    float a = atan(p.z, p.x);
    p.xz *= rotate(a);
    p.x -= 0.7;
    p.xy *= rotate(a* (2.5 * sin(time * 0.5)));
    p.x = abs(p.x) - 0.3;
    return length(p.xy) - 0.2;
}

float map4(in vec3 p)
{     
    p.xz *= rotate(time * 0.6);
    p.yz *= rotate(time * 0.6);   
    float r = 2.0;
    float f = 5.0 / 2.0;
    p.xz = vec2(length(p) - r, sin(atan(p.z, p.x) * f) / f * 2.0);
    return abs(p.x) + abs(p.y) + abs(p.z) - 0.3;
 }

float map(in vec3 p)
{
    float de1 = 0.8 * map1(p);
    float de2 = 0.5 * map2(p);
    float de3 = 0.8 * map3(p);
    float de4 = 0.5 * map4(p);    
    if (Flag)
    {
        if (de1 < de2 && de1 < de3 && de1 < de4)
        {
            M = 1;
         } else if (de2 < de3 && de2 < de4){
            M = 2;
         } else if (de3 < de4){
            M = 3;   
        } else {
            M = 4;
        }
    }    
    return min(min(min(de1,de2),de3),de4);
}

vec3 doColor(in vec3 p)
{
    Flag = true; map(p); Flag = false;
    if (M == 1)
    {
        return hsv(atan(p.z, p.x) / PI2 - 0.02 * time, 0.4, 0.7);
    }
    if (M == 2) 
    {
        return hsv(0.1 * time, 0.6, 1.0 );;
    }
    if (M == 3) 
    {
        return vec3(0.2, 0.7, 0.3);
    }
    return vec3(1.0, 0.2, 0.1);
}

vec3 calcNormal(in vec3 p)
{
    const vec2 e = vec2(0.0001, 0.0);
    return normalize(vec3(
        map(p + e.xyy) - map(p - e.xyy),
        map(p + e.yxy) - map(p - e.yxy),
        map(p + e.yyx) - map(p - e.yyx)));
}

float softshadow(in vec3 ro, in vec3 rd)
{
    float res = 1.0;
    float t = 0.05;
    for(int i = 0; i < 32; i++)
    {
        float h = map(ro + rd * t);
        res = min(res, 8.0 * h / t);
        t += clamp(h, 0.02, 0.1);
        if(h < 0.001 || t > 1.5) break;
    }
    return clamp(res, 0.0, 1.0);
}

float march(in vec3 ro, in vec3 rd)
{
    const float maxd = 50.0;
    const float precis = 0.001;
    float h = precis * 2.0;
    float t = 0.0;
    float res = -1.0;
    for(int i = 0; i < 64; i++)
    {
        if(h < precis || t > maxd) break;
        h = map(ro + rd * t);
        t += h;
    }
    if(t < maxd) res = t;
    return res;
}

void main(void)
{
    vec2 p2d = (2.0 * gl_FragCoord.xy - resolution.xy) / resolution.y;
    vec3 col = vec3(0.2, 0.3, 0.7)*((p2d.y+1.0) * 0.3);
       vec3 rd = normalize(vec3(p2d, -1.8));
    vec3 ro = vec3(0.0, 0.0, 3.5);
    vec3 li = normalize(vec3(0.5, 0.8, 3.0));
    float t = march(ro, rd);
    if(t > -0.001)
    {
        vec3 p3d = ro + t * rd;
        vec3 n = calcNormal(p3d);
        float dif = clamp((dot(n, li) + 0.5) * 0.7, 0.4, 1.0);
        dif *= clamp(softshadow(p3d, li), 0.4, 1.0);
        col = doColor(p3d) * dif;
    }
       glFragColor = vec4(col, 1.0);
}
