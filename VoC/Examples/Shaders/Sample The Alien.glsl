#version 420

// original https://www.shadertoy.com/view/sdGSzt

uniform int frames;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// 'The Alien' dean_the_coder (Twitter: @deanthecoder)
// https://www.shadertoy.com/view/sdGSzt (YouTube: https://youtu.be/2QoR8L16Lc0)
//
// Processed by 'GLSL Shader Shrinker'
// (https://github.com/deanthecoder/GLSLShaderShrinker)
//
// I nearly gave up several times on this shader. I knew modelling
// a human face would be hard, so thought attempting an alien would
// be easier. No two 'alien' references seem to be the same, so
// I can use artistic license. Also there's no eyes/node to get wrong.
// I'm quite happy with the result, but the body could do with some arms.
// But hey - The framerate is still acceptable (for me), so...
//
// I'm also trying to improve my animation skills. I've added some
// 'anticipations', where before a strike the alien pulls back a bit
// to build up some 'power'.
//
// The skull pattern was simpler than I was expecting - I just threw
// a simple gyroid at it and it looked good! Surprising! And fast
// to calculate in real-time.
//
// Tricks to get the performance:
//   - No 'max dist' needed in raymarching loop (all rays hit something).
//   - Only the skull is reflective, and that reflects just a fake sky.
//     (I know there's no sky in a corridor, but it looks good!)
//   - I precalculate two smooth noises variables in the lighting
//     code and reuse them as much as possible.
//   - Lots of domain repetition.
//     E.g. Each jaw only has one tooth!
//          There's only one SDF for the wall pipe.
//          The Weyland-Yutani logo is _nearly_ just one line.
//
// Thanks to Evvvvil, Flopine, Nusan, BigWings, Iq, Shane,
// totetmatt, Blackle, Dave Hoskins, byt3_m3chanic, and a bunch
// of others for sharing their time and knowledge!
// License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License
#define R    resolution
#define U    normalize
#define L    length
#define Z0    min(time, 0.)
#define sat(x)    clamp(x, 0., 1.)
#define S(a, b, c)    smoothstep(a, b, c)
#define S01(a)    S(0., 1., a)
#define minH(a, b, c)    { float h_ = a; if (h_ < h.d) h = Hit(h_, b, c); }

float t;
struct Hit {
    float d;
    int id;
    vec3 p;
};

// Thnx Dave_Hoskins - https://www.shadertoy.com/view/4djSRW
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

float fbm(vec3 p) {
    float i,
          a = 0.,
          b = .5;
    for (i = Z0; i < 4.; i++) {
        a += b * n31(p);
        b *= .5;
        p *= 2.;
    }

    return a * .5;
}

float smin(float a, float b, float k) {
    float h = sat(.5 + .5 * (b - a) / k);
    return mix(b, a, h) - k * h * (1. - h);
}

float smax(float a, float b, float k) { return -smin(-a, -b, k); }

float min2(vec2 v) { return min(v.x, v.y); }

float max3(vec3 v) { return max(v.x, max(v.y, v.z)); }

mat2 rot(float a) {
    float c = cos(a),
          s = sin(a);
    return mat2(c, s, -s, c);
}

float box(vec3 p, vec3 b) {
    vec3 q = abs(p) - b;
    return L(max(q, 0.)) + min(max3(q), 0.);
}

float cyl(vec3 p, vec2 hr) {
    vec2 d = abs(vec2(L(p.xy), p.z)) - hr;
    return min(max(d.x, d.y), 0.) + L(max(d, 0.));
}

float cap(vec3 p, float h, float r) {
    p.x -= clamp(p.x, 0., h);
    return L(p) - r;
}

float arc(vec3 p, float l, float a, float r, float tap) {
    vec2 q,
         sc = vec2(sin(a), cos(a));
    float u, d2, s, t,
          ra = .5 * l / a;
    p.x -= ra;
    q = p.xy - 2. * sc * max(0., dot(sc, p.xy));
    u = abs(ra) - L(q);
    d2 = (q.y < 0.) ? dot(q + vec2(ra, 0), q + vec2(ra, 0)) : u * u;
    s = sign(a);
    t = (p.y > 0.) ? atan(s * p.y, -s * p.x) * ra : (s * p.x < 0.) ? p.y : l - p.y;
    return sqrt(d2 + p.z * p.z) - max(.001, r - t * tap);
}

