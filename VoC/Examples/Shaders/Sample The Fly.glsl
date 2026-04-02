#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/ft2XWw

uniform int frames;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// 'The Fly' dean_the_coder (Twitter: @deanthecoder)
// https://www.shadertoy.com/view/ft2XWw (YouTube: https://youtu.be/Vq-9sCiXFLo)
//
// Processed by 'GLSL Shader Shrinker' (Shrunk by 1,562 characters)
// (https://github.com/deanthecoder/GLSLShaderShrinker)
//
// The Fly was one of the first 'horror' movies I saw (waaay
// too young...). An awesome movie!
// I think the unsung hero in the movie is the fly itself.
// This is a tribute to that little performer.
//
// Tricks to get the performance:
// - As always, making use of abs() to reflect objects.
//   (There's only one window pane, and one horizontal pipe
//   on the wall - The others are mirrored.)
// - There's only one point light. The extra whiteness inside
//   the 'pod' is faked in the material code.
// - I tend to avoid using Shadertoy's textures.
//   This is partly due to performance, but mostly because I'm
//   a bit of a purist and like the idea of 'everything you
//   see is generated in real time'. Although using that wood
//   texture is always very tempting! :)
//
// Thanks to Evvvvil, Flopine, Nusan, BigWings, Iq, Shane,
// Blackle and a bunch of others for sharing their knowledge!

#define R    resolution
#define Z0    min(time, 0.)
#define sat(x)    clamp(x, 0., 1.)
#define S01(a)    smoothstep(0., 1., a)
#define S(a, b, c)    smoothstep(a, b, c)

float t,
      g = 0.;

#define HASH    p = fract(p * .1031); p *= p + 3.3456; return fract(p * (p + p));

vec4 h44(vec4 p) { HASH }

float n31(vec3 p) {
    const vec3 s = vec3(7, 157, 113);
    vec3 ip = floor(p);
    p = fract(p);
    p = p * p * (3. - 2. * p);
    vec4 h = vec4(0, s.yz, s.y + s.z) + dot(ip, s);
    h = mix(h44(h), h44(h + s.x), p.x);
    h.xy = mix(h.xz, h.yw, p.y);
    return mix(h.x, h.y, p.z);
}

float n21(vec2 p) { return n31(vec3(p, 1)); }

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

#define minH(a)    if (a.x < h.x) h = a

float box(vec3 p, vec3 b) {
    vec3 q = abs(p) - b;
    return length(max(q, 0.)) + min(max(q.x, max(q.y, q.z)), 0.);
}

float cyl(vec3 p, vec2 hr) {
    vec2 d = abs(vec2(length(p.xy), p.z)) - hr;
    return min(max(d.x, d.y), 0.) + length(max(d, 0.));
}

float cap(vec3 p, float h, float r) {
    p.y -= clamp(p.y, 0., h);
    return length(p) - r;
}

float tor(vec3 p, vec2 t) {
    vec2 q = vec2(length(p.xz) - t.x, p.y);
    return length(q) - t.y;
}

float link(vec3 p, float le, float r1, float r2) {
    vec3 q = vec3(p.x, max(abs(p.y) - le, 0.), p.z);
    return length(vec2(length(q.xy) - r1, q.z)) - r2;
}

vec3 rayDir(vec3 lookAt, vec2 uv) {
    vec3 f = normalize(lookAt),
         r = normalize(cross(vec3(0, 1, 0), f));
    return normalize(f + r * uv.x + cross(f, r) * uv.y);
}

float pod(vec3 p, bool isDr, out float w) {
    float d, dr,
          s = step(3.25, p.y),
          a = atan(p.x, p.z);
    w = (max(0., p.y - 1.) + sat(1. - p.y)) * .25 + s * .1;
    d = max(cap(p, 3.2, 1.5 - sqrt(w * w + .001)), -p.y);
    w = d;
    dr = p.y * .09 - 1.3 - p.z - S(2.3, 3.3, p.y) - S(.3, 1.5, abs(p.x));
    if (isDr) return max(d, -dr);
    d -= .15 * sat(sin(p.y * 30.)) * (1. - s) * step(1., p.y) + sat(sin(a * 25.) * .1 * s) * step(p.y, 3.5);
    return isDr ? max(w, -dr) : max(max(d, dr), dr);
}

