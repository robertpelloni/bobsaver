#version 420

// original https://www.shadertoy.com/view/sltXW4

uniform int frames;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// 'Innserspace' dean_the_coder (Twitter: @deanthecoder)
// https://www.shadertoy.com/view/sltXW4 (YouTube: https://youtu.be/TonMoR0KI_E)
//
// Processed by 'GLSL Shader Shrinker'
// (https://github.com/deanthecoder/GLSLShaderShrinker)
//
// Another 80s film I grew up loving, so I thought it would be a
// good challenge to make a shader from it.
//
// Things to note:
//   - I only add three blood cells into the tunnel, and use
//     domain repetition to clone them for (nearly) free.
//   - Lots of axis symmetry in the 'pod' to reduce complexity.
//   - As only the cockpit glass is transparent, it is rendered
//     separately (using ray/sphere intersection).
//   - Re-using my handy 'honk' function (Blame evvvvil for the name)
//     for the robot arm. Very handy for chaining together capsules
//     which move relative to each other.
//
// Thanks to Evvvvil, Flopine, Nusan, BigWings, Iq, Shane,
// totetmatt, Blackle, Dave Hoskins, byt3_m3chanic, tater,
// and a bunch of others for sharing their time and knowledge!
//
// License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License

#define Z0    min(time, 0.)
#define sat(x)    clamp(x, 0., 1.)
#define S(a, b, c)    smoothstep(a, b, c)
#define S01(a)    S(0., 1., a)
#define minH(a, b, c)    { float h_ = a; if (h_ < h.d) h = Hit(h_, b, c); }

float t, fade,
      g = 0.,
      arm = 0.;
struct Hit {
    float d;
    int id;
    vec3 p;
};

// Thnx Dave_Hoskins - https://www.shadertoy.com/view/4djSRW
float h31(vec3 p3) {
    p3 = fract(p3 * .1031);
    p3 += dot(p3, p3.yzx + 3.3456);
    return fract((p3.x + p3.y) * p3.z);
}

float h21(vec2 p) { return h31(p.xyx); }

float n31(vec3 p) {
    const vec3 s = vec3(7, 157, 113);

    // Thanks Shane - https://www.shadertoy.com/view/lstGRB
    vec3 ip = floor(p);
    p = fract(p);
    p = p * p * (3. - 2. * p);
    vec4 h = vec4(0, s.yz, s.y + s.z) + dot(ip, s);
    h = mix(fract(sin(h) * 43758.545), fract(sin(h + s.x) * 43758.545), p.x);
    h.xy = mix(h.xz, h.yw, p.y);
    return mix(h.x, h.y, p.z);
}

float smin(float a, float b, float k) {
    float h = sat(.5 + .5 * (b - a) / k);
    return mix(b, a, h) - k * h * (1. - h);
}

float min2(vec2 v) { return min(v.x, v.y); }

float max2(vec2 v) { return max(v.x, v.y); }

float max3(vec3 v) { return max(v.x, max(v.y, v.z)); }

float remap(float f, float in1, float in2) { return sat((f - in1) / (in2 - in1)); }

mat2 rot(float a) {
    float c = cos(a),
          s = sin(a);
    return mat2(c, s, -s, c);
}

vec3 rep(vec3 p) { return mod(p + 10., 20.) - 10.; }

float box(vec3 p, vec3 b) {
    vec3 q = abs(p) - b;
    return length(max(q, 0.)) + min(max3(q), 0.);
}

float cyl(vec3 p, vec2 hr) {
    vec2 d = abs(vec2(length(p.zy), p.x)) - hr;
    return min(max(d.x, d.y), 0.) + length(max(d, 0.));
}

float cap(vec3 p, float h, float r) {
    p.x -= clamp(p.x, 0., h);
    return length(p) - r;
}

float tor(vec3 p) {
    return length(vec2(length(p.xz) - 1., p.y)) - .4;
}

float honk(inout vec3 p, vec2 r) {
    float d = cap(p, r.x, r.y);
    p.x -= r.x;
    return d;
}

vec3 rayDir(vec3 ro, vec3 lookAt, vec2 uv) {
    vec3 f = normalize(lookAt - ro),
         r = normalize(cross(vec3(0, 1, 0), f));
    return normalize(f + r * uv.x + cross(f, r) * uv.y);
}

