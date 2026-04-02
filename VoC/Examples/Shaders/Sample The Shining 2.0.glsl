#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/tlyfDV

uniform int frames;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// 'pow(The Shining, 2.0)' dean_the_coder (Twitter: @deanthecoder)
// https://www.shadertoy.com/view/tlyfDV
//
// Another 'Shining' corridor scene, this time playing
// with a recursive camera path - A first for me, and
// fun to make!
//
// My previous Shining scene here:
//   https://www.shadertoy.com/view/3stBDf
//
// Thanks to Evvvvil, Flopine, Nusan, BigWings, Iq, Shane,
// Blackle and a bunch of others for sharing their knowledge!

#define MIN_DIST         .0015
#define MAX_DIST         20.0
#define MAX_STEPS         64.0
#define SHADOW_STEPS     30.0
#define MAX_SHADOW_DIST  20.0

#define Z0 min(time, 0.)
#define sat(x) clamp(x, 0., 1.)
#define S(x) smoothstep(0., 1., x)

float g = 0.0, // Glow.
      bld = 1.0; // Blood.

#define AA    // Enable this line if your GPU can take it!

struct Hit {
    float d, id;
    vec3 uv;
};

// Thnx Dave_Hoskins - https://www.shadertoy.com/view/4djSRW
#define HASH    p = fract(p * .1031); p *= p + 3.3456; return fract(p * (p + p));
float hash11(float p) { HASH }
vec2 hash22(vec2 p) { HASH }

float hash31(vec3 p3)
{
    p3  = fract(p3 * .1031);
    p3 += dot(p3, p3.yzx + 3.3456);
    return fract((p3.x + p3.y) * p3.z);
}

vec4 hash44(vec4 p) { HASH }

float n31(vec3 p) {
    // Thanks Shane - https://www.shadertoy.com/view/lstGRB
    const vec3 s = vec3(7, 157, 113);
    vec3 ip = floor(p);
    p = fract(p);
    p = p * p * (3. - 2. * p);

    vec4 h = vec4(0, s.yz, s.y + s.z) + dot(ip, s);
    h = mix(hash44(h), hash44(h + s.x), p.x);

    h.xy = mix(h.xz, h.yw, p.y);
    return mix(h.x, h.y, p.z);
}

float n21(vec2 p) {
    // Thanks Shane - https://www.shadertoy.com/view/lstGRB
    const vec3 s = vec3(7, 157, 0);
    vec2 ip = floor(p);
    p = fract(p);
    p = p * p * (3. - 2. * p);

    vec2 h = s.zy + dot(ip, s.xy);
    h = mix(hash22(h), hash22(h + s.x), p.x);

    return mix(h.x, h.y, p.y);
}

void minH(inout Hit a, Hit b) {
    if (b.d < a.d) a = b;
}

mat2 rot(float a) {
    float c = cos(a), s = sin(a);
    return mat2(c, s, -s, c);
}

float sdHex(vec2 p, float r) {
    p = abs(p);
    return -step(max(dot(p, normalize(vec2(1, 1.73))), p.x), r);
}

float sdBox(vec3 p, vec3 b) {
    vec3 q = abs(p) - b;
    return length(max(q, 0.)) + min(max(q.x, max(q.y, q.z)), 0.);
}

vec3 rayDir(vec3 ro, vec3 lookAt, vec2 uv) {
    vec3 f = normalize(lookAt - ro),
         r = normalize(cross(vec3(0, 1, 0), f));
    return normalize(f + r * uv.x + cross(f, r) * uv.y);
}

float deco(vec2 p) {
    p.xy = fract(p.xy * rot(-2.36) * 1.5);
    return step(0.5, fract(min(p.x, p.y) * 4.0));
}

void splat(vec2 p, out float i, out float o) {
    i = max(0., -sign(sdHex(p, 1.)));
    o = max(0., sign(sdHex(p, 2.)) - sign(sdHex(p, 3.)));
}