float backInOut(float x) {
    float f = x < .5 ? 2. * x : 1. - (2. * x - 1.),
          g = pow(f, 3.) - f * sin(f * 3.141);
    return x < .5 ? .5 * g : .5 * (1. - g) + .5;
}

float bone(vec3 p, float h, float r, float s) {
    float f = S(.7, 1., abs(p.x / h - .5) * 2.) * .05 * s;
    p.y = abs(p.y) - f;
    return cap(p, h, r - f * .6);
}

vec3 rayDir(vec3 ro, vec3 lookAt, vec2 uv) {
    vec3 f = U(lookAt - ro),
         r = U(cross(vec3(0, 1, 0), f));
    return U(f + r * uv.x + cross(f, r) * uv.y);
}

float sky(vec3 rd) {
    float d = 10. / rd.y,
          den = 1.;
    if (d < 0.) return 0.;
    vec3 p = rd * d + vec3(1, .2, 1) * t * .8;
    p.xz *= .2;
    for (int i = 0; i < 3; i++)
        den *= exp(-.12 * fbm(p));

    return S(.9, 1., den) * (1. - sat(d / 64.));
}

float th(inout vec3 p) {
    float f = atan(p.z, p.x) + .25087;
    p.xz = L(p.xz) * cos(mod(f, .26174) - .13087 + vec2(0, 1.57));
    p = vec3(.04 - p.y, p.x - .36, p.z);
    f = .45 + abs(floor(f * 2.) * .01);
    return cap(p, f, .05 * S(0., f * 1.5, cos(abs(p.x / f * 1.86 - 1. + p.x))));
}