Hit pod(vec3 p, float sha) {
    vec3 tp,
         op = p;
    float f,
          d = cap(p, .5, 1.);

    // Rear box.
    f = min(d, max(box(p, vec3(2, .32, .32)) - .7, abs(p.x - .9) - .6));
    d = mix(d, f, .7);

    // Rear slope cut.
    f = max(d, p.x + p.y * .5 - 1.4);
    d = mix(d, f, .5);

    // Sphere straps.
    f = max2(S(.06, .04, abs(abs(p.xz) - vec2(0.0, p.y * .16 + .28))));
    d -= f * .02;

    // Front glass.
    p.y -= .64;
    f = box(p, vec3(1, .18, p.y * .16 + .26));
    d = max(d, -f);

    // Side glass.
    p.xy += vec2(.35, -.08);
    f = max(box(p, vec3(.22, .12, 2)), p.y - sin(p.x + 1.58) * 1.96 + 1.9 - p.x * .4);
    d = max(d, -f);
    p = op;

    // Square base.
    p.xy += vec2(-.21, .2);
    f = max(box(p, vec3(1.15, .85, .58)) - .15, abs(p.y) - .2);
    d = mix(d, min(max(d, -p.y), f), .8);
    p = op;
    Hit h = Hit(d, 3, p);

    // Top turbines.
    p.z = abs(p.z) - .75;
    p.xy -= vec2(.7, 1);
    f = cyl(p, vec2(.02 * S(.24, .2, abs(p.x)) + .2, .5));
    tp = p;
    p.x = abs(p.x) - .74;
    f = min(max(f, .28 - length(p)), cap(p + vec3(.94, 0, 0), .62, .08));
    minH(f, 4, tp);
    p = op;

    // Lights.
    p.y -= .73 - .47 * step(p.x, 0.);
    p.xz = abs(p.xz - vec2(.14, 0)) - vec2(1.25, .2);
    f = cap(p - vec3(2, 0, 0), .5, p.x * .4 + .2);
    g += .002 / (.2 + f * f * f * f) * S(-1., -3., op.x);
    f = max(length(p + vec3(.43, 0, 0)) - .46, -p.x);
    g += .003 / (.003 + f * f * 1e2);
    f = min(max(length(p) - .18, p.x), f);
    d = min(d, f);
    p = op;

    // Skids.
    p.z = abs(p.z);
    p -= vec3(.29, -.45, .8);
    f = box(p, vec3(1, .03, .08));
    p.x++;
    p.xy *= mat2(.70721, -.707, .707, .70721);
    p.x += .047;
    f = min(f, box(p, vec3(.06, .03, .08)));
    d = min(d, f);
    p = op;

    // Rear canisters.
    p.z = abs(p.z);
    p -= vec3(1.38, .16, .45);
    mat2 r = mat2(.95534, .29552, -.29552, .95534);
    p.yz *= r;
    p.xy *= r;
    d = min(d, cap(p.yxz, .4, .1));
    p = op;

    // Arm.
    p += vec3(1.08, .23, .3);
    p.xz *= rot(-4.71225 + S(0., .5, arm) * 1.3);
    f = min(honk(p, vec2(.6, .03)), cap(p.yxz, .06, .04));
    p.y -= .06;
    r = mat2(-1, 0, 0, -1);
    p.xz *= r;
    p.xy *= rot(S01(arm) * 2.);
    f = min(min(f, honk(p, vec2(.6, .03))), cap(p.yxz, .06, .04));
    p.y -= .06;
    p.xz *= r;
    p.xy *= rot(S(.7, 1., arm) * 2.);
    f = min(f, honk(p, vec2(.1, .01)));
    minH(min(d, f), 3, p);
    if (t * sha * step(t, 36.) > 25.5) {
        p.xy *= rot(sin(t * .55) * .5);
        p.x -= .02;
        d = honk(p, vec2(2, .01));
        g += 2e-4 * (sin(p.x * 10. - t * 5.) * .5 + 1.) / (1e-5 + d * d);
        minH(d, 7, p);
    }

    return h;
}

float tube(vec3 p) {
    float d = abs(26.5 - pow(abs(sin(p.x * .16)), 14.) - length(p.yz)) - .5;
    if (t > 41.) {
        p.y++;
        d = smin(d, 2. - length(p.xy) + dot(sin(vec2(5, 10) * atan(p.x, p.y)), vec2(.1, .05)), -.4);
    }

    return d;
}

float cell(vec3 p, float rnd) {
    p.xy -= vec2(15. * t - 7. * cos(t * 2.), 1);
    float i = h31(floor((p - 10.) / 20.) + vec3(rnd, rnd, -rnd));
    p = rep(p);
    mat2 m = rot(10. * i + t * rnd * sin(i * 10.));
    p.yz *= m;
    p.xy *= -m;
    return smin(tor(p), cyl(p.yxz, vec2(1, .1)), .4);
}

