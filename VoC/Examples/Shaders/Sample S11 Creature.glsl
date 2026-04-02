#version 420

// original https://www.shadertoy.com/view/WdcBR4

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

mat2 rot(float a) {
    float s = sin(a), c = cos(a);
    return mat2(c, -s, s, c);
}

float sph(vec3 p, float r) {
    return length(p) - r;
}

float box(vec3 p, vec3 s) {
    vec3 q = abs(p) - s;
    return max(q.x, max(q.y, q.z));
}

vec3 smin(vec3 a, vec3 b, float h) {
    vec3 k = clamp((a - b) / h * .5 + .5, 0., 1.);
    return mix(a, b, k) - k * (1. - k) * h;
}

float map(vec3 p) {
    float t = time * .2;
    float s = 1.;
    for (float i = 0.; i < 5.; i++) {
        p -= 0.05 * i;
        p.xy *= rot(t * i);
        p.yz *= rot(t - i * 0.9 + 12.34);
        p.zx *= rot(t + i * 1.3);
        p = smin(p, -p, -s * 2.5);
        p -= s;
        s *= 0.5 ;
    }
    
    return box(p, vec3(0.5));
}

vec3 norm(vec3 p) {
    vec2 e = vec2(0.01, 0);
    return normalize(map(p) - vec3(map(p - e.xyy), map(p - e.yxy), map(p - e.yyx)));
}

void cam(inout vec3 p) {
    float t = time;
    p.zx *= rot(t * 0.1);
    p.zy *= rot(t * 0.2);
}

vec3 bg(vec3 r) {
    float k = r.y * .5 + .5;
    return mix(vec3(.3, .5, .9), vec3(.3, .1, .1), k);
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy - .5 * resolution.xy) / resolution.y;
    
    int tx = int(uv.x * 512.);
    float fft = 0.0; //texelFetch(iChannel0, ivec2(tx, 0), 0).x;
    float wave = 0.0; //texelFetch(iChannel0, ivec2(tx, 1), 0).x;

    vec3 s = vec3(0, 0, -12);
    vec3 r = normalize(vec3(-uv, 1));
    
    cam(s);
    cam(r);
    
    vec3 col = vec3(0);
    
    col += bg(r);

    vec3 p = s;
    float dd = 0.;
    float side = sign(map(p));
    float prod = 1., spec;
    float maxdist = 100.;
    vec3 n, l, h;
    for (int i = 0; float(i) < maxdist; i++) {
        float d = map(p) * side;
        if (d < .01) {
            n = norm(p) * side;
            l = normalize(vec3(-1, -1, -2));
            if (dot(n, l) < 0.) l = -l;
            h = normalize(l - r);
            spec = .1 + .2 * pow(max(0., dot(n, l)), 20.);
            
            col += bg(reflect(r, n)) * 0.01;
            col += max(0., dot(n, l)) * spec * prod;
            
            side = -side;
            d = 0.1;
            prod *= 0.7;
            r = refract(r, n, 1. - .2 * side);
            //break;
        }
        if (dd > maxdist) {
            dd = maxdist;
            break;
        }
        p += r * d;
        dd += d;
    }
    
    glFragColor = vec4(col,1.0);
}