Hit map(vec3 p) {
    Hit h;
    h.d = 1e7;
    float d, lip, at, f, nd, s, O, x, o,
          ph = S(0., 5., t);
    p.x -= 12. * (1. - ph);
    p.xz *= rot(sin(t * .5) * .02);
    p.yz *= rot(sin(t) * .01);
    vec3 r, np, pp,
         op = p;

    // Corridor.
    p.xz *= mat2(.96891, -.2474, .2474, .96891);
    p.y = abs(p.y);
    p.z -= 30.;
    d = -p.z - 2.;
    p.yz *= mat2(.87758, -.47943, .47943, .87758);
    p.y -= 2.5;
    minH(min(d, -p.z), 6, p);
    p.x = abs(p.x + 3.) - 15.;
    minH(box(p - vec3(0, 8.5, 0), vec3(5, 2.3, .1)), 8, p - vec3(0, 8.5, 0));

    // Pipework.
    d = L(p.yz - vec2(14, 0)) - 1.5;
    p.y = abs(p.y - 2.5) - 1.1;
    minH(min(d, L(p.yz) - .8), 7, p);

    // Anim.
    lip = 0.;
    r = vec3(0);

    // Walk on.
    op.x += 16. * (1. - ph);
    r.xy = sin(ph * 12.566 + vec2(0, 8)) * vec2(.05, .1) * S(1., .5, ph * ph);
    r.z = -r.x * .5;
    op.y += abs(r.x);

    // Slight turn
    ph = S(4., 8., t);
    r.xy = mix(r.xy, sin(backInOut(ph) * -.25132 + vec2(0, 8)) * vec2(1, .12), S(0., .2, ph));

    // Sniff.
    ph = S(8.2, 12., t);
    lip = abs(sin(ph * 6.283));
    r.x += sin(ph * -3.142) * .015;

    // Face forward.
    r.xy *= S(14., 11.5, t);

    // Whip-round anticipation.
    ph = S(14.5, 15., t);
    r += vec3(.1, .05, .1) * ph;
    op.y += ph * .1;

    // Whip.
    ph = S(15., 15.3, t);
    r = mix(r, vec3(-.5, .12, 0), ph);

    // Mouth open.
    at = S(15.3, 20., t) * .2;
    f = S01(at * 30.);
    lip += f;
    r.yz = mix(r.yz, vec2(.34, -.1 + sin(t) * .07), at * 5.);

    // Inner mouth open.
    at += S(20., 23., t) * .25;

    // Strike anticipation.
    op.z -= S(24., 24.2, t) * .5;

    // Strike.
    ph = S(24.2, 24.5, t);
    op.z += ph * 1.5;
    at += ph * .4;

    // Withdraw.
    ph = S(29., 32., t);
    at += ph;
    op.z -= ph;
    r.y *= S(34., 31., t);

    // Body position.
    op += vec3(.9, 1.3, -3.6);
    op.yz *= rot(r.y + .2);
    op.xz *= rot(r.x - .2);
    r *= 3.;

    // Spine.
    p = op;
    p.xy *= mat2(-.73739, -.67546, .67546, -.73739);
    p.x++;
    d = cap(p + vec3(0, .68, 0), 4., .1 + abs(sin(p.x * 26.) * .04));
    minH(d, 2, p);

    // Neck/body.
    p.z *= 1. - mix(.4, 1.2, S01(p.x)) * .42;
    f = abs(sin(p.x * 15.) * .07);
    f *= S(.01, .05, abs(p.z)); // todo - check adding sternum
    f += S(0., .3, p.x) * .6 * S01(p.y);
    nd = cap(p, 4., mix(.3, .5, S01(p.x)) * (1. + f));
    np = p;

    // Rotate head.
    p = op - vec3(1, .4, 0);
    r *= .5;
    p.xz *= rot(r.x);
    p.yz *= rot(r.z);
    p += vec3(1, .4, 0);
    op = p;

    // Skull.
    p = op;
    p.x -= 1.5;
    p.xy *= mat2(.85252, -.52269, .52269, .85252);
    p.xy = vec2(p.y - 1., -p.x);
    d = arc(p, 4.6, -.6, .8, .06);
    p = op - vec3(.9, 0, 0);
    p.xy *= mat2(.995, -.09983, .09983, .995); // todo - inline
    f = .15 - box(p, vec3(2.6, cos((p.x + .3) * .4) * 1.71 - .5, 1));
    d = smax(d, f, .06);
    minH(d, 1, p);

    // Head bulk.
    p = op;
    p.y -= .86;
    d = min(d, L(p.yz) - .3 - .04 * abs(sin(p.x * 7.7)) - .02 * abs(sin(p.x * 23.1)));
    minH(max(d, abs(p.x) - 2.4), 2, p);

    // Frills.
    p = op;
    p.xy += vec2(1.8, -.88);
    p.z = abs(p.z) - .22;
    p.xy *= mat2(.99281, .11971, -.11971, .99281);
    p.xz *= mat2(.9968, .07991, -.07991, .9968);
    d = max(cap(p, 3.5, .2 + .05 * abs(sin(p.x * 22.)) + sin(p.x) * .1), -p.y - .14);

    // Lower organs.
    pp = p + vec3(-1.8, .3, 0);
    pp.yz /= .8 + .5 * cos(pp.x);
    pp.yz *= rot(pp.x * -.3 + .8);
    f = sin(pp.x * 35.);
    f = max(smin(box(pp, vec3(2, vec2(.1 + .01 * abs(f * f)))), L(abs(pp.yz) - .116) - .02, .08), abs(pp.x) - 2.);
    minH(min(d, f), 2, pp);
    if (nd < d) minH(smin(d, nd, .5), 9, np);

    // Skull bone.
    p.yz += vec2(.21, -.15) - sin(p.x - .2) * .14;
    minH(bone(p, 3.6, .08, 1.), 3, p);

    // Cheek bone.
    p.x -= 3.63;
    p.xy *= mat2(.88699, -.46178, .46178, .88699);
    p.yz *= mat2(.5403, .84147, -.84147, .5403);
    d = min(d, bone(p, .65, .06 - .01 * sin(p.x * 10. - 1.), .8));
    minH(d, 3, p);

    // Top gums.
    p = op;
    p.xy -= vec2(2.3, .76);
    d = max(cyl(p.xzy, vec2(.4 + S(-.15, .1, p.y) * .17 - S(.2, -.2, p.y + p.x) * .09, .2 - sin(p.y * 77.) * .02 * lip)) - .1, 2.75 * p.y + p.x - .4);
    minH(d, 3, p);

    // Smooth connect organs to top gums.
    minH(max(max(smin(f, d, .25) + .01, -f), -d), 2, p);

    // Top teeth.
    p.x -= .08;
    minH(max(smax(th(p), p.y - .03, .02), 2.29 - op.x), 4, p);

    // Strike animation.
    f = S(1., .9, at);
    s = S(.5, .51, at);
    O = (S(0., .15, at) * .6 + s * .4) * f + sin(t) * .03;
    x = S(0., .2, at) * .22 + s * .5;
    o = S(.15, .4, at) * .5 + s * (sin(t * 14.) - .8) * .2;
    x *= f * f;
    o *= f * f;

    // Inner mouth.
    p = op;
    p.xy *= mat2(.87758, -.47943, .47943, .87758);
    p.xz *= rot(sin(t * 2.) * .014 * s);
    p.y -= 1.44;
    p.x -= x - .9;
    pp = p;
    d = L(p.yz) - .1 - sin(p.x * 58.) * .01;
    p.yz = abs(p.yz) - .08;
    d = max(smin(max(d, -d - .012), L(p.yz) - .03, .05), abs(p.x - 2.2) - .5);
    minH(d, 5, p);
    p = pp;
    p.y = abs(p.y) - .08;
    p.x -= 2.68;
    p.xy *= rot(o + .1);
    p.x -= .05;
    minH(smin(d, box(p, vec3(.035 + abs(sin(abs(p.z) * 81.) * .006), .008, .1)) - .014, .03), 5, p);

    // Inner teeth.
    p.x -= .025;
    p.z = abs(abs(p.z) - .034) - .017;
    p.y *= -1.;
    p.xy = p.yx;
    d = cap(p, .06, .016 * cos(p.x * 22.));
    p.z = abs(pp.z) - .09;
    minH(min(d, cap(p, .1, .02 * cos(p.x * 17.))), 4, p);

    // Jaws.
    o = O * -.4 - .9;
    p = op - vec3(1.6, .95, 0);
    p.xy *= rot(o);
    f = p.x * -.25;
    p.z -= clamp(p.z, -.6 - f, .6 + f);
    d = bone(p, .9, .1 + f * .2, .8);
    p.x -= .9;
    p.xy *= mat2(.69671, .71736, -.71736, .69671);
    d = smin(d, cap(p, .3, p.x * -.03 + .08), .1);

    // Bottom gums.
    p = op - vec3(1.6, .95, 0);
    p.xy *= rot(.8 + o);
    f = cyl(p.xzy * vec3(1, 1.3, 1) - vec3(.77, 0, -.73), vec2(.38 - .005 * sin(p.y * 126.), .04)) - .05;
    minH(smin(d, max(f, .7 - p.x), .1), 3, p);

    // Cheek skin.
    pp = p - vec3(.6, -.2, 0);
    f = S(-.32, .32, pp.y);
    pp.z = abs(pp.z) - .4 - f * .14;
    f = mix(.8, .5, O) * (.04 - .03 * sin(3.14 * f));
    d = smin(d, min(box(pp + vec3(.2, -.2, -.05), vec3(.1 * pp.y + f, .32, 0)), box(pp, vec3(f, .35, 0))) - .02, .03);
    minH(d, 3, pp);

    // Bottom teeth.
    p.x -= .73;
    p.y += .9;
    p.xy *= mat2(-.98999, .14112, -.14112, -.98999);
    minH(max(max(p.x + .1, p.y + .3), th(p)), 4, p);
    return h;
}

