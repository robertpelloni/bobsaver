#version 420

// original https://www.shadertoy.com/view/4tjGWV

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

vec3 ra, rb, rc, rd;

float line(vec2 p, vec3 a, vec3 b) {
    vec2 zs = vec2(1.0);// / (vec2(a.z,b.z) * 0.5 + 1.5);
    a.xy *= zs.x;
    b.xy *= zs.y;
    vec2 c = b.xy - a.xy;
    float t = dot(p - a.xy, c) / dot(c,c);
    t = clamp(t, 0.0, 1.0);
    vec2 r = mix(a.xy, b.xy, t);
    vec2 d = p - r;
    return dot(d,d);
}

vec3 ddt(vec3 s, float t, vec4 k)
{
    vec3 del = normalize(k.xyz - s);
    vec3 mp = mix(s, k.xyz, 0.5);
    vec3 rf = k.xyz - mp - del * 0.5;
    
    vec3 fw = vec3(0.0, 0.0, 1.0);
    if (abs(dot(del,fw)) > 0.7) {
        fw = vec3(0.0, 1.0, 0.0);
    }
    vec3 tg = normalize(cross(del, fw));
    tg.z = 0.0;
    
    rf += tg * k.w * 0.1;
    
    rf.y -= 0.05;
    return rf;
}

vec3 euler(vec3 s, vec4 k, float t, float h)
{
    return s + ddt(s, t, k) * h;
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    uv = uv * 2.0 - 1.0;
    uv.x *= resolution.x / resolution.y;
    
    vec3 k = vec3(10.0, 28.0, 8.0/3.0);
    
    vec3 o = vec3(0.0, -1.5, 0.0);
    float mat = 0.75;
    
    float len = 1.0;
    ra = vec3(0.0, 0.0, 0.0);
    rb = ra + normalize(vec3(-1.0)) * len;
    rc = rb + normalize(vec3(-1.0)) * len;
    rd = rc + normalize(vec3(-1.0)) * len;
    
    float t = 0.0;
    float dt = 1.0;
    
    const int iter = 64;
    float trail = 0.0;
    for (int i = 0; i < iter; ++i) {
        float time = time * 1.0 / 3.0;
        if (float(i) >= fract(time)*float(iter)) {
            break;
        }
        for (int j = 0; j < 4; ++j) {
            rb = euler(rb, vec4(ra,1.0), t, dt);
            rc = euler(rc, vec4(rb,0.0), t, dt);
            rd = euler(rd, vec4(rc,0.0), t, dt);
            t += dt;
            
            vec3 end = (rd-o)*mat;
            trail += 1.0 / (1.0 + dot(uv-end.xy,uv-end.xy) * 10000.0);
        }
    }

    float da = line(uv, (ra-o)*mat, (rb-o)*mat);
    float db = line(uv, (rb-o)*mat, (rc-o)*mat);
    vec3 endp = (rd-o)*mat;
    float dc = line(uv, (rc-o)*mat, endp);
    float d = min(da, min(db, dc));
    
    float fc = 1.0 / (1.0 + d * 1000.0);
    
    vec3 bc = vec3(1.0-(uv.y*0.5+0.5));
    
    bc = mix(bc, vec3(1.0, 1.0, 0.0), fc);
    
    float lit = trail;
    
    bc += lit * vec3(1.0, 1.0, 1.0) * 0.1;
    
    glFragColor = vec4(bc,1.0);
}