// Carpet texture.
vec3 carpet(vec2 p) {
    p.x = mod(p.x, 7.) - 3.5;
    p.y = mod(p.y, 10.) - 10.;

    float i, o, i2, o2,
    c = (1. - step(.5, abs(p.x))) * (1. - step(2., abs(p.y)));

    p.x = abs(p.x) - 3.5;

    c += (1. - step(.5, abs(p.x))) * (1. - step(2., abs(p.y + 2.)));

    vec2 op = p;

    p.y = abs(p.y + 5.) - 5.;
    splat(p, i2, o2);

    op.x = mod(p.x, 7.) - 3.5;
    op.y += 3.8;
    splat(op, i, o);

    i = sign(i + i2);
    o = sign(o + o2) * (1. - c);

    return vec3(1, .01, .01) * i +
           vec3(1, .1, .01) * o +
           vec3(.05, .01, .01) * (1. - i - o);
}

#define GROUND_ID  1.
#define WALL_ID    2.
#define CANVAS_ID  3.
#define FRAME_ID   4.
#define LIGHT_ID   5.
#define WOOD_ID    6.

#define FRAME_P    vec3(2.5, 2.7, -0.12)
#define RO         vec3(-7, 2.4, -3)
#define LA         vec3(10, 2.4, -3)
#define LIGHTP     vec3(3.4, 3.5, -2.6)

Hit map(vec3 p) {
    Hit h = Hit(abs(p.y), GROUND_ID, p);
    
    float d = length(p - LIGHTP - vec3(0,1.5,0)) - 0.4;
    minH(h, Hit(d, LIGHT_ID, p));
    g += 0.002 / (0.001 + d * d);
    
    // Wallz.
    d = min(sdBox(p - vec3(0,2.2,0), vec3(5, 3, 0.1)), -sdBox(p - vec3(0,2.4,0) - vec3(0,0,4), vec3(10, 2.5, 9.5)));
    minH(h, Hit(min(d, max(abs(p.x) - 0.15, -sdBox(p + vec3(0,0,2.8), vec3(1, 4.5, 2.6)))), WALL_ID, p));

    // Skirting.
    d = min(sdBox(p - vec3(0, 0, 0), vec3(5, .38, 0.15)), sdBox(p - vec3(0, 0, -5.6), vec3(10, .38, 0.15)));
    d = min(d, min(d, sdBox(p - vec3(10, 0, -5.6), vec3(.15, .38, 9))));
    vec3 mp = p; mp.z = abs(mp.z + 2.8) - 2.65;
    minH(h, Hit(min(d, sdBox(mp, vec3(.2, .38, .1))), WOOD_ID, p));

    // Picture frame.
    p -= FRAME_P;
    vec3 cs = vec3(0.885, 0.5, 0.01);
    minH(h, Hit(sdBox(p, cs), CANVAS_ID, p));
    minH(h, Hit(max(sdBox(p, cs + 0.1), -sdBox(p, cs + vec3(0,0,1))), FRAME_ID, p));

    return h;
}

vec3 N(vec3 p, float t) {
    float h = t * 0.4;
    vec3 n = vec3(0);
    for (int i = min(frames, 0); i < 4; i++) {
        vec3 e = .005773 * (2. * vec3(((i + 3) >> 1) & 1, (i >> 1) & 1, i & 1) - 1.);
        n += e * map(p + e * h).d;
    }

    return normalize(n);
}

float shadow(vec3 p, vec3 ld) {
    // Thanks iq.
    float s = 1., t = .1;
    for (float i = Z0; i < SHADOW_STEPS; i++)
    {
        float h = map(t * ld + p).d;
        s = min(s, 15. * h / t);
        t += h;
        if (s < .001 || t > MAX_SHADOW_DIST) break;
    }

    return sat(s);
}

// Quick ambient occlusion.
float ao(vec3 p, vec3 n, float h) { return map(h * n + p).d / h; }

/**********************************************************************************/