vec3 N(vec3 p, float t) {
    float h = t * .4;
    vec3 n = vec3(0);
    for (int i = min(frames, 0); i < 4; i++) {
        vec3 e = .005773 * (2. * vec3(((i + 3) >> 1) & 1, (i >> 1) & 1, i & 1) - 1.);
        n += e * map(p + e * h).d;
    }

    return U(n);
}

float shadow(vec3 p, vec3 lp) {
    float d,
          s = 1.,
          t = .1,
          mxt = L(p - lp);
    vec3 ld = U(lp - p);
    for (float i = Z0; i < 25.; i++) {
        d = map(t * ld + p).d;
        s = min(s, 15. * d / t);
        t += max(.1, d);
        if (mxt - t < .5 || s < .001) break;
    }

    return S01(s);
}

// Quick ambient occlusion.
float ao(vec3 p, vec3 n, float h) { return sat(map(h * n + p).d / h); }

float fog(float d) { return exp(d * d * -.002); }

vec3 strobe(vec3 p, vec3 c) {
    p.x -= 1.5;
    vec2 q = p.xz * rot(t * 2.);
    return mix(c, pow(c, vec3(.7, 1, 1)), S(.8, .6, abs(q.x / q.y)));
}

vec3 lights(vec3 p, vec3 rd, vec3 n, Hit h) {
    vec3 ld = U(vec3(6, 3, -10) - p), c;
    vec2 spe = vec2(10, 1);
    float ao = mix(ao(p, n, .2), ao(p, n, 2.), .7),
          nh = n31(h.p * 55.),
          nl = n31(h.p * 23.);
    if (h.id == 1) {
        // Gyroid.
        c = pow(abs((vec3(.005, .01, .01) * dot(sin(h.p * 26.), cos(h.p.zxy * 26.))
         + nh * .0046) * .5), vec3(1.12, map(ld + p).d * -.07 + 1.46, 1.43));
        c *= 1. - (.9 * S01(.9 + dot(rd, n)) + .5);
        spe = vec2(5, 28);
    }
    else if (h.id == 2 || h.id == 5 || h.id == 9) {
        c = vec3(ao * .001);
        c += S(.8, 1., ao) * vec3(1.4, 1.4, 1) * .009;
        c *= nh;
        c += 1e-4;
        spe = vec2(30. * ao, 3);
        if (h.id == 5) {
            c *= 4.5;
            spe = vec2(3, 13);
        }
    }
    else if (h.id == 3) {
        c = vec3(.56, .5, .6) * .001;
        c += S(.09, .88, abs(n.y) * nh) * .002 * vec3(1, .62, .65);
        n += (nl - .5) * .08;
        spe = vec2(18, 20);
    }
    else if (h.id == 6) {
        c = vec3(.01 + nl * .01);
        spe = vec2(19, 1);
    }
    else if (h.id == 7) {
        c = vec3(.03 + nl * .02);
        spe = vec2(42, 50);
    }
    else if (h.id == 8) {
        h.p *= .3;
        float w1 = abs(abs(abs(h.p.x) - .5) - h.p.y - .25);
        c = 5e-4 + min2(step(abs(h.p.xy), vec2(1.2, .4))) * (vec3(1, 1, 0) * S(.2, .15, w1) + vec3(.5) * S(.2, .15, min(abs(abs(h.p.x) - h.p.y - .15), max(h.p.y, abs(h.p.x) - .05))) * S(.25, .2, S(.4, .3, w1))) * .05 + nh * .001;
    }
    else {
        c = vec3(.01 + pow(sat(dot(rd, reflect(ld * vec3(-1, -1, 1), n))), 24.) * .6);
        spe = vec2(8, 5);
    }

    if (h.id == 9) c *= .4;

    // Combine into final color.
    return (sat(.1 + .9 * dot(ld, n)) * (.1 + .9 * shadow(p, vec3(6, 3, -10))) * (.3 + .7 * ao) * ao + pow(sat(dot(rd, reflect(ld, n))), spe.x) * spe.y) * strobe(p, abs(c)) * 5.;
}

vec3 scene(vec3 p, vec3 rd) {
    float i,
          d = 0.;
    Hit h;
    for (i = Z0; i < 120.; i++) {
        h = map(p);
        if (abs(h.d) < .0015) break;
        d += h.d;
        p += h.d * rd;
    }

    vec3 n = N(p, d),
         col = lights(p, rd, n, h) * fog(d);
    if (h.id == 1) {
        // We hit a reflective surface - Cheat and just reflect sky.
        n = U(n + (n31(h.p * 44.) - .5) * .05);
        col += .015 * sky(reflect(rd, n));
    }

    return col;
}

void main(void) {
	vec2 fc = gl_FragCoord.xy;
    t = mod(time, 36.);
    vec2 uv = (fc - .5 * R.xy) / R.y,
         v = fc.xy / R.xy;
    vec3 col = scene(vec3(0), rayDir(vec3(0), vec3(0, 0, 1), uv));
    col *= .5 + .5 * pow(16. * v.x * v.y * (1. - v.x) * (1. - v.y), .4);
    glFragColor = vec4(pow(max(vec3(0), col), vec3(.45)) * sat(t) * S(34., 33., t), 0);
}
