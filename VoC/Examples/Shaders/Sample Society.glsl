#version 420

// original https://neort.io/art/c7nt9uk3p9fbll0nrjtg

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;
uniform sampler2D backbuffer;

out vec4 glFragColor;

vec3 backgroundColor = vec3(0.15, 0.0, 0.6);
vec3 ballColor = vec3(0.8, 0.3, 0.4);

#define PI 3.141592653589793

struct obj{
    float d;
    vec3 shadow;
    vec3 light;
};

float sphere(vec3 p, float r) {
    return length(p) - r;
}

float box(vec3 p, vec3 c) {
    vec3 q = abs(p) - c;
    return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);
}

/**
 * Meta ball
 */
float smin(float a, float b, float k) {
    float h = max(k - abs(a - b), 0.0);
    return min(a, b) - h * h * 0.25 / k;
}

float rand(vec2 co){
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

obj addObj(obj a, obj b) {
    if (a.d < b.d) {
        return a;
    } else {
        return b;
    }
}

obj dist(vec3 p) {
    float d = 1.0;
    
    float shadow_d = 1.0;
    float r = 2.0;
    float t = time * 0.1;
    for (int i = 0; i < 12; i++) {
        float r1 = rand(vec2(float(i) / 16.0 * 360.0)) + 0.1;
        float r2 = rand(vec2(float(i) / 16.0 * 540.0)) * 2.0 - 1.0;
        float _t = 360.0 * fract(t * float(i) * 0.13) * PI / 180.0;
        vec3 m = vec3(
            cos(_t) * r,
            // sin(t + float(i) * 0.2) * r,
            sin(_t) * r,
            0.0
        );
        float size = 0.15;
        d = smin(d, sphere(p + m, size), 0.9);
        shadow_d = smin(shadow_d, sphere(p + m + vec3(0.2, 0.4, 0.6), size), 0.9);
    }
    
    float noise = rand(p.xz);
    obj o1 = obj(d, mix(vec3(0.2, 0.3, 0.5), vec3(0.5, 0.25, 0.8), noise), ballColor);
    vec3 ns = backgroundColor * 0.85;
    obj o2 = obj(shadow_d, ns, ns);
    
    // Floor
    float theFloor = box(p + vec3(0.0, 0.0, 0.0), vec3(3.0, 0.25, 0.5));
    d = smin(o1.d, theFloor, 0.5);
    obj o12 = addObj(obj(d, o1.shadow, o1.light), o1);

    return addObj(o12, o2);
}

vec3 getNorm(vec3 p) {
    vec2 e = vec2(0.001, 0.0);
    return normalize(vec3(
        dist(p + e.xyy).d - dist(p - e.xyy).d,
        dist(p + e.yxy).d - dist(p - e.yxy).d,
        dist(p + e.yyx).d - dist(p - e.yyx).d
    ));
}

void main(void) {
    vec2 uv = (gl_FragCoord.xy * 2.0 - resolution.xy) / min(resolution.x, resolution.y);
    
    float t = time;
    float r = 3.0;
    vec3 target = vec3(0.0, 0.0, 0.0);
    vec3 cameraPos = vec3(cos(t) * r, 0.0, sin(t) * r);
    cameraPos = vec3(0.0, 0.0, r);
    vec3 cameraDir = normalize(target - vec3(0.0, 0.0, 1.0) - cameraPos);
    // vec3 cameraDir = vec3(0.0, 0.0, -1.0);
    vec3 cameraSide = normalize(cross(cameraDir, vec3(0.0, 1.0, 0.0)));
    vec3 cameraUp = normalize(cross(cameraSide, cameraDir));
    
    vec3 rayDir = normalize(uv.x * cameraSide + uv.y * cameraUp + cameraDir);
    
    vec3 rayPos = cameraPos;
    bool isHit = false;
    obj o;
    
    for (int i = 0; i < 64; i++) {
        o = dist(rayPos);
        
        if (abs(o.d) < 0.001) {
            isHit = true;
            break;
        }
        
        rayPos += o.d * rayDir;
    }
    
    vec3 color = backgroundColor;
    if (isHit) {
        vec3 n = getNorm(rayPos);
        vec3 light = vec3(0.0, 1.0, 1.0);
        float diff = max(dot(light, n), 0.0);
        float f = rand(uv * 1.0);
        // color = mix(mix(vec3(0.1, 0.6, 0.9), o.light, f), o.light, diff);
        color = mix(o.shadow, o.light, diff);
    }

    glFragColor = vec4(color, 1.0);
}