vec2 map(vec3 p) {
    vec2 h = vec2(p.y, 2);
    float d, podd,
          w = t * 4.;
    vec3 pp = vec3(cos(w) * cos(w * 1.3) * .5, 1.5 + sin(w * .5) * .5, -6. * (S(10., 5., t) + S(32., 40., t)));
    pp = mix(pp, vec3(0, .3, 0), sat(S(16., 20., t) - S(28., 32., t)));
    minH(vec2(length(p - pp) - .02, 1));
    minH(vec2(8. - p.z, 4));
    pp = p;
    pp.x++;
    pp.y -= 3.3;
    d = max(min(abs(4.5 - pp.z) - .5, 18. - p.x), -box(pp, vec3(1.26, 2.12, 4.6)));
    pp.xy = abs(abs(pp.xy) - vec2(.64, 1.08)) - vec2(.32, .54);
    d = max(d, -box(pp, vec3(.3, .5, 9)));
    minH(vec2(d, 3));
    pp = p - vec3(7, 1, 0);
    minH(vec2(cyl(pp - vec3(0, .3, 1.2), vec2(S01(2. - pp.y), .1) * .8), 5));
    w = .05 * step(p.y, 1.5);
    d = box(pp, vec3(2. - w, .7, 1. - w));
    pp.x = abs(pp.x) - 1.5;
    pp.y += .7;
    d = min(d, box(pp, vec3(.05, .2, .8)) - .1);
    minH(vec2(d, 8));
    pp = p.zxy;
    pp.x -= 4.1;
    pp.y -= 1.4;
    d = length(pp.xy + vec2(.5, 5.1)) - .16 - .03 * step(abs(cos(pp.z)), .05);
    pp.z = abs(pp.z - .4) - .15;
    d = min(d, link(pp, 4., .5, .1));
    p.z--;
    pp = p;
    w = S(15., 12., t) + S(23., 26., t);
    pp.x += pow(sin(w * 1.6), 4.);
    pp.z += S(.7, 0., abs(w * 1.7 - 1.) - .3) * .3;
    minH(vec2(pod(pp, true, w), 7));
    d = min(d, pod(p, false, podd) * .9);
    w = .05 + abs(.01 * sin((p.y - abs(p.x)) * 36.));
    p.yz++;
    d = min(min(d, link(p, .5, 1.5, w)), link(p, .5, 1.2, w));
    p.y -= 1.7;
    p.z -= .3;
    d = max(min(d, max(max(tor(p, vec2(.9, .7)), -p.z), tor(p - vec3(0, -.7, 0), vec2(1)))), -podd - .06);
    minH(vec2(d, 6));
    d = max(length(p.xz) - .4, abs(p.y + .6) - .01);
    minH(vec2(d, 0));
    w = 1.;
    if (t > 16.) {
        if (t < 19.) w = .001 + .02 * (.5 + .5 * sin(t * 6.));
        else if (t < 23.) w = step(fbm(vec3(1, 1, t * 10.)), .2);
    }

    g += .005 / (.1 + d * d * 1e2 * w);
    return h;
}

vec3 N(vec3 p, float t) {
    float h = t * .2;
    vec3 n = vec3(0);
    for (int i = min(frames, 0); i < 4; i++) {
        vec3 e = .005773 * (2. * vec3(((i + 3) >> 1) & 1, (i >> 1) & 1, i & 1) - 1.);
        n += e * map(p + e * h).x;
    }

    return normalize(n);
}

float shadow(vec3 p, vec3 ld) {
    float i, h,
          s = 1.,
          t = .1;
    for (i = Z0; i < 30.; i++) {
        h = map(t * ld + p).x;
        s = min(s, 15. * h / t);
        t += h;
        if (s < .001 || t > 18.) break;
    }

    return sat(s);
}

