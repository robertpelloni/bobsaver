#version 420

// original https://www.shadertoy.com/view/fdBfD1

uniform int frames;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// 'Aliens (Scanner scene)' dean_the_coder (Twitter: @deanthecoder)
// https://www.shadertoy.com/view/fdBfD1 (YouTube: https://youtu.be/yimsQfjK8es)
//
// Processed by 'GLSL Shader Shrinker'
// (https://github.com/deanthecoder/GLSLShaderShrinker)
//
// Another Aliens-themed shader, motivated by me watching
// this clip from the movie: https://youtu.be/3HbkcRAQhew
// I try to add add something new each time I make a shader,
// and this time it was the 'frost' effect on the cryo pod.
// Definitely an effect I want to come back to in the future!
//
// Tricks to get the performance:
//   - No 'max dist' raymarch check needed, as the room is enclosed.
//   - Reflective helmet glass and laser effect calculated using
//     ray-sphere ray-plane intersections, allowing me to keep
//     the raymarching loop simple.
//
// Thanks to Evvvvil, Flopine, Nusan, BigWings, Iq, Shane,
// totetmatt, Blackle, Dave Hoskins, byt3_m3chanic, tater,
// and a bunch of others for sharing their time and knowledge!
//
// License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License

#define MIN_DIST    .0015
#define MAX_STEPS    120.0
#define SHADOW_STEPS    30.0

#define LIGHT_RGB    vec3(0.1, 0.6, 1.4)
#define FOG_RGB    vec3(0.03, 0.04, 0.05)
#define R    resolution
#define Z0    min(time, 0.)
#define sat(x)    clamp(x, 0., 1.)
#define S(a, b, c)    smoothstep(a, b, c)
#define S01(a)    S(0.0, 1.0, a)

float t,
      g = 0.0;

float h31(vec3 p3) {
    p3 = fract(p3 * .1031);
    p3 += dot(p3, p3.yzx + 333.3456);
    return fract((p3.x + p3.y) * p3.z);
}

float h21(vec2 p) { return h31(p.xyx); }

float n31(vec3 p) {
    // Thanks Shane - https://www.shadertoy.com/view/lstGRB
    const vec3 s = vec3(7, 157, 113);
    vec3 ip = floor(p);
    p = fract(p);
    p = p * p * (3. - 2. * p);
    vec4 h = vec4(0, s.yz, s.y + s.z) + dot(ip, s);
    h = mix(fract(sin(h) * 43758.5453), fract(sin(h + s.x) * 43758.5453), p.x);
    h.xy = mix(h.xz, h.yw, p.y);
    return mix(h.x, h.y, p.z);
}

float n21(vec2 p) { return n31(vec3(p, 1)); }

float fbm(vec3 p) {
    float a = 0.0,
          b = 0.5, i;
    for (i = Z0; i < 4.0; i++) {
        a += b * n31(p);
        b *= 0.5;
        p *= 2.0;
    }
    
    return a * 0.5;
}

float min2(vec2 v) { return min(v.x, v.y); }
float max2(vec2 v) { return max(v.x, v.y); }
float max3(vec3 v) { return max(v.x, max(v.y, v.z)); }

bool intPlane(vec3 p0, vec3 n, vec3 ro, vec3 rd, out float d) {
    float denom = dot(n, rd);
    if (abs(denom) > 0.0001) {
        d = dot(p0 - ro, n) / denom;
        return d >= 0.0;
    }

    return false;
}

bool intSph(vec3 p0, float r, vec3 ro, vec3 rd, out float d) {
    vec3 oc = ro - p0;
    float a = dot(rd, rd),
          b = dot(oc, rd),
          c = dot(oc, oc) - r * r,
          e = b * b - a * c;
    if (e <= 0.0) return false;
    d = b > 0.0 ? (-b + sqrt(e)) / a : (-b - sqrt(e)) / a;
    return true;
}

mat2 rot(float a) {
    // Thanks Fabrice.
    return mat2(cos(a + vec4(0, 11, 33, 0)));
}

float box(vec3 p, vec3 b) {
    vec3 q = abs(p) - b;
    return length(max(q, 0.)) + min(max3(q), 0.);
}

float cyl(vec3 p, vec2 hr) {
    vec2 d = abs(vec2(length(p.xy), p.z)) - hr;
    return length(max(d, 0.));
}

float cap(vec3 p, float h, float r) {
    p.x -= clamp(p.x, 0., h);
    return length(p) - r;
}

