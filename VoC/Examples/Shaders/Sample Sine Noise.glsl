#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/3lGyDW

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//-------------------------------------
/*

    Sine Noise
    
    it's similar to value noise
    it interpolates cells of randomly rotated
    and shifted sine intead of values.
    
    you can control the direction, animation speed
    and tiling.
    
    inspired from:
    https://www.shadertoy.com/view/tldSRj by iq
    https://www.shadertoy.com/view/wttSRj by robobo1221

*/
//-------------------------------------

#define PI acos(-1.0)

uvec3 pcg3d(uvec3 v)
{
    v = v * 1664525u + 1013904223u;

    v.x += v.y*v.z;
    v.y += v.z*v.x;
    v.z += v.x*v.y;

    v ^= v >> 16u;

    v.x += v.y*v.z;
    v.y += v.z*v.x;
    v.z += v.x*v.y;

    return v;
}

vec3 hash33(vec3 p)
{
    uvec3 u = uvec3(p);
    return vec3(pcg3d(u)) * (1.0/float(0xffffffffu));
}

vec3 NoiseCore(vec2 i, vec2 f, float tiling, float randomFactor, float angle, float animationSpeed, int seed)
{
    const float k = 2.0;
    i = mod(i, tiling);

    vec3 hv = hash33(vec3(i,seed));
    hv.x *= randomFactor * PI;
    hv.x += angle * PI;

    vec2 g0 = vec2(cos(hv.x), sin(hv.x));
    vec2 g1 = f + (hv.yz*2.0-1.0) * k - time * animationSpeed * g0;
    float p = dot(g0, g1) * PI * k;

    float value = sin(p);
    float derivative = cos(p);

    return vec3( value, vec2(derivative * g0) );
}

vec3 SineNoise(vec2 p, float tiling, float randomFactor, float angle, float animationSpeed, int seed)
{
    vec2 i = floor(p);
    vec2 f = fract(p);

    vec3 a = NoiseCore(i + vec2(0,0), f - vec2(0,0), tiling, randomFactor, angle, animationSpeed, seed);
    vec3 b = NoiseCore(i + vec2(1,0), f - vec2(1,0), tiling, randomFactor, angle, animationSpeed, seed);
    vec3 c = NoiseCore(i + vec2(0,1), f - vec2(0,1), tiling, randomFactor, angle, animationSpeed, seed);
    vec3 d = NoiseCore(i + vec2(1,1), f - vec2(1,1), tiling, randomFactor, angle, animationSpeed, seed);
    
    f = f*f*f*(f*(f*6.0-15.0)+10.0);

    return mix(mix(a,b,f.x),mix(c,d,f.x),f.y);
}

vec2 uv0;
vec3 noise(vec2 p, float t)
{
    if(uv0.x < 0.5)
        return SineNoise(p, t, 1.0, 0.0, 0.3, 200);
        
    return SineNoise(p, t, 0.0, sin(time * .1), 0.6, 200);
}

vec3 fbm(vec2 p, float t)
{
    float f = 1.0;
    float a = 1.0;
    float r = 0.0;
    float s = 0.0;
    
    vec2 dsum = vec2(0);
    vec2 offset = vec2(2.45,3.77);

    for(int i=0; i<6; i++)
    {
        vec3 n = noise((p + offset)*f, t*f);
        r += n.x*a;
        dsum += n.yz*a*f;
        f *= 2.0;
        s += a;
        a *= 0.5;
        offset *= 2.0;
    }
    
    return vec3(r,dsum)/s;
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.x;
    uv0 = gl_FragCoord.xy/resolution.xy;
    uv *= 10.0;

    vec3 n = fbm(uv, 10.0);
    
    vec3 col = vec3(0);
    if(uv0.y < 0.5)
        col.rg += n.yz;
    else
        col += n.x*0.5+0.5;

    // Output to screen
    glFragColor = vec4(col,1.0);
}
