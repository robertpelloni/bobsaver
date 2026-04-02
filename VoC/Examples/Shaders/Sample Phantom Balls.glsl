#version 420

// original https://www.shadertoy.com/view/3lSGDV

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

///
/// This post cloned from below created by kaneta.
///  https://www.shadertoy.com/view/wl2GWG
///
/// Also Phantom Mode by aiekick
/// https://www.shadertoy.com/view/MtScWW

#define repeat(p, span) mod(p, span) - (0.5 * span)

mat3 m = mat3( 0.00,  0.80,  0.60,
                         -0.80,  0.36, -0.48,
                         -0.60, -0.48,  0.64);

float hash(float n)
{
    return fract(sin(n) * 43758.5453);
}

float noise(in vec3 x)
{
    vec3 p = floor(x);
    vec3 f = fract(x);
    
    f = f * f * (3.0 - 2.0 * f);
    
    float n = p.x + p.y * 57.0 + 113.0 * p.z;
    
    float res = mix(mix(mix(hash(n +   0.0), hash(n +   1.0), f.x),
                                  mix(hash(n +  57.0), hash(n +   58.0), f.x), f.y),
                            mix(mix(hash(n + 113.0), hash(n + 114.0), f.x),
                                   mix(hash(n + 170.0), hash(n + 171.0), f.x), f.y), f.z);
    return res;
}

float fbm(vec3 p)
{
    float f;
    f   = 0.5000 * noise(p); p = m * p * 2.02;
    f += 0.2500 * noise(p); p = m * p * 2.03;
    f += 0.1250 * noise(p);
    return f;
}

mat3 camera(vec3 ro, vec3 ta)
{
    vec3 up = normalize(vec3(0, 1, 0));
    vec3 cw = normalize(ta - ro);
    vec3 cu = normalize(cross(cw, up));
    vec3 cv = normalize(cross(cu, cw));
    return mat3(cu, cv, cw);
}

float sdSphere(vec3 p, float r)
{
    float s = r + fbm(p * 2.0 + time);
    return length(p) - s;
}

float map(vec3 p)
{
    p = repeat(p + 2., 4.0);
    return sdSphere(p, 0.8);
}

vec3 normal(vec3 p)
{
    vec2 e = vec2(0.0001, 0);
    float d = map(p);
    vec3 n = d - vec3(
        map(p - e.xyy),
        map(p - e.yxy),
        map(p - e.yyx));
    return normalize(n);
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy * 2.0 - resolution.xy) / min(resolution.x, resolution.y);

    vec3 col = vec3(0);
    
    vec3 ro = vec3(sin(time * 0.2), 1. + sin(time) * 0.2, time);
    vec3 ta = vec3(0, 1., time + 1.);
    
    vec3 ray = camera(ro, ta) * normalize(vec3(uv, 2.5));
    
    vec3 p;
    
    float d = 0., t = 0.01;
    float ac = 0.;
    
    for (int i = 0; i < 64; i++)
    {
        p = ro + ray * t;
        
        d = map(p);
        
        // Phantom Mode
        d = max(abs(d), 0.02);
        
        ac += exp(-d * 3.);
        t += d;
    }
    
    col = vec3(ac * 0.01);
    
    vec3 fog = vec3(0.5, 0.8, 1.5) * t * 0.05;
    col *= fog;
    
    float fog2 = t * 0.015;
    col += fog2;
    
    glFragColor = vec4(col, 1.0);
}
