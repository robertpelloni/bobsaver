#version 420

// original https://www.shadertoy.com/view/4tlcz4

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/* greets to Shadertoy community */

float thetime() {
    return time * 2.0;
}

mat2 rot(float x) {
    return mat2(cos(x), sin(x), -sin(x), cos(x));
}

float sdBox( vec3 p, vec3 b )
{
  vec3 d = abs(p) - b;
  return min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0));
}

float sdTorus( vec3 p, vec2 t )
{
  vec2 q = vec2(length(p.xz)-t.x,p.y);
  return length(q)-t.y;
}

float section(vec3 p) {
    return sdTorus(p, vec2(0.5, 0.1));
}

float mat = 0.0;

float map(vec3 p) {
    float t = fract(thetime()) * 2.0;
    float t0 = clamp(t, 0.0, 1.0);
    float t1 = clamp(t - 1.0, 0.0, 1.0);
    
    //t0 = smoothstep(0.0, 1.0, t0);
    //t1 = smoothstep(0.0, 1.0, t1);
    
    vec3 s = p;
    s.x += floor(thetime()) * 2.0;
    s.y += floor(thetime());
    
    float d = 1000.0;
    mat = 8.0;
    const int n = 8;
    float c = 0.5;
    for (int i = 0; i < n; ++i) {
        float f = float(i) / float(n - 1);
        vec3 q = s;
        q -= vec3(-1.0, 0.0, 0.0);
        float u = mix(t0, t1, f);
        q.xy *= rot(3.141492 * u);
        float c = f * (1.0 - f) * 4.0;
        q += vec3(-1.0, 0.0, 0.0);
        vec3 pa = q + vec3(0.0, -1.0, 0.0);
        vec3 pb = q + vec3(0.0, 0.0, 0.0);
        vec3 r = mix(pa, pb, f);
        float k = section(r);
        if (k < d) {
            d = k;
            mat = float(i);
        }
    }
    
    for (int i = -2; i <= 2; ++i) {
        vec3 q = p - vec3(0.0, -1.0, 0.0);
        q.y += 0.65;
        q.y -= float(i);
        q.x -= floor(q.y) * 2.0;
        q.y = fract(q.y) - 0.5;
        q.y += float(i);
        float k = sdBox(q, vec3(1.0, 1.0, 1.0 + sin(p.x) * 0.5 + 0.5));
        if (k < d) {
            d = k;
            mat = 8.0;
        }
    }
    
    return d;
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

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    uv = uv * 2.0 - 1.0;
    uv.x *= resolution.x / resolution.y;

    vec3 r = normalize(vec3(uv, 1.0 - dot(uv, uv) * 0.33));
    vec3 o = vec3(0.0, 1.0, -4.0);
    
    r.yz *= rot(-0.25);
    
    r.xz *= rot(3.141592 * 0.25 + sin(time * 0.5) * 0.25);
    o.xz *= rot(3.141592 * 0.25 + sin(time * 0.5) * 0.25);
    
    o.x -= thetime() * 2.0 - 1.0;
    o.y -= -1.0 + thetime();
    
    float t = trace(o, r);
    vec3 w = o + r * t;
    vec3 sn = normal(w);
    
    vec3 sc = vec3(1.0);
    
    if (mat != 8.0) {
        if (mod(thetime(), 2.0) < 1.0) {
            mat = 7.0 - mat;
        }
        sc.xz *= rot(1.0 + mat * 0.5);
        sc = sc * 0.5 + 0.5;
    } else {
        sc = vec3(1.0, 0.0, 0.0);
    }
    
    vec3 fogc = vec3(0.0);//texture(iChannel0, r).xyz;
    
    float prod = max(dot(sn, -r), 0.0);
    sc *= prod;
    
    float fog = 1.0 / (1.0 + t * t * 0.01);
    
    float aoc = map(w + sn * 1.3);
    
    vec3 fc = mix(fogc, sc * mix(0.5, 1.0, aoc), fog);

    glFragColor = vec4(fc, 1.0);
}