vec3 vig(vec3 c, vec2 fc) {
    vec2 q = fc.xy / resolution.xy;
    c *= .5 + .5 * pow(16. * q.x * q.y * (1. - q.x) * (1. - q.y), .4);
    return c;
}

vec3 lights(vec3 p, vec3 rd, float d, Hit h) {
    float gg = g, s = 0.0;
    vec3 ld = normalize(LIGHTP - p), n = N(p, d), c = vec3(0);
         
    if (h.id == WALL_ID) {
        n = normalize(n + n31(h.uv * vec3(3.7, 1.7, 2.7)) * 0.08);
        if (p.x < 9.99)
            c = vec3(0.4);
        else {
            s = deco(p.zy);
            c = (0.1 + 0.2 * s) * vec3(0.05, 0.15, 0.1);
        }
    } else if (h.id == GROUND_ID)
        c = carpet(h.uv.zx * 3.5) * ((n21(p.xz * 85.0) - 0.5) * 0.4 + 0.6);
    else if (h.id == FRAME_ID)
        c = vec3(0.01);
    else if (h.id == WOOD_ID)
        c = 0.02 * mix(vec3(1.7, 1, .5), vec3(.8, .5, .3), vec3(hash11(hash31(p.yxz * vec3(0, 1, 30)))));
    
    if (bld > 0.0)
        c = mix(vec3(.3,0,0), vec3(dot(c, vec3(.2, .72, .08))), sat((p.y * .5 + .5) * n31(p) / (0.1 + n31(p * vec3(9, 2, 9)))));

    // Primary light.
    float l1 = sat(.1 + .9 * dot(ld, n))
               * (0.6 + 0.4 * shadow(p, ld)),

    // Secondary(/bounce) light.
    l2 = sat(.1 + .9 * dot(ld * vec3(-1, 0, -1), n)) * .3

    // Specular.
         + pow(sat(dot(rd, reflect(ld, n))), 10.0 + s * 10.0) * (0.6 + s),

    // Combine into final color.
    lig = l1 + l2 * mix(ao(p, n, .2), ao(p, n, 0.5), .3);
    g = gg;
    return lig * c * vec3(2, 1.8, 1.7);
}

vec3 march(vec3 p, vec3 rd) {
    float d = .0;
    vec3 ro = p;
    Hit h;
    for (float i = Z0; i < MAX_STEPS; i++) {
        h = map(p);

        if (abs(h.d) < MIN_DIST) {
            if (h.id != CANVAS_ID) break;
            bld = 1.0 - bld; // Toggle the blood.
            p = RO;
            g = d = 0.0;
            rd = rayDir(RO, LA, h.uv.xy);
            continue;
        }

        d += h.d;
        if (d > MAX_DIST)
            return vec3(0);

        p += h.d * rd; // No hit, so keep marching.
    }

    return g + lights(p, rd, d, h);
}

void main(void)
{
    // Camera.
    float t = fract(time * 0.2);
    bld = floor(mod(time / 5.0, 2.0));
    vec3 ro = mix(RO, vec3(FRAME_P.x, RO.yz), t);
    
    t *= .88056;
    vec3 fp = FRAME_P + vec3(0, .1, 0);
    vec3 lookAt = mix(LA, fp + vec3(0, -.1, 0.1), S(t * 1.5));

    ro = mix(ro, fp, smoothstep(0.7, 1.0, t));

    vec2 uv = (gl_FragCoord.xy - .5 * resolution.xy) / resolution.y;
    vec3 col = march(ro, rayDir(ro, lookAt, uv));

#ifdef AA
    if (fwidth(col.r) > 0.1) {
        for (float dx = Z0; dx <= 1.; dx++)
            for (float dy = Z0; dy <= 1.; dy++)
                col += march(ro, rayDir(ro, lookAt, uv + (vec2(dx, dy) - 0.5) / resolution.xy));
        col /= 5.;
    }
#endif

    // Output to screen.
    glFragColor = vec4(vig(pow(sat(col * sat(time)), vec3(.45)), gl_FragCoord.xy), 0);
}