float cells(vec3 p) { return min(min(cell(p, 1.), cell(p + vec3(5), 2.)), cell(p + vec3(12), 3.)); }

vec3 podP = vec3(0),
     podR = vec3(0);
vec3 lp() {
    vec3 p = vec3(3, 0, 0);
    p.xz *= rot(-podR.y);
    return podP - p;
}

Hit map(vec3 p, float sha) {
    Hit h2,
        h = Hit(tube(p), 5, p);
    vec3 op = p;
    minH(cells(p), 6, p);
    p = op - podP;
    p.yz *= rot(podR.x);
    p.xz *= rot(podR.y);
    h2 = pod(p, sha);
    if (h2.d < h.d) return h2;
    return h;
}

vec3 N(vec3 p, float t) {
    float h = t * .4;
    vec3 n = vec3(0);
    for (int i = min(frames, 0); i < 4; i++) {
        vec3 e = .005773 * (2. * vec3(((i + 3) >> 1) & 1, (i >> 1) & 1, i & 1) - 1.);
        n += e * map(p + e * h, 1.).d;
    }

    return normalize(n);
}

float shadow(vec3 p, vec3 lp) {
    float d,
          s = 1.,
          t = .1,
          mxt = length(p - lp);
    vec3 ld = normalize(lp - p);
    for (float i = Z0; i < 30.; i++) {
        d = map(t * ld + p, 0.).d;
        s = min(s, 15. * d / t);
        t += max(.01, d);
        if (mxt - t < .5 || s < .001 || t > 45.) break;
    }

    return S01(s);
}

float aof(vec3 p, vec3 n, float h) { return sat(map(h * n + p, 0.).d / h); }

float fog(float d) { return exp(d * d * -.001); }

void dtc(vec2 p, inout vec3 c) {
    if (abs(p.x) > .6 || abs(p.y) > .5) return;
    float dc,
          f = step(min2(abs(p - vec2(0, .2))), .08) * step(p.y, .3) * step(abs(p.x), .4);
    if (f > 0.) {
        c = vec3(8);
        return;
    }

    dc = step(.5, p.x);
    p.x = abs(p.x) - .46;
    f = dot(p, p);
    dc += step(f, .25) * step(.16, f);
    if (dc > 0.) c = vec3(3);
}

vec3 lights(vec3 p, vec3 rd, vec3 n, Hit h) {
    vec3 c,
         l = lp(),
         ld = normalize(l - p),
         noise = vec3(n31(h.p * .3), n31(h.p.zxy * 3.3), n31(h.p.zxy * 60.)) - .5;
    vec2 spe = vec2(10, 1);
    if (h.id <= 4) {
        c = vec3(.34, .3, .32);
        c *= 1. + dot(noise, vec3(1, .5, .15));
        n = normalize(n + dot(noise, vec3(.11, .13, .036)));
        spe.y = 8.;
        if (h.id == 4) {
            float l = length(h.p.yz),
                  v = step(l, .13) * step(.06, l) * sat(1. + sin(t * -80. + 18. * atan(h.p.y, h.p.z)));
            c = mix(c, vec3(.005), v * .6);
            if (h.p.z > 0.) dtc(h.p.xy * vec2(sign(p.x), 1) * 4.5, c);
            n = normalize(n + v * .2);
        }
    }
    else if (h.id == 6) {
        c = vec3(.2, 0, 0);
        n = normalize(n + noise.z * .25);
    }
    else if (h.id == 5) {
        c = vec3(.1, 0, 0);
        c.r *= 1. - S(.4, 0., abs(dot(sin(p * .16), cos(p.zxy * .07)))) * .5;
        c *= 1. + dot(noise.xy, vec2(1, .2)) + sat(noise.z) * .7;
    }
    else c = vec3(1);

    float ao = mix(aof(p, n, .2), aof(p, n, 2.), .7),
          sha = shadow(p, l),
    l1 = sat(.1 + .9 * dot(ld, n))
         * (0.3 + 0.7 * sha)
         * (0.3 + 0.7 * ao),
    l2 = sat(.1 + .9 * dot(ld * vec3(-1, 0, -1), n)) * 0.025
         + pow(sat(dot(rd, reflect(ld, n))), spe.x) * spe.y * sat(sha + 0.5),
    fre = 1.0 - S(.7, 1., 1. + dot(rd, n));

    return mix(vec3(0.005, 0, 0), (l1 + l2 * ao) * c * vec3(1, .7, .7), fre);
}

