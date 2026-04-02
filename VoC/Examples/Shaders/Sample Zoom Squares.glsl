#version 420

// original https://www.shadertoy.com/view/Xt3Szs

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec3 col1 = vec3(0.118, 0.365, 0.467);
vec3 col2 = vec3(0.514, 0.851, 0.933);
vec3 col3 = vec3(0.957, 0.875, 0.29);
vec3 col4 = vec3(0.973, 0.663, 0.106);
vec3 col5 = vec3(0.843, 0.431, 0.176);
vec3 col6 = vec3(0.361, 0.251, 0.145);

mat2 rot(float x)
{
    return mat2(cos(x), sin(x), -sin(x), cos(x));
}

float sdBox( vec2 p, vec2 b )
{
  vec2 d = abs(p) - b;
  return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

vec2 box(vec2 p, float r, float k, float t)
{
    vec2 q = vec2(atan(p.y, p.x) / 3.14159 * k, length(p) - r);
    q.x = (fract(q.x / k) - 0.5) * k;
    q.y = sdBox(p * rot(t), vec2(1.0));
    return q;
}

vec3 cout = vec3(0.0);

vec3 tex(vec2 p, float t, float pt)
{
    vec2 of = vec2(cos(t), sin(t)) * 0.5;
    vec2 pof = vec2(cos(pt), sin(pt)) * 0.5;
    
    vec2 c = box(p + of, 1.0, 3.0, t);
    vec2 c2 = box(p + of, 1.0, 3.0, t);
    
    float ln = 10000.0;
    
    float k = 1.0 / (1.0 + c.y * c.y * ln);
    float u = 1.0 / (1.0 + c2.y * c2.y * ln);
    
    vec2 sub = p;
    
    cout.xy = sub / 0.25;
    cout.z = 1.0;
    
    float d = 1000.0;
    vec2 q = c2;
    for (int i = 0; i < 6; ++i) {
        for (int j = 0; j < 3; ++j) {
            q.x = abs(q.x) - 0.125;
            q *= rot(3.141592 * 0.25);
        }
        q.y = abs(q.y) - 0.25;
        q *= rot(3.141592 * 0.125);
        d = min(d, sdBox(q, vec2(0.125)));
    }
    
    float r = 1.0 / (1.0 + d * d * ln);
    
    vec2 ins = box(cout.xy + pof, 1.0, 1.0, pt);
    float imask = max(sign(ins.y), 0.0);
    float omask = max(sign(-c.y), 0.0);
    float mask = imask * omask;
    r *= omask * imask;
    
    vec2 rp = p + of;
    
    vec3 tex1 = vec3(0.0,0.0,0.0);//texture2D(iChannel0, rp).xyz;
    tex1 = vec3(dot(tex1, vec3(0.299, 0.587, 0.114)));
    tex1 *= col1;
    
    vec3 dest = mix(tex1, vec3(0.0), max(sign(d), 0.0)) * mask;
    vec3 src = mix(col3, vec3(0.0), max(sign(-d), 0.0)) * mask;
    
    vec3 fc = mix(src + dest, vec3(0.0), r);
    
    return mix(fc, col3 * 2.0, k);
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    uv = uv * 2.0 - 1.0;
    uv.x *= resolution.x / resolution.y;
    
    vec3 r = normalize(vec3(uv, 1.0 - dot(uv,uv) * 0.1));
    vec3 o = vec3(0.0, 0.0, -2.0);
    vec3 n = vec3(0.0, 0.0, 1.0);
    
    float st = time;
    
    o.xy += vec2(cos(time) * sin(time), sin(time)) * 2.0;
    r.xy *= rot(st);
    n.xz *= rot(sin(time) * 0.3);
    n.xy *= rot(st);
    
    float t = -dot(o, n) / dot(r, n);
    t += max(sign(-t), 0.0) * -1000.0;
    vec3 w = o + r * t;
    
    float end = log(256.0);
    float zt = mod(st, end);
    float depth = 64.0 * exp(zt);
    w.xy /= depth;
    
    /* to give the appearence of linear time zooming i use exp(time). */
    /* the scene matches up every 4^n seconds, so i can only mod() when */
    /* exp(time) = some power of 4, and for this modulus i use log(4^4 = 256) */
    
    vec3 p = vec3(w.xy, 1.0);
    vec3 col = vec3(0.0);
    float pinv = 0.0;
    
    for (int i = 0; i < 10; ++i) {
        float inv = mod(floor(float(i)), 2.0) * 2.0 - 1.0;
        float t = inv * time / end * 3.141592;
        float pt = pinv * time / end * 3.141592;
        col += tex(p.xy, t, pt) * p.z;
        p = cout;
        pinv = inv;
    }
    
    float fog = 1.0 / (1.0 + t * t * 0.01);
    
    col = mix(col6, col, fog);
    
    glFragColor = vec4(sqrt(col), 1.0);
}