vec3 rayDir(vec3 ro, vec3 lookAt, vec2 uv) {
    vec3 f = normalize(lookAt - ro),
         r = normalize(cross(vec3(0, 1, 0), f));
    return normalize(f + r * uv.x + cross(f, r) * uv.y);
}

float hatch(vec3 p, float ex) {
    float d = box(p, vec3(2, 2.5, ex + .3));
    p.xy *= rot(3.1415 / 4.);
    return max(d, box(p, vec2(2.7, 2.7 + ex).xxy));
}

#define LP    vec3(0, -0.4, 3.5)

vec3 rigP() {
    float tt = t;
    if (tt > 47.0) tt = 16.0 - tt + 47.0;
    return vec3(0, 0.5, 6) +
      S(vec3(0.5, 0.7, 1), vec3(0.0, 0.2, 0.3), vec3(S(1.0, 13.0, tt))) * vec3(-2.4, 1.6, 5);
}

float map(vec3 p) {
    // Walls.
    float d = abs(box(p, vec3(8, 4, 10)) - 0.5) - 0.5;
    d = max(d, -hatch(p - vec3(0, 0, 8), 3.));
    d = min(d, 20. - p.z);

    // Wall posts.
    vec3 tp = p;
    tp.x = abs(tp.x);
    tp.xz -= vec2(7, 9);
    d = min(d, box(tp, vec3(1. + p.y * 0.15, 4, 0.5)));
    d = min(d, abs(p.y) * -0.15 - tp.x);

    // Hatch.
    tp = p - vec3(0.8, -3.4, 7);
    tp.yz *= rot(1.4);
    tp.xy *= rot(0.2);
    d = min(d, hatch(tp, 0.0));

    // Laser rig.
    tp = p - rigP();
    d = min(d, cyl(tp, vec2(0.05, .1))); // Nozzle.
    tp.yz += vec2(0.15, -1.0);
    d = min(d, box(tp, vec3(0.3, 0.3, 1))); // Barrel.
    d = min(d, box(tp - vec3(0, 0.15, 0), vec3(0.25, 0.25, 0.9))); // Heat sinks.
    tp.y += 0.3;
    d = min(d, max(box(tp, vec3(0.4, 0.45, 0.4)), -box(tp, vec3(0.3, 0.4, 0.5))));
    tp.xz += vec2(.5, 0.4);
    d = min(d, cap(tp.yzx, 1.2, S(0.0, -0.1, tp.y - 0.8) * 0.04 + .02));
    tp -= vec3(0.0, -0.24, 2.4);
    d = min(d, max(box(tp, vec3(0.2, 0.15, 2)), -tp.x - tp.z - 2.)); // Front support.
    vec3 mp = tp.zyx + vec3(1.5, 0, 0.22);
    mp.y = abs(mp.y) - 0.06;
    d = min(d, cap(mp, 2., .1)); // Pipes.
    tp.z -= 4. - 1.8;
    tp.xz *= rot(1.);
    tp.z -= 1.8;
    d = min(d, box(tp, vec3(0.2, 0.3, 2))); // Rear support.
    
    // Panel-thing.
    tp = p + vec3(0, 3, 2.5);
    tp.xz = abs(tp.xz);
    tp.z -= 3.;
    d = min(d, max(box(tp, vec3(3, 1.5, 1)), tp.x + tp.y * 0.5 - 3.2));

    // Lighty-boxes.
    tp -= vec3(1.5, 2, -.2);
    d = min(d, box(tp, vec3(0.6)));
    tp.x = abs(abs(tp.x) - 0.12 - .12) - 0.12;
    tp.y = abs(tp.y) - 0.12;
    float f = box(tp - vec3(0, 0, 0.58), vec3(0.06));
    g += S(0.8, 0.96, p.z) * 0.003 / (0.003 + abs(f)) * S(0.8, 0., f);
    d = min(d, f);

    // Helmet table.
    tp = p + vec3(0.5, 2, -2);
    d = min(d, box(tp + vec3(0, 1.4, 0), vec3(1, 1, 0.5)));

    // Helmet.
    float l = length(tp);
    f = abs(l - 0.47) - 0.02;
    f -= step(abs(abs(tp.z) - .1), 0.05) * 0.006 + step(abs(tp.y), 0.08) * 0.01;
    d = min(d, max(f, -box(tp + vec3(0.6, -0.3, 0), vec3(0.5))));

    // Pod.
    tp = p + vec3(4.2, 3.2, -1);
    l = S(2., 0.0, tp.z) * 0.5 + S(1.2, 2., tp.z) * 0.4;
    float b = box(tp, vec3(0.6, 0.6, 2));
    f = mix(cyl(tp + vec3(0, tp.z * 0.1, 0), vec2(0.7, 2)), b - 0.2, l);
    return min(d, mix(b - 0.15, f, S(.6, .65, tp.y + 0.5)));
}

