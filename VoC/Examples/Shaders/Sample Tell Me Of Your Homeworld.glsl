#version 420

// original https://www.shadertoy.com/view/MsdBRH

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define EPSILON 0.01
#define MAXSTEPS 128
#define NEAR 0.1
#define FAR 100.0
#define TWOPI 6.28319

precision mediump float;

in vec2 vTextureCoord;

struct Camera {
    vec3 pos;
    vec3 dir;
};

float rand (vec2 st) {
    return fract(sin(dot(st.xy,vec2(12.9898,78.233)))*43758.5453123);
}

vec2 grad (vec2 st) {
    float nn = rand(st);
    return vec2(cos(nn * TWOPI), sin(nn * TWOPI));
}

float gradnoise (vec2 st) {
    // returns range -1, 1
    vec2 pa = floor(st);
    vec2 pb = pa + vec2(1.0, 0.0);
    vec2 pc = pa + vec2(0.0, 1.0);
    vec2 pd = pa + vec2(1.0);
    vec2 ga = grad(pa);
    vec2 gb = grad(pb);
    vec2 gc = grad(pc);
    vec2 gd = grad(pd);
    float ca = dot(ga, st - pa);
    float cb = dot(gb, st - pb);
    float cc = dot(gc, st - pc);
    float cd = dot(gd, st - pd);
    vec2 frast = fract(st);
    return mix(
        mix(ca, cb, smoothstep(0.0, 1.0, frast.x)),
        mix(cc, cd, smoothstep(0.0, 1.0, frast.x)),
        smoothstep(0.0, 1.0, frast.y));
}

float perlin (vec2 st, float scale, float freq, float persistence, float octaves) {
    float p = 0.0;
    float amp = 1.0;
    for (float i=0.0; i<octaves; i++) {
        p += gradnoise(st * freq / scale) * amp;
        amp *= persistence;
        freq *= 2.0;
    }
    return p;
}

float sdfSphere(vec3 p, float r) {
    return length(p) - r;
}

float sdfPerlin(vec3 p) {
    return p.y + 4.0 * perlin(p.xz, 6.0, 0.5, 0.5, 3.0) + 0.5;
}

float sceneSDF(vec3 p) {
    float moon1 = sdfSphere(p + vec3(-60.0, -40.0, -70.0), 5.0);
    float moon2 = sdfSphere(p + vec3(-30.0, -20.0, -70.0), 2.0);
    float land = sdfPerlin(vec3(p.x, p.y, p.z + time));
    return min(min(moon1, moon2), land);
}

vec3 sceneNormal(vec3 p) {
    float baseSDF = sceneSDF(p);
    vec3 unNorm = vec3(
        sceneSDF(vec3(p.x + EPSILON, p.y, p.z)) - baseSDF,
        sceneSDF(vec3(p.x, p.y + EPSILON, p.z)) - baseSDF,
        sceneSDF(vec3(p.x, p.y, p.z + EPSILON)) - baseSDF
    );
    return normalize(unNorm);
}

float distToSurface(Camera c, out vec3 ip) {
    float depth = NEAR;
    for (int i=0; i<MAXSTEPS; i++) {
        ip = c.pos + c.dir * depth;
        float distToScene = sceneSDF(ip);
        if (distToScene < EPSILON) {
            return depth;
        }
        depth += distToScene;
        if (depth >= FAR) {
            return FAR;
        }
    }
    return depth;
}

float lambert(vec3 norm, vec3 lpos) {
    return max(dot(norm, normalize(lpos)), 0.0);
}

void main(void) {
    vec2 uv = (gl_FragCoord.xy / resolution.xy) * 2.0 - 1.0;
    uv.x *= resolution.x / resolution.y;
    vec3 nrmDir = normalize(vec3(uv, 1.0));
    Camera camera = Camera(vec3(0.0, 2.0, -3.0), nrmDir);
    vec3 endPt;
    float t = distToSurface(camera, endPt);
    vec3 ambi = vec3(0.01, 0.001, 0.001);
    vec3 sky = mix(vec3(0.1,0.2,1.0), vec3(1.0), smoothstep(0.0, 1.0, 1.0 - uv.y / 2.0 - 0.5));
    vec3 col = sky;

    if (t < FAR) {
        vec3 nrm = sceneNormal(endPt);
        vec3 lpos = vec3(-1.0, 0.5, -0.4); // light position
        vec3 diff = vec3(0.6, 0.17, 0.01); // landscape diffuse
        col = ambi + diff * lambert(nrm, lpos);
        if (endPt.y < 10.0) {
            col = mix(col, sky, length(endPt) / FAR);
        }
        else {
            col = sky + vec3(0.5) * lambert(nrm, lpos);
        }
    }

    col = pow(col, vec3(1.0 / 2.2));
    glFragColor = vec4(col, 1.0);
}
