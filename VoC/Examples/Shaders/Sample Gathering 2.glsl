#version 420

// original https://neort.io/art/c6mde6c3p9f1mfrqj520

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;
uniform sampler2D backbuffer;

out vec4 glFragColor;

#define PI acos(-1.0)
#define TAU 6.283185
#define ITER 64.0

struct obj{
    float d;
    vec3 c_shadow;
    vec3 c_light;
};

mat2 rot(float a) {
    return mat2(cos(a), sin(a), -sin(a), cos(a));
}

vec2 round(vec2 p) {
    return floor(p + 0.5);
}

vec2 crep(vec2 p, float c, float l) {
    return p - c * clamp(round(p / c), -l, l);
}

float dt(float speed, float off) {
    return fract((time + off) * speed);
}

float bounce(float speed, float off) {
    return sqrt(sin(dt(speed, off) * PI));  // sqrt() is important to intonate the animation.
}

float box(vec3 p, vec3 c) {
    vec3 q = abs(p) - c;
    return min(0.0, max(q.x, max(q.y, q.z))) + length(max(q, 0.0));
}

obj prim(vec3 p) {
    float size = 0.2;
    float num = 25.0;  // odd number is better.
    float per = size * 3.6;
    // id for each box
    vec2 id = round(p.xz / per);

    // bounce
    float bounceSpeed = 0.8;
    float bounceOffset = length(id * 0.15);
    float b = bounce(bounceSpeed, bounceOffset);
    p.y -= b * 0.2;

    // repetition
    p.xz = crep(p.xz, per, floor(num * 0.5));

    // rotate
    p.xz *= rot(sin(dt(bounceSpeed, bounceOffset) * PI / 2.0) * TAU);

    float sy = size * b * 2.;
    // box
    float d = box(p, vec3(size, sy, size));

    float l = 1.0 * sy;
    return obj(d, vec3(0.0, l, 0.8), vec3(0.4, 0.85, 0.99));
}

obj SDF(vec3 p) {
    p.yz *= rot(-atan(1.0 / sqrt(2.0)));
    p.xz *= rot(TAU / 8.0);  // 45 degree (≒ TAU * 45.0 / 360.0)
    obj scene = prim(p + vec3(0.0));
    return scene;
}

vec3 getNorm(vec3 p) {
    vec2 eps = vec2(0.001, 0.0);
    return normalize(SDF(p).d - vec3(SDF(p - eps.xyy).d, SDF(p - eps.yxy).d, SDF(p - eps.yyx).d));
}

void main(void) {
    vec2 uv = (gl_FragCoord.xy * 2.0 - resolution.xy) / min(resolution.x, resolution.y);
    
    vec3 ro  = vec3(uv * 5.0, -40.0),
         rd  = vec3(0.0, 0.0, 1.0),
         p   = ro,
         col = vec3(0.85, 0.85, 0.6),
         l   = normalize(vec3(1.0, 2.0, -2.0));
    
    bool hit = false;
    obj o;
    
    for (float i = 0.0; i < ITER; i++) {
        o = SDF(p);
        if (o.d < 0.001) {
            hit = true;
            break;
        }
        p += o.d * rd;
    }
    
    if (hit) {
        vec3 n = getNorm(p);
        float lighting = max(dot(n, l), 0.0);
        col = mix(o.c_shadow, o.c_light, lighting);
    }
    
    vec3 color = vec3(sqrt(col));

    glFragColor = vec4(color, 1.0);
}
