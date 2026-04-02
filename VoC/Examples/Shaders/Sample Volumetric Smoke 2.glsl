#version 420

// original https://www.shadertoy.com/view/4t3XRf

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//#define Use_Perlin
//#define Use_Value
#define Use_Simplex
#define MOD3 vec3(.1031,.11369,.13787)
float hash31(vec3 p3)
{
    p3  = fract(p3 * MOD3);
    p3 += dot(p3, p3.yzx + 19.19);
    return -1.0 + 2.0 * fract((p3.x + p3.y) * p3.z);
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

vec3 hash33(vec3 p3)
{
    p3 = fract(p3 * MOD3);
    p3 += dot(p3, p3.yxz+19.19);
    return -1.0 + 2.0 * fract(vec3((p3.x + p3.y)*p3.z, (p3.x+p3.z)*p3.y, (p3.y+p3.z)*p3.x));
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

float noise(vec3 p) {
#ifdef Use_Value
    return value_noise(p * 2.0);
#elif defined Use_Simplex
    return simplex_noise(p);
#endif
    return 0.0;
}

float noise_sum_abs(vec3 p)
{
    float f = 0.0;
    p = p * 3.0;
    f += 1.0000 * abs(noise(p)); p = 2.0 * p;
    f += 0.5000 * abs(noise(p)); p = 2.0 * p;
    f += 0.2500 * abs(noise(p)); p = 2.0 * p;
    f += 0.1250 * abs(noise(p)); p = 2.0 * p;
    f += 0.0625 * abs(noise(p)); p = 2.0 * p;
    
    return f;
}

float noise_sum_abs_sin(vec3 p)
{
    float f = noise_sum_abs(p);
    f = sin(f * 2.5 + p.x * 5.0 - 1.5);
    
    return f * f;
}

float volDensity ( vec3 p ) {
    return noise_sum_abs_sin( vec3(p.x + -0.5*sin(time), p.y + 0.5*sin(time), p.z + time )) / max(4.0, pow(distance( p, vec3(0.0)), 5.0+ 8.0 * sin(time)));   
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    uv = uv * 2.0 - 1.0;
    
    vec3 rayPos = vec3( 0.0, 0.0, -2.4 * sin(time) );
    vec3 rayDir = normalize(vec3( uv, 1.0 ));
    
    vec3 color;
    
    float totalDensity = 0.0;
    for (int i = 0; i < 30; i++ ) {
        rayPos += rayDir * 0.03;
        totalDensity += abs(volDensity( rayPos ));
    }
    if (totalDensity == 0.0) {
        color = vec3( 1.0, 1.0, 1.0);
    } else {
        color = 1.8*vec3(uv, 1.5 + sin(time))/ totalDensity;
    }
    
    glFragColor = vec4(color, 1.0);
    //glFragColor = vec4(uv,0.5+0.05*sin(time),1.0);
    
}