float ao(vec3 p, vec3 n, float h) { return map(h * n + p).x / h; }

float fog(vec3 v) { return exp(dot(v, v) * -.002) * S(12.0, 6.0, v.y); }

vec3 lights(vec3 p, vec3 rd, float d, vec2 h) {
    if (h.y == 1.) return vec3(.01);
    vec3 ld = normalize(vec3(2, 4, -1) - p),
         n = N(p, d),
         c = vec3(.2);
    float lig,
          hs = 0.,
          gg = g;
    if (h.y == 3.) c -= n31(p * .8) * .06;
    else if (h.y == 6.) c = vec3(.5 - .18 * n31(p * 26.)) * .3 * (1. + 6. * step(length(p - vec3(0, 1.5, 2)), 1.7));
    else if (h.y == 2.) c = mix(vec3(.04, .02, .02), vec3(.06, .04, .02), n21(p.xz * vec2(2.3, 30)));
    else if (h.y == 0.) c = vec3(1.2);
    else if (h.y == 4.) {
        c = vec3(.1, .2, .3) * (.24 - rd.y) * .6 + .01;
        hs++;
    }
    else if (h.y == 5.) c = vec3(.15, .01, .02);

    float ao = mix(ao(p, n, 1.), ao(p, n, 2.), .7),
          l1 = sat(.1 + .9 * dot(ld, n)) * (.3 + .7 * sat(hs + shadow(p, ld))) * (.3 + .7 * ao),
          l2 = sat(.1 + .9 * dot(ld * vec3(-1, 0, -1), n)) * .3 + pow(sat(dot(rd, reflect(ld, n))), 10.),
          fre = S(.7, 1., 1. + dot(rd, n)) * .5;
    lig = l1 + l2 * ao;
    g = gg;
    return mix(lig * c * vec3(2, 1.6, 1.5), vec3(.01), fre);
}

vec4 march(inout vec3 p, vec3 rd, float s) {
    float i,
          d = .01;
    g = 0.;
    vec2 h;
    for (i = Z0; i < s; i++) {
        h = map(p);
        if (abs(h.x) < .0015) break;
        d += h.x;
        if (d > 25.) return vec4(0);
        p += h.x * rd;
    }

    return vec4(g + lights(p, rd, d, h), h.y);
}

vec3 scene(vec3 rd) {
    vec3 p = vec3(0);
    p -= vec3(1, -2. + t * .0125, 5.5 - t / 40.);
    vec4 col = march(p, rd, 80.);
    col.rgb *= fog(p);
    if (col.w >= 6.) {
        float lp = length(p);
        vec3 n = N(p, lp);
        if (col.w == 7.) {
            rd = refract(rd, n, 1.);
            p -= n * .3;
            col += march(p, rd, 32.) * fog(p);
            col *= .5;
            n = N(p, lp);
        }

        rd = reflect(rd, n);
        p += n * .01;
        col += .1 * march(p, rd, 32.) * fog(p);
    }

    return col.rgb;
}

#define rgba(col)    vec4(pow(max(vec3(0), col), vec3(.45)) * sat(t), 0)

void mainVR(out vec4 glFragColor, vec2 fc, vec3 ro, vec3 rd) {
    t = mod(time, 40.);
    rd.xz *= mat2(1, 0, 0, -1);
    glFragColor = rgba(scene(rd));
}

void main(void) {
    t = mod(time, 40.);
    vec2 q,
         uv = (gl_FragCoord.xy - .5 * R.xy) / R.y;
    vec3 col = scene(rayDir(vec3(mix(.5, .33, S(1., 10., t)), 0, 1), uv));
    q = gl_FragCoord.xy / R.xy;
    col *= .5 + .5 * pow(16. * q.x * q.y * (1. - q.x) * (1. - q.y), .4);
    glFragColor = rgba(col);
}
