#version 420

// original https://www.shadertoy.com/view/tly3RV

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

mat2 rot(float x) {
    return mat2(cos(x), sin(x), -sin(x), cos(x));
}

mat2 timerot(float f, float t, float n) {
    return rot(mix(f,0.0,clamp(abs(mod(t,n)),0.0,1.0)) * 3.141592);
}

float ismissing(float t) {
    return min(mod(t, 2.0) * mod(t, 3.0) * mod(t, 5.0), 1.0);
}

float cutbox(vec3 p, float a, float b) {
    vec3 q = abs(p);
    float ba = max(q.x - a, q.y - a);
    float bb = max(q.x - b, q.y - b);
    return max(max(ba, -bb), q.z - 0.1);
}

float map(vec3 p) {
    float gt = time * 2.0;
    
    float t = floor(mod(gt, 30.0));
    float f = smoothstep(0.0, 1.0, fract(gt));
    
    float nt = ismissing(t);
    
    vec3 q = p;
    q.z += mix(0.0, sin(f*3.141592*1.0), nt);
    q.yz *= timerot(f, t, 2.0);
    float disk3 = cutbox(q, 3.0, 2.3);

    q = p;
    q.z += mix(0.0, sin(f*3.141592*2.0), nt);
    q.xz *= timerot(-f, t, 3.0);
    float disk2 = max(max(length(q.xy) - 2.0, 1.5 - length(q.xy)), abs(q.z) - 0.1);
    
    q = p;
    q.z += mix(0.0, sin(f*3.141592*3.0), nt);
    q.xy *= timerot(-f, t, 5.0);
    float disk1 = cutbox(q, 0.9, 0.4);
    
    vec2 r = vec2(p.z + 3.0, (abs(p.x / 5.0) - 0.5) * 5.0);
    float back = length(r) - 0.2;
    p.xy *= rot(3.141592 * 0.5);
    r = vec2(p.z - 4.0, (abs(p.x / 16.0) - 0.5) * 16.0);
    back = min(back, length(r) - 0.25);
    
    return min(min(min(disk1, disk2), disk3), back);
}

vec3 normal(vec3 p)
{
    vec3 o = vec3(0.01, 0.0, 0.0);
    return normalize(vec3(map(p+o.xyy) - map(p-o.xyy),
                          map(p+o.yxy) - map(p-o.yxy),
                          map(p+o.yyx) - map(p-o.yyx)));
}

float trace(vec3 o, vec3 r) {
  float t = 0.0;
    for (int i = 0; i < 32; ++i) {
        t += map(o + r * t);
    }
    return t;
}

vec3 light(vec3 w, vec3 n, vec3 p, vec3 c) {
    vec3 d = w - p + n * 0.01;
    float l = length(d);
    float m = max(sign(trace(p, d / l) - l), 0.0);
    float a = 1.0 / (1.0 + dot(d, d) * 0.01);
    float s = max(dot(d / l, -n), 0.0);
    return s * a * c * m;
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    uv = uv * 2.0 - 1.0;
    uv.x *= resolution.x / resolution.y;
    
    vec3 r = normalize(vec3(uv, 1.0 - dot(uv, uv) * 0.2));
    vec3 o = vec3(0.0, 0.0, -6.0);

    float gt = time * 2.0;
    float nt = floor(mod(gt, 30.0));
    float nf = smoothstep(0.0, 1.0, fract(gt));
    float isp = mix(0.0, sin(-nf*3.141592*2.0), ismissing(nt));
    o.z -= isp;
    r.xy *= rot(3.141592 * -0.25) * timerot(-nf, nt, 5.0);

    float t = trace(o, r);
    vec3 w = o + r * t;
    vec3 n = normal(w);
    
    vec3 lit = light(w, n, vec3(1.0, 2.0, -5.0), vec3(0.75, 0.5, 0.5));
    lit += light(w, n, vec3(0.0, 0.0, -6.0), vec3(0.0, 0.5, 1.0));

    glFragColor = vec4(vec3(sqrt(lit)), 1.0);
}
