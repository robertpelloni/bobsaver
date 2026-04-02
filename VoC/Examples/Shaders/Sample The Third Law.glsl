#version 420

// original https://www.shadertoy.com/view/4l2XzW

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

float box(vec3 p, vec3 s)
{
    vec3 q = clamp(p, -s, s);
    return length(p - q);
}

float sdHexPrism( vec3 p, vec2 h )
{
    vec3 q = abs(p);
    return max((q.x*0.866025+q.y*0.5),q.y)-h.x;
}

vec2 map(vec3 p)
{
    vec3 q = p;
    
    float sc = 1.0;
    
    q = (fract(q * sc) * 2.0 - 1.0) * sc;
    
    vec3 spc = fract(p + 0.5) * 2.0 - 1.0;
    
    float md = 1000.0;
    float it = 0.0;
    
    const int iters = 5;
    
    for (int i = 0; i < iters; ++i) {
        
        float n = float(i) / float(iters-1);
        
        vec3 s = sign(q);
        
        vec3 w = normalize(q);
        
        float sm = abs(p.x) + abs(p.y) + abs(p.z) * 1.0;
        
        float mx = mix(1.0, 2.1, 0.5+0.5*sin(sm+time));
        
        q = mix(q, s*w*w, mx);
        
        float d = box(q, w*w*yrot(n*pi*2.0));
        
        float r = mix(1.0, 1.8, 0.5+0.5*sin(p.z*n+time));
        
        float sp = length(spc.xy) - r;
        
        d = max(d, -sp);
        
        if (d < md) {
            md = d;
            it = n;
        }
        
        md = min(md, d);
    }
    
    return vec2(md, it);
}

float trace(vec3 o, vec3 r)
{
     float t = 0.0;
    for (int i = 0; i < 16; ++i) {
        vec3 p = o + r * t;
        float d = map(p).x;
        t += d * 0.3;
    }
    return t;
}

vec3 pal(float idx)
{
    vec3 gt = vec3(1.2,0.5,0.8) * time;
    mat3 c = xrot(gt.x) * yrot(gt.y) * zrot(gt.z);
    vec3 p = mix(c[0], c[1], idx);
    vec3 q = mix(c[1], c[2], idx);
    vec3 m = abs(mix(p, q, idx));
    return 0.5 + m * 0.5;
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    uv = uv * 2.0 - 1.0;
    vec2 uvo = uv;
    uv.x *= resolution.x / resolution.y;
    
    vec3 o = vec3(0.0, 0.0, 0.0);
    vec3 r = normalize(vec3(uv, 1.0 - dot(uv,uv)));
    
    float rt = floor(time) + smoothstep(0.0, 1.0, fract(time));
    
    r *= zrot(rt);
    o.z += time * 4.0;
    
    float t = trace(o, r);
    vec3 w = o + r * t;
    vec2 fd = map(w);
    
    float fog = 1.0 / (1.0 + t * t * 0.1 + fd.x * 100.0);

    vec3 fc = pal(fd.y) * fog;
    
    fc = 1.0 - sqrt(fc);
    
    float edge = max(abs(uvo.x), abs(uvo.y));
    
    fc *= 1.0 - pow(edge,8.0);

    glFragColor = vec4(fc, 1.0);
}
