#version 420

// original https://www.shadertoy.com/view/MtyyRd

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define MOD3 vec3(.1031,.11369,.13787)

//value noise hash
float hash31(vec3 p3)
{
    p3  = fract(p3 * MOD3);
    p3 += dot(p3, p3.yzx + 19.19);
    return -1.0 + 2.0 * fract((p3.x + p3.y) * p3.z);
}

//simplex and perlin noise hash
vec3 hash33(vec3 p3)
{
    p3 = fract(p3 * MOD3);
    p3 += dot(p3, p3.yxz+19.19);
    return -1.0 + 2.0 * fract(vec3((p3.x + p3.y)*p3.z, (p3.x+p3.z)*p3.y, (p3.y+p3.z)*p3.x));
}

float value_noise(vec3 p)
{
    vec3 pi = floor(p);
    vec3 pf = p - pi;
    
    vec3 w = pf * pf * (3.0 - 2.0 * pf);
    
    return     mix(
                mix(
                    mix(hash31(pi + vec3(0, 0, 0)), hash31(pi + vec3(1, 0, 0)), w.x),
                    mix(hash31(pi + vec3(0, 0, 1)), hash31(pi + vec3(1, 0, 1)), w.x), 
                    w.z),
                mix(
                    mix(hash31(pi + vec3(0, 1, 0)), hash31(pi + vec3(1, 1, 0)), w.x),
                    mix(hash31(pi + vec3(0, 1, 1)), hash31(pi + vec3(1, 1, 1)), w.x), 
                    w.z),
                w.y);
}

float perlin_noise(vec3 p)
{
    vec3 pi = floor(p);
    vec3 pf = p - pi;
    
    vec3 w = pf * pf * (3.0 - 2.0 * pf);
    
    return     mix(
                mix(
                    mix(dot(pf - vec3(0, 0, 0), hash33(pi + vec3(0, 0, 0))), 
                        dot(pf - vec3(1, 0, 0), hash33(pi + vec3(1, 0, 0))),
                           w.x),
                    mix(dot(pf - vec3(0, 0, 1), hash33(pi + vec3(0, 0, 1))), 
                        dot(pf - vec3(1, 0, 1), hash33(pi + vec3(1, 0, 1))),
                           w.x),
                    w.z),
                mix(
                    mix(dot(pf - vec3(0, 1, 0), hash33(pi + vec3(0, 1, 0))), 
                        dot(pf - vec3(1, 1, 0), hash33(pi + vec3(1, 1, 0))),
                           w.x),
                       mix(dot(pf - vec3(0, 1, 1), hash33(pi + vec3(0, 1, 1))), 
                        dot(pf - vec3(1, 1, 1), hash33(pi + vec3(1, 1, 1))),
                           w.x),
                    w.z),
                w.y);
}

float simplex_noise(vec3 p)
{
    const float K1 = 0.333333333;
    const float K2 = 0.166666667;
    
    vec3 i = floor(p + (p.x + p.y + p.z) * K1);
    vec3 d0 = p - (i - (i.x + i.y + i.z) * K2);
    
    // thx nikita: https://www.shadertoy.com/view/XsX3zB
    vec3 e = step(vec3(0.0), d0 - d0.yzx);
    vec3 i1 = e * (1.0 - e.zxy);
    vec3 i2 = 1.0 - e.zxy * (1.0 - e);
    
    vec3 d1 = d0 - (i1 - 1.0 * K2);
    vec3 d2 = d0 - (i2 - 2.0 * K2);
    vec3 d3 = d0 - (1.0 - 3.0 * K2);
    
    vec4 h = max(0.6 - vec4(dot(d0, d0), dot(d1, d1), dot(d2, d2), dot(d3, d3)), 0.0);
    vec4 n = h * h * h * h * vec4(dot(d0, hash33(i)), dot(d1, hash33(i + i1)), dot(d2, hash33(i + i2)), dot(d3, hash33(i + 1.0)));
    
    return dot(vec4(31.316), n);
}

float fbm(vec3 p)
{
    float r = 0.;
    float m = 0.5;
    for (int i=0; i<10;i++){
        r += perlin_noise(p) * m;
        p *= 2.;
        m *= 0.5;
    }
    return r;
}

float weird(vec3 p){
    float value = 0.;
    float m = 0.5;
    for (int i=0; i<5; i++){
        value = fbm(vec3(p.xy,time*m + value));
        m *= 0.75;
    }
//    return abs(value*p.z);
    return tanh(value*p.z)*0.5+0.5;
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    uv.x *= resolution.x / resolution.y;

    // Time varying pixel color
    float scale = 3.;
    vec3 col = vec3(
        weird(vec3(uv*scale,25)),
        weird(vec3(uv*scale,5)),
        weird(vec3(uv*scale,1))
    );

    // Output to screen
    glFragColor = vec4(col,1.0);
}
