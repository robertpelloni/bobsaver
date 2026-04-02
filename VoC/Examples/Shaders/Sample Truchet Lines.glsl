#version 420

// original https://www.shadertoy.com/view/NtXXRS

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const int MAX_STEPS = 100;
const float MAX_DIST = 50.0;
const float MIN_DIST = 0.001;
const float PI = 3.1415;

mat2 rot(float r) {
    float s = sin(r), c = cos(r);
    return mat2(c, -s, s, c);
}

float rand1(vec3 p) {
    return fract(sin(dot(p, vec3(12.9898, 78.233, 42.1581))) * 43758.5453123);
}

float sdBox(vec3 p, vec3 s) {
    vec3 m = abs(p) - s;
    return length(max(m, 0.0)) + min(max(m.x, max(m.y, m.z)), 0.0);
}

float sdSphere(vec3 p, float r) {
    return length(p) - r;
}

vec3 closestPointLine(vec3 p, vec3 a, vec3 b) {
    vec3 ab = b - a;
    float d = clamp(dot(p - a, ab) / dot(ab, ab), 0.0, 1.0);
    if(d < 0.0) return a; if(d > 1.0) return b; return mix(a, b, d);
}

float sdLine(vec3 p, vec3 a, vec3 b, float r) { return length(p - closestPointLine(p, a, b)) - r; }

float sdTruchet(vec3 p, float r) {
    r *= 2.0;
    float d = min(min(min(sdSphere(p + vec3(0.5, 0.0, 0.0), r), sdSphere(p - vec3(0.5, 0.0, 0.0), r)), min(sdSphere(p + vec3(0.0, 0.5, 0.0), r), sdSphere(p - vec3(0.0, 0.5, 0.0), r))), min(sdSphere(p + vec3(0.0, 0.0, 0.5), r), sdSphere(p - vec3(0.0, 0.0, 0.5), r)));
    r *= 0.5;
    d = min(d, sdLine(p, vec3(0.0, 0.5, 0.0), vec3(0.0, 0.0, 0.5), r));
    d = min(d, sdLine(p, vec3(0.0, -0.5, 0.0), vec3(0.5, 0.0, 0.0), r));
    d = min(d, sdLine(p, vec3(-0.5, 0.0, 0.0), vec3(0.0, 0.0, -0.5), r));
    return d;
}

float map(vec3 p) {
    vec3 i = floor(p);
    vec3 m = p - i - 0.5;
    m.xz *= rot(floor(rand1(i) * 4.0) * PI * 0.5);
    m.xy *= rot(floor(rand1(i + 62.0) * 4.0) * PI * 0.5);
    m.yz *= rot(floor(rand1(i + 25.0) * 4.0) * PI * 0.5);
    return sdTruchet(m, 0.05);
}

float march(vec3 ro, vec3 rd) {
    float d = 0.0;
    for(int i = 0; i < MAX_STEPS; i++) {
        float ds = map(ro + (rd * d));
        d += ds;
        if(d > MAX_DIST) return MAX_DIST;
        if(abs(ds) <= MIN_DIST) return d;
    }
    return MAX_DIST;
}

vec3 normal(vec3 p) {
    vec2 e = vec2(MIN_DIST, 0.0);
    return normalize(vec3(
        map(p + e.xyy) - map(p - e.xyy),
        map(p + e.yxy) - map(p - e.yxy),
        map(p + e.yyx) - map(p - e.yyx)
    ));
}

vec4 getCol(vec3 ro, vec3 rd, out float d, out vec3 p, out vec3 n) {
    d = march(ro, rd);
    p = ro + (rd * d);
    n = normal(p);

    vec3 col = vec3(sin(p * PI * 0.25) * 0.5 + 0.5);
    
    vec3 light = vec3(0.0);
    
    light += 1.4 * clamp(dot(n, normalize(vec3(0.7, 1.0, -0.5))), 0.0, 1.0);
    light += 0.2;

    col *= light;
    col = mix(col, vec3(0.2, 0.2, 0.2), smoothstep(0.0, MAX_DIST, d));

    return vec4(col, 1.0);
}

vec4 image(vec2 i, float t) {
    vec2 uv = (i.xy - (0.5 * resolution.xy)) / min(resolution.x, resolution.y);
    
    vec3 ro = vec3(0., 0.0, time * 0.5);
    vec3 rd = normalize(vec3(uv, 1.0));

    rd.yz *= rot(sin(time * PI * 0.05) * PI * 0.125);
    rd.xz *= rot(cos(time * PI * 0.05) * PI * 0.125);

    vec4 col = vec4(0.0);

    float factor = 1.0;
    
    for(int i = 0; i < 3; i++) {
        if(factor < 0.001) break;
        
        float d; vec3 p, n;
        vec4 tc = getCol(ro, rd, d, p, n);
        
        col = mix(col, tc, factor);
        
        factor *= 0.2;
        
        ro = p + (n * MIN_DIST * 2.0);
        rd = reflect(rd, n);
    }
    
    col *= smoothstep(2.2, -0.5, length(uv));

    return col;
}

void main(void) {
    glFragColor = image(gl_FragCoord.xy, time);
}