vec3 N(vec3 p, float t) {
    float h = t * 0.4;
    vec3 n = vec3(0);
    for (int i = min(frames, 0); i < 4; i++) {
        vec3 e = .005773 * (2. * vec3(((i + 3) >> 1) & 1, (i >> 1) & 1, i & 1) - 1.);
        n += e * map(p + e * h);
    }

    return normalize(n);
}

float shadow(vec3 p, vec3 lp) {
    float s = 1.,
          t = .02, d,
          mxt = length(p - lp);
    vec3 ld = normalize(lp - p);
    for (float i = Z0; i < SHADOW_STEPS; i++) {
        d = map(t * ld + p);
        s = min(s, 15. * d / t);
        t += d;
        if (mxt - t < 0.5 || s < 0.001) break;
    }

    return S01(s);
}

// Quick ambient occlusion.
float aof(vec3 p, vec3 n, float h) { return sat(map(h * n + p) / h); }

float fog(float d) { return exp(d * d * (t < 16. ? -0.01 : -0.02)); }

float L_On() { return 0.01 + step(9.5, t) * step(t, 51.0); }

float dtc(vec2 p) {
    if (abs(p.x) > .6 || abs(p.y) > .5) return 0.0;
    if (step(min2(abs(p - vec2(0, .2))), .08) * step(p.y, .3) * step(abs(p.x), .4) > 0.)
        return 0.6;

    float dc = step(.5, -p.x), f;
    p.x = abs(p.x) - .46;
    f = dot(p, p);
    dc += step(f, .25) * step(.16, f);
    return step(0.1, dc);
}

vec3 lights(vec3 p, vec3 rd, vec3 n) {
    vec3 ld = normalize(LP - p),
         c = vec3(0.25, 0.05, 0.04);
         
    c += dtc((p.xy + vec2(4, -0.8)) * 0.5) * 0.04 * step(0.0, p.z);

    // Scanner.
    float s = step(5., p.z);
    c.rg += vec2(.5, .1) * step(max2(abs(p.xy)), 1.8 * s);

    // Helmet.
    float f = .12 * step(length(p - vec3(-0.5, -2, 2)), .502);
    c = mix(c, 1. / LIGHT_RGB, f);
    n.yz -= n31(p * 40.) * .12 * .3 * (1. - s);

    // Pod frost.
    if (p.x < -3.5 && abs(p.z) < 4. && s < 1.0) {
        vec3 pp = p * vec3(105, 86, 53);
        float glint = n21(pp.xz) * (0.5 + 0.5 * h21(pp.yx));
        c = mix(c, 1. / LIGHT_RGB, S(0.85, 1., glint) + 0.13);
    }

    float ao = mix(aof(p, n, .2), aof(p, n, 2.), .7),
          l1 = sat(.1 + .9 * dot(ld, n)) * (0.3 + 0.7 * shadow(p, LP)) * (0.3 + 0.7 * ao),
          l2 = sat(.1 + .9 * dot(ld * vec3(-1, 0, -1), n)) * .3 + pow(sat(dot(rd, reflect(ld, n))), 10.) * 2.,
          fre = S(.7, 1., 1. + dot(rd, n)) * 0.2,
          lig = l1 + l2 * ao;
    return mix(lig * c * LIGHT_RGB, FOG_RGB, fre) * L_On();
}

