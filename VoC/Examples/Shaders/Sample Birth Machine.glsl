#version 420

// original https://www.shadertoy.com/view/MtsXRn

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float pi = 3.14159;

mat3 xrot(float t)
{
    return mat3(1.0, 0.0, 0.0,
                0.0, cos(t), -sin(t),
                0.0, sin(t), cos(t));
}

mat3 yrot(float t)
{
    return mat3(cos(t), 0.0, -sin(t),
                0.0, 1.0, 0.0,
                sin(t), 0.0, cos(t));
}

mat3 zrot(float t)
{
    return mat3(cos(t), -sin(t), 0.0,
                sin(t), cos(t), 0.0,
                0.0, 0.0, 1.0);
}

vec2 map(vec3 p)
{
    float t = p.z;
    p = fract(p) * 2.0 - 1.0;
    vec3 q = p;
    float k = 1.0;
    float fd = 1000.0;
    float mt = 0.0;
    const int n = 8;
    for (int i = 0; i < n; ++i) {  
        float d = length(q) - 0.1;
        if (d < fd) {
            mt = float(i);
            fd = d;
        }
        fd = min(fd, d);
        q += -sign(q) * (length(q)-0.15);
    }
    mt /= float(n-1);
    float tr = 1.0 + 0.4 * sin(t*3.0);
    float ca = length(p.xy) - tr;
    fd = max(fd, -ca);
    return vec2(fd, mt);
}

float trace(vec3 o, vec3 r)
{
    float t = 0.0;
    for (int i = 0; i < 32; ++i) {
        vec3 p = o + r * t;
        float d = map(p).x;
        t += d * 0.25;
    }
    return t;
}

vec3 normal(vec3 p)
{
    vec3 o = vec3(0.01, 0.0, 0.0);
    return normalize(vec3(map(p+o.xyy).x - map(p-o.xyy).x,
                          map(p+o.yxy).x - map(p-o.yxy).x,
                          map(p+o.yyx).x - map(p-o.yyx).x));
}

vec3 col(float x)
{
    vec3 ka = vec3(1.0, 1.0, 0.0) * 0.5;
    vec3 kb = vec3(1.0, 0.5, 0.0) * 0.5;
    vec3 kc = vec3(0.0, 0.0, 1.0) * 0.5;
    vec3 ma = mix(ka, kb, x);
    vec3 mb = mix(kb, kc, x);
    return mix(ma, mb, x);
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    uv = uv * 2.0 - 1.0;
    uv.x *= resolution.x / resolution.y;
    
    mat3 xfm = yrot(time) * xrot(time*0.5) * zrot(time*0.25);
    
    vec3 r = normalize(vec3(uv, 1.0 - dot(uv,uv)*0.333));
     r *= xfm;
    
    vec3 o = vec3(0.5, 0.5, 0.0);
    o.z += time * 0.125;
    
    float t = trace(o, r);
    vec3 w = o + r * t;
    vec3 sn = normal(w);
    vec2 fd = map(w);
    
    float prod = max(dot(sn, -r), 0.0);
    
    float fog = 1.0 / (1.0 + t * t + fd.x * 100.0);
    
    float flmb = 0.0;
    float fspec = 0.0;
    float fls = 0.0;
    
    for (int j = -1; j <= 1; j+=2) {
    
        vec3 lpos = o + vec3(0.0,0.0,1.0) * float(j);

        float lt = 0.0;
        for (int i = 0; i < 16; ++i) {
            lt += (length(o + r * lt - lpos) - 0.1) * 0.5;
        }

        float lm = 1.0;
        if (t < lt) {
            lm = 1.0 / (1.0 + lm * lm * 0.1);
        }

        float ls = 1.0 / (1.0 + lt * lt * 0.001);

        vec3 ld = lpos - w;
        float la = length(ld);
        ld /= la;
        float lmb = max(dot(ld, sn), 0.0);
        vec3 refl = reflect(ld, sn);
        float spec = max(dot(refl, r), 0.0);
        spec = clamp(pow(1.0+spec, 4.0), 0.0, 1.0);
        spec = mix(spec, 0.0, fd.y);
        float atten = 1.0 / (1.0 + la * la * 0.01);
        
        flmb += lmb * atten;
        fspec += spec * atten;
        fls += ls * lm;
    }
    
    vec3 diff = col(fd.y);
    
    diff = mix(diff, vec3(1.0, 1.0, 1.0), abs(sn.z));
    
    vec3 fc = diff * (flmb + fspec) * fog + fls;
    
    glFragColor = vec4(fc, 1.0);
}