vec3 scene(vec3 p, vec3 rd) {
    vec3 n, col, wp = p;
    float i, gg, sum,
          d = 0.;
    Hit h;
    for (i = Z0; i < 90.; i++) {
        h = map(p, 1.);
        if (abs(h.d) < .0015 || d > 70.) break;
        d += h.d;
        p += h.d * rd;
    }

    gg = g;
    n = N(p, d);
    col = mix(vec3(.0025, .5e-4, .5e-4), gg * vec3(2, .91, .7) + lights(p, rd, n, h), fog(d));

    // March the window.
    {
        float a = dot(rd, rd),
              b = 2. * dot(rd, wp - podP),
              dis = b * b - 4. * a * (dot(podP, podP) + dot(wp, wp) - 2. * dot(podP, wp) - .99);
        if (dis > 0.) {
            float sd = (-b - sqrt(dis)) / (2. * a);
            if (sd < d && sd > 0.0) {
                p = wp + sd * rd;
                if (p.y > podP.y + .4) {
                    n = normalize(podP - p);
                    col += vec3(1, .7, .7) * (.02 + pow(sat(dot(rd, reflect(normalize(lp() - p), n))), 3.5));
                }
            }
        }
    }

    // Particles.
    sum = 0.;
    for (float dist = 1.; dist < d; dist += 5.) {
        vec3 vp = wp + rd * dist;
        vp.yz -= t * .1;
        sum += 1. - S(0., mix(.15, .02, remap(dist, 1., 20.)), length(fract(vp - wp) - .5));
    }
    col += sum * vec3(.03, .003, .003);
    
    return col;
}

float addFade(float a) { return min(1., abs(t - a)); }

#define rgba(col)    vec4(pow(max(vec3(0), col), vec3(.45)) * fade, 0)

vec3 cam(inout vec3 at) {
    t = mod(time, 55.);
    fade = addFade(0.) * addFade(21.) * addFade(41.) * addFade(55.);

    // Stage 1a - Pod travels towards viewer.
    podP = mix(vec3(-70, 1, 3), vec3(0, -1, 3), S(0., 12., t));
    podR = vec3(sin(t) * .2, 3.141, 0);
    float f = remap(t, 0., 7.);
    vec3 ro = mix(vec3(-20, 0, 0), vec3(-3, 0, 6), f);
    at = mix(vec3(-20, 0, 10), podP, remap(t, 0., 7.));

    // Stage 1b - Pod rotate to wall, extend arm.
    podR = mix(podR, vec3(0, 4.7, 0), S(10., 15., t));
    arm = S(14., 18., t);
    podP = mix(podP, vec3(0, -1, 8), S(16., 21., t));

    // Stage 2 - Pod cutting wall.
    float drift = .3;
    if (t > 21.) {
        drift *= 1. - remap(t, 22., 25.) * .8;
        podP.yz += vec2(-.6, mix(8., 14.4, S(20., 25., t)));
        at = podP;
        f = S(20., 25., t);
        ro += 5. + vec3(5. * f, -3.2 * f, 11.2) - vec3(4.1, 2.35, -1.8) * S(27., 33., t);
        arm *= S(40.5, 37.5, t);
        podP.z += S(38., 41., t);

        // Stage 3 - Entering hole.
        if (t > 41.) {
            drift = .3;
            ro = vec3(-1.921875, 15. - 10. * S(41., 44., t), 15);
            f = S(48., 53., t);
            podR.y -= f;
            podP.xz += vec2(f, S(43., 55., t) * 13.);
        }
    }

    // Pod drift.
    podP += vec3(sin(t), sin(t * 1.1), cos(t)) * drift;
    return ro;
}

void mainVR(out vec4 glFragColor, vec2 fc, vec3 ro, vec3 rd) {
    rd.xz *= mat2(1, 0, 0, -1);
    vec3 dummy;
    glFragColor = rgba(scene(cam(dummy), rd));
}

void main(void) {
	vec2 fc=gl_FragCoord.xy;
    vec2 R = resolution.xy,
         uv = (fc - .5 * R.xy) / R.y,
         v = fc.xy / R.xy;
    vec3 at,
         ro = cam(at),
         col = scene(ro, rayDir(ro, at, uv));
    col *= .5 + .5 * pow(16. * v.x * v.y * (1. - v.x) * (1. - v.y), .4);
    col -= h21(fc * .3) * .001;
    glFragColor = rgba(col);
}
