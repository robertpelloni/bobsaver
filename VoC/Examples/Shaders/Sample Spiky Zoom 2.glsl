#version 420

// original https://www.shadertoy.com/view/WddGD4

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

mat2 rot(float x) {
    return mat2(cos(x), sin(x), -sin(x), cos(x));
}

float spike(vec3 p, float w) {
    float len = 0.7;
    vec3 q = p;
    p.z = -(abs(p.z) - len);
    float a = length(p.xy) - p.z * w;
    return a;
}

float box(vec3 p) {
    return max(max(abs(p.x) - 0.25, abs(p.y) - 0.5), abs(p.z) - 0.5);
}

float mapmat = 0.0;

float map(vec3 p) {
    mapmat = 0.0;
    float d = 1000.0;
    for (int j = -1; j <= 1; ++j) {
        vec3 q = p;
        float s = 1.0;
        float nz = floor(q.z / s) - float(j) / s;
        q.z = (fract(q.z / s) - 0.5) * s;
        q.z += float(j) * s;
        q.xy *= rot(3.141592 * 0.25 * nz);
        q.xy = abs(q.xy) - 1.5;
        for (int i = 0; i < 3; ++i) {
            float b = box(q);
            if (b < d) {
                d = b;
                mapmat = 0.0;
            }
            q.xy = abs(q.xy) - 0.25;
            q.xy *= rot(3.141592 * 0.125);
            q.yz *= rot(3.141592 * 0.125);
        }
        float g = -spike(q.yzx, 0.15);
        if (g > d) {
            d = g;
            mapmat = 0.0;
        }
        float k = spike(q.yzx, 0.1);
        if (k < d) {
            d = k;
            mapmat = 1.0;
        }
    }
    return d;
}

vec3 normal(vec3 p) {
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
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    uv = uv * 2.0 - 1.0;
    uv.x *= resolution.x / resolution.y;
    
    vec3 r = normalize(vec3(uv, 1.5));
    vec3 o = vec3(0.0, 0.0, 0.0);
    
    r.xy *= rot(3.141592 * 0.125);
    r.xz *= rot(sin(time * 0.25) * 0.1);
    
    o.z += time;
    
    float t = trace(o, r);
    float mat = mapmat;
    vec3 w = o + r * t;
    vec3 sn = normal(w);
    float fd = map(w + sn * 1.0);
    float fade = map(w);
    fade = 1.0 / (1.0 + fade * fade * 100.0);
    
    vec3 ldir = normalize(vec3(0.0, 0.0, sign(sn.z)));
    vec3 ref = reflect(r, sn);
    float spec = max(dot(ldir, -ref), 0.0);
    spec = pow(spec, 2.0);
    float eye = max(dot(r, -sn), 0.0);
    
    float fog = 1.0 / (1.0 + t * t * 0.1);
    
    vec3 col1 = vec3(0.25, 0.75, 1.0);
    vec3 col2 = vec3(1.0, 0.25, 0.1);
    vec3 col = mix(col1, col2, mat);
    
    vec3 fc = col;
    fc += col1 * vec3(2.0) * abs(sn.z);
    fc = (fc + spec * col + eye * col + col2 * (1.0 - spec)) * fd * fade * fog;

    glFragColor = vec4(fc, 1.0);
}
