#version 420

// original https://neort.io/art/c79hf743p9f3hsjeb370

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;
uniform sampler2D backbuffer;

out vec4 glFragColor;

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
    float t = time * 0.7;
    for (int i = 0; i < 10; i++) {
        float r1 = rand(vec2(float(i) / 16.0 * 360.0)) * 2.0 - 1.0;
        float r2 = rand(vec2(float(i) / 16.0 * 540.0)) * 2.0 - 1.0;
        vec3 m = vec3(
            cos(t * r1) * r,
            sin(t * r2) * r,
            0.0
        );
        d = smin(d, sphere(p + m, 0.5), 0.9);
        shadow_d = smin(shadow_d, sphere(p + m + vec3(0.2, 0.9, 0.9), 0.5), 0.9);
    }
    
    float noise = rand(p.xz);
    obj o1 = obj(d, mix(vec3(0.2, 0.7, 0.1), vec3(0.1, 0.5, 0.9), noise), vec3(0.8, 0.9, 0.1));
    vec3 ns = mix(vec3(0.0, 0.25, 0.31), vec3(0.05, 0.19, 0.3), noise) * 1.4;
    ns = vec3(0.0, 0.25, 0.31) * 1.5;
    obj o2 = obj(shadow_d, ns, ns);
    return addObj(o1, o2);
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
    
    vec3 color = vec3(0.15, 0.5, 0.6);
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
