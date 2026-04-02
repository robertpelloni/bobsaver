#version 420

// original https://www.shadertoy.com/view/llB3WK

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

float line(vec2 p, vec3 a, vec3 b) {
    vec2 zs = 1.0 / (vec2(a.z,b.z) * 0.5 + 1.5);
    a.xy *= zs.x;
    b.xy *= zs.y;
    vec2 c = b.xy - a.xy;
    float t = dot(p - a.xy, c) / dot(c,c);
    t = clamp(t, 0.0, 1.0);
    vec2 r = mix(a.xy, b.xy, t);
    vec2 d = p - r;
    return dot(d,d);
}

vec3 ddt(vec3 s, vec3 k)
{
    vec3 r;
    r.x = k.x * (s.y - s.x);
    r.y = s.x * (k.y - s.z) - s.y;
    r.z = s.x * s.y - k.z * s.z;
    return r;
}

vec3 rk4(vec3 s, vec3 k, float h)
{
    vec3 k0 = ddt(s, k);
    vec3 k1 = ddt(s + k0 * h * 0.5, k);
    vec3 k2 = ddt(s + k1 * h * 0.5, k);
    vec3 k3 = ddt(s + k2 * h, k);
    return s + (k0 + 2.0 * (k1 + k2) + k3) * h / 6.0;
}

vec3 midpoint(vec3 s, vec3 k, float h)
{
    vec3 k0 = ddt(s, k);
    return s + ddt(s + k0 * h * 0.5, k) * h;
}

vec3 euler(vec3 s, vec3 k, float h)
{
    return s + ddt(s, k) * h;
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    uv = uv * 2.0 - 1.0;
    uv.x *= resolution.x / resolution.y;
    
    vec3 k = vec3(10.0, 28.0, 8.0/3.0);
    
    vec3 iv;
    iv.z = k.y - 1.0;
    iv.x = sqrt(k.z * iv.z);
    iv.y = -iv.x;
    
    float t = 1000.0;
    
    vec3 mov = iv + vec3(0.0, 8.0, 0.0);
    mat3 rot = yrot(time) * zrot(pi*0.5);
//    if (mouse.z >= 1.0) {
//        vec2 mp = mouse.xy / resolution.xy * 2.0 - 1.0;
//        rot = zrot(pi*0.5) * xrot(mp.y*6.0) * yrot(mp.x*6.0);
//    }
    rot *= mat3(0.04);
    
    vec3 s = iv;
    for (int i = 0; i < 300; ++i) {
        vec3 sp = s;
        s = midpoint(s, k, 0.02);
        float d = line(uv, (sp-mov)*rot, (s-mov)*rot);
        t = min(t, d);
    }
    
    float fc = 1.0 / (1.0 + t * 1000.0);
    
    vec3 bc = vec3(0.0, 0.0, 1.0-(uv.y*0.5+0.5));
    
    bc = mix(bc, vec3(1.0, 1.0, 1.0), fc);
    
    glFragColor = vec4(bc,1.0);
}