vec3 beam(vec3 p, vec3 ro, vec3 rd, float d, float plane) {
    vec3 lp = rigP() - vec3(0, 0, 0.1),
         pn = vec3(1, 0, 0);
    float r = 0.0;
    if (t < 35.0)
        r = mix(-1.8, 0.6, sin(max(0.0, t - 16.) * 0.15) * 0.5 + 0.5);
    else if (t < 47.0) {
        r = mix(-0.5, 0.35, sin(max(0.0, t - 35.) * 0.3) * 0.5 + 0.5);
        lp.x -= 3.5;
    }

    pn.xz *= rot(r);
    float u;
    if (intPlane(lp, pn, ro, rd, u) && u < d) {
        vec3 op = p;
        p = ro + rd * u;
        float tt = step(t, 16.0) + step(47., t);
        if (abs(p.y - lp.y) * tt < lp.z - p.z) {
            vec3 q = p * vec3(0.2, 2.5, 2.5);
            q.yz = vec2(fbm(q), fbm(q + vec3(0.23, 1.23, 4.56)) + t * 0.04);
            float edge = S(0.02, 0.0, abs(length(p - op) - 0.01));
            edge += 0.5 * tt * max3(S(vec3(0.02), vec3(0), abs(p.y - 0.5 - sin(t + vec3(0, 3, 5)) * (lp.z - p.z))));
            float beam = 0.5 * min(edge, 1.0);
            beam += fbm(p + q * 10.) * plane;
            beam *= S(4.5, -3.0, op.y) * fog(u * 1.3);
            return beam * shadow(p, lp) * vec3(0.3, 1.2, 2.4);
        }
    }

    return vec3(0);
}

float addFade(float a) { return min(1.0, abs(t - a)); }

vec3 scene(vec3 ro, vec3 rd) {
    // March the scene.
    float d = 0.0, i, h;
    vec3 p = ro, col;
    for (i = Z0; i < MAX_STEPS; i++) {
        h = map(p);
        if (abs(h) < MIN_DIST) break;
        d += h;
        p += h * rd;
    }

    col = mix(FOG_RGB, g * vec3(0.76, 0.16, .08) + lights(p, rd, N(p, d)), fog(d));

    // Ground fog.
    col = mix(FOG_RGB, col, S(-4., -3.5, p.y - abs(p.x * 0.1)));
    float ns = fbm(p + t * vec3(0.2, -0.4, 0.1)) * 5.;
    col += mix(0.5, 1.0, L_On()) * FOG_RGB * ns * (0.1 + S(-2., -4., p.y + ns * 0.6 - 2. * step(6., p.z)));

    // LAZERS!
    if (L_On() > 0.1) {
        col += beam(p, ro, rd, d, 0.25 + 0.75 * step(t, 16.));

        // Helmet glass.
        float u;
        if (intSph(vec3(-0.5, -2, 2), 0.45, ro, rd, u) && u < d) {
            p = ro + rd * u;
            vec3 n = normalize(p - vec3(-0.5, -2, 2));
            col *= 0.6; // Darken a bit.
            
            // Add highlights.
            col += pow(sat(dot(n, vec3(-0.1, 1, 0))), 10.0) * 0.1;
            col += S(0.5, 1.0, 1. + dot(rd, n)) * 0.05;
            col += pow(sat(dot(n, vec3(-1, 1, 1)) - 0.95), 15.0) * 5.;
            col += beam(p, ro, rd, u, 0.1);

            // Reflect button lights.
            g *= 0.28;
            h = map(p + n);
            col += g * vec3(76, 16, 8);
        }
    }

    return col;
}

void main(void) {
    vec2 uv = (gl_FragCoord.xy - .5 * R.xy) / R.y,
         v = gl_FragCoord.xy.xy / R.xy;
    t = mod(time, 61.);
    float fade = addFade(0.0) * addFade(16.0) * addFade(35.0) * addFade(47.0) * addFade(61.0);

    // Door/scanner entry.
    vec3 ro = vec3(-2, 0, 2),
         lookAt = vec3(0, -0.9 * S(16.0, 0.0, t), 10);
    if (t < 47.0) {
        if (t > 35.0) {
            // Pod scan.
            ro = vec3(-5, -2, 3);
            lookAt = vec3(2, -6, -5);
        }
        else if (t > 16.0) {
            // Helmet/room scan.
            ro = vec3(-1.6, -1.4, 3) + S(16., 30., t) * vec3(-0.8, 0.2, 0.8);
            lookAt = vec3(4, -4, -10);
        }
    }

    // Keep camera moving a tad.
    ro.x += 0.1 * sin(t * 0.3);
    
    vec3 col = scene(ro, rayDir(ro, lookAt, uv));
    col *= .5 + .5 * pow(16. * v.x * v.y * (1. - v.x) * (1. - v.y), .4);
    glFragColor = vec4(pow(max(vec3(0), col), vec3(.45)) * fade, 0);
}
