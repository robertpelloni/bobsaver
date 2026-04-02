#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/NdKGDz

uniform int frames;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// 'The Abyss' dean_the_coder (Twitter: @deanthecoder)
// https://www.shadertoy.com/view/NdKGDz (YouTube: https://youtu.be/SZqlIZMQU6U)
//
// Processed by 'GLSL Shader Shrinker'
// (https://github.com/deanthecoder/GLSLShaderShrinker)
//
// The Abyss movie from 1989, where a friendly 'visitor'
// has a look around an underwater habitat.
//
// Quote: "Keep your pantyhose on..."
//
// Tricks to get the performance:
// - The water and scene are raymarched separately, as only
//   the water is reflective. When reflecting only the background
//   needs to be processed.
//   This also allows different max marching steps for each.
// - Similarly I have two normal functions.
//   One for the water, one for everything else.
// - Textures applied during the lighting calculations, as far
//   as possible.
// - Fake shadows.
//
// Thanks to Evvvvil, Flopine, Nusan, BigWings, Iq, Shane,
// totetmatt, Blackle, Dave Hoskins, byt3_m3chanic, and a bunch
// of others for sharing their time and knowledge!

#define R    resolution
#define U    normalize
#define L    length
#define Z0    min(time, 0.)
#define sat(x)    clamp(x, 0., 1.)
#define S01(a)    smoothstep(0., 1., a)
#define S(a, b, c)    smoothstep(a, b, c)
#define minH(a, b)    { float h_ = a; if (h_ < h.x) h = vec2(h_, b); }

float t, g = 0., g2 = 0.;
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

float max2(vec2 v) { return max(v.x, v.y); }

float max3(vec3 v) { return max(v.x, max2(v.yz)); }

mat2 rot(float a) {
    float c = cos(a),
          s = sin(a);
    return mat2(c, s, -s, c);
}

float box(vec3 p, vec3 b) {
    vec3 q = abs(p) - b;
    return L(max(q, 0.)) + min(max3(q), 0.);
}

float cap(vec3 p, vec2 hr) {
    p.x -= clamp(p.x, 0., hr.x);
    return L(p) - hr.y;
}

float honk(inout vec3 p, mat2 rot, float h, float r) {
    p.xy *= rot;
    float d = cap(p, vec2(h * .88, r));
    p.x -= h;
    return d;
}

// Find most dominant uv coords.
vec2 proj(vec3 p, vec3 n) {
    n = abs(n);
    float m = max3(n);
    return n.x == m ? p.yz : n.y == m ? p.xz : p.xy;
}

float surf(vec2 p1, vec2 p2) {
    float d = t * .4;
    return n31(vec3(p1.x + d, p1.y, d)) * .3 + n31(vec3(p2, d) * 2.) * .1 + n31(vec3(p2 + d * .5, d) * 3.6) * .05;
}

float face(vec3 p, float o) {
    float f, d,
          ox = p.x;
    p.x = abs(p.x) - .15;
    p.y += .05;
    p.z += .15 - .3 + .3 * S(27., 30., t);
    f = S(29.5, 31., t);
    d = L(p) - .08;
    p.x = ox;
    p.y -= .3 - 1. + cos(ox * 1.5 * (.3 + f * .8));
    o = max(o, -box(p, vec3(.15 + f * .1, .02 + f * .015, .09)));
    return -smin(-o, d, .03);
}

float wat(vec3 p) {
    vec3 h1, h2, h3, h4,
         op = p;
    p.z -= 3.;

    // Twist room.
    p.xz *= mat2(.707, .707, -.707, .707);

    // Pool.
    float d, s = surf(p.xz, op.xz);

    // Clip pool to pool walls.
    d = max(p.y + 6., box(p, vec3(8, 66, 8)));

    // Tentacle.
    p -= vec3(3, -7, 3);
    vec3 phNow = vec3(.3, .1, 0) * S(6., 10., t);
    phNow = mix(mix(mix(mix(mix(phNow, vec3(.37, -.12, 0), S(11., 13., t)), vec3(.3, .1, 0), S(14., 16., t)), vec3(1.09, .23, 0), S(16., 20., t)), vec3(.3, .1, 0), S(22., 24., t)), vec3(.31, .02, 1), S(24., 27., t));
    phNow *= S(35.5, 34., t);
    phNow.x += .01;
    p.y -= .2 * sin(t);
    mat2 bf = rot(phNow.z * .9);
    p.xz *= rot(.8 - phNow.y * 2.);
    h1 = vec3(1.4, phNow.x * 4.5, 1.3 * (.5 + .5 * phNow.x));
    d = smin(d, honk(p, rot(h1.x), h1.y, mix(1.5, h1.z, sat(p.y / h1.y))), 2.5); // angle, length, radius
    p.xy *= bf;
    h2 = vec3(-.7 * phNow.x, h1.yz * vec2(.8, .9));
    d = smin(d, honk(p, rot(h2.x), h2.y, mix(h1.z, h2.z, sat(p.x / h2.y))), .2);
    p.xz *= rot(-phNow.y);
    h3 = vec3(-.4 * phNow.x, h2.yz * vec2(2.5, .7));
    d = smin(d, honk(p, rot(h3.x), h3.y, mix(h2.z, h3.z, sat(p.x / h3.y))), .1);
    p.xz *= rot(phNow.y * -3.);
    p.xy *= bf;
    h4 = vec3(-.2 * phNow.x, h3.yz * vec2(.4 + dot(phNow.xz, vec2(.15, 1)), .7));
    d = smin(d, honk(p, rot(h4.x), h4.y, mix(h3.z, h4.z, sat(p.x / h4.y))), .2);
    d -= s * S01(L(p) - .5 * (S(26.5, 27.5, t) - S(34., 34.5, t)));
    d = face(p.zyx, d);
    g2 += .01 / (4. + d * d);
    return d;
}

float pipe(vec3 p, float r) { return L(p.yz) - r - min(step(.96, fract(p.x * .2)) * r * .2, .1); }

vec2 env(vec3 p) {
    p.z -= 3.;
    float d = max(abs(p.z - 30.), 20. - p.x);

    // Twist room.
    p.xz *= mat2(.707, .707, -.707, .707);

    // Left wall.
    d = min(min(d, max(abs(20. - abs(p.z)) - 1.5, p.x - 24.)), 34. - p.z);

    // Right walls.
    d = min(min(d, max(abs(25. - abs(p.x)) - 1.5, p.z - 7.7 - step(p.x, 0.) * 12.)), max(abs(5.2 - p.z) - .1, 24. - p.x));

    // Ceiling.
    d = smin(d, 10. - p.y, 1.);

    // Right corner box.
    d = min(d, max(box(p - vec3(21, 0, 12.6), vec3(2.5, 66, 6)), -box(p - vec3(32, 0, 12.6), vec3(10, 66, 5))));

    // Left door.
    d = max(d, .5 - box(p - vec3(4, 0, 20), vec3(4, 4, 2)));

    // Right doors.
    vec3 q = p;
    q.y -= .8;
    q.z = abs(q.z - 7.) - 5.;
    if (p.x > 0.) d = max(max(d, 3. - box(q, vec3(26, 2, 0))), 4. - box(q, vec3(15.4, 2.8, 1)));
    vec2 h = vec2(d, 3);

    // Lamp.
    d = cap(p.yxz - vec3(5, 23, -3), vec2(1.2, .6));
    g += .02 / (1. + d * d);
    minH(d, 5.);

    // Ground/pool hole.
    minH(max(p.y + 5., -box(p, vec3(8, 66, 8))), 2.);

    // Wall pipes.
    q = p.yxz - vec3(1, 20.5, 6.4);
    q.y = abs(abs(q.y) - .5) - .5;
    d = pipe(q, .2);

    // LHS big jobs.
    q = p - vec3(0, 9, 18.5);
    q.y = abs(q.y) - .6;
    d = min(d, pipe(q, .5));

    // Light wires.
    q = p.yzx - vec3(0, -11, 23.5);
    q.y = abs(abs(q.y) - 6.) - .3;
    d = min(d, pipe(q, .2));

    // Roof big jobs.
    q = p - vec3(0, 9, 10);
    q.z = abs(abs(q.z + 3.5) - 3.) - 1.;
    d = min(d, pipe(q, .7));

    // Corridor pipe.
    d = min(d, pipe(p - vec3(0, -3, 32), 1.));

    // Floor pipe.
    q = p.zxy - vec3(1, 23, -4);
    d = min(d, max(pipe(q, .8), p.z + 3.));
    q.x += 4.;
    minH(min(d, L(q) - .8), 4.);
    return h;
}

// Environment normal.
vec3 Ne(vec3 p) {
    float h = L(p) * .4;
    vec3 n = vec3(0);
    for (int i = min(frames, 0); i < 4; i++) {
        vec3 e = .005773 * (2. * vec3(((i + 3) >> 1) & 1, (i >> 1) & 1, i & 1) - 1.);
        n += e * env(p + e * h).x;
    }

    return U(n);
}

// Water normal.
vec3 Nw(vec3 p) {
    float h = L(p) * .4;
    vec3 n = vec3(0);
    for (int i = min(frames, 0); i < 4; i++) {
        vec3 e = .005773 * (2. * vec3(((i + 3) >> 1) & 1, (i >> 1) & 1, i & 1) - 1.);
        n += e * wat(p + e * h);
    }

    return U(n);
}

// Quick ambient occlusion.
float ao(vec3 p, vec3 n, float d) {
    p += d * n;
    return min(wat(p) * .4, env(p).x) / d;
}

float fog(vec3 v) { return exp(dot(v, v) * -4e-4); }

vec3 lights(vec3 p, vec3 rd, vec3 n, vec2 h) {
    if (h.y == 5.) return vec3(1.8 * L(n.xz) + .2);
    vec3 c, ld2,
         ld = U(vec3(0, -5, 0) - p);
    float l1, l2, fre,
          ao = mix(ao(p, n, .2), ao(p, n, 2.), .7),
          sha = 1.,
          l2c = 1.;
    vec2 spe = vec2(1.22, .1);
    if (h.y == 1.) {
        // Tentacle.
        c = vec3(.35, .71, .53) * 1.6 * S(1., -5., p.y);
        spe = vec2(100, 8);
    }
    else {
        float n10 = n31(p * 10.);
        if (h.y == 3.) {
            // Walls.
            c = vec3(1, .8, .6) - n10 * .06 - n31(p * .5) * .1;
            l2c = .05;
        }
        else if (h.y == 4.) {
            // Pipes.
            c = vec3(1.85, .4, .235);
            spe = vec2(4, .3);
        }
        else if (h.y == 2.) {
            // Chevrons.
            float f = step(-6., p.y) * step(max2(abs(p.xz * mat2(.7, .7, -.7, .7) - 2.)), 10.);
            c = mix(vec3(.2), f * (.01 + step(.5, fract(p.x + .75))) * vec3(16, 6, 1), f) * (.4 + .6 * n10);
        }

        sha = .3 + .7 * sat(S(-3.5, -2., p.y) + step(p.y, -5.));

        // Caustics.
        vec2 uv = proj(p, n) * .3 + t * .1,
             dd = vec2(.1, 0);
        dd = vec2(surf(uv + dd, uv.yx + dd), surf(uv + dd.yx, uv.yx + dd.yx));
        c += pow(S01(abs(L((surf(uv, uv.yx) - dd) / .05) - .5)), 3.) * 4.;
    }

    // Primary and secondary lights.
    ld2 = U(vec3(10, 15, 10) - p);
    l1 = sat(.1 + .9 * dot(ld, n)) * (.4 + .6 * ao);
    l2 = sat(dot(ld2, n)) * .01 + pow(sat(dot(rd, reflect(ld2, n))), spe.x) * spe.y;
    fre = S(.7, .8, 1. + dot(rd, n)) * .1;

    // Light falloff.
    l1 *= S(25., 1., L(vec3(0, -5, 0) - p)) * .8 + .025;
    l2 *= (.5 * S(30., 45., L(p)) + S(30., 5., L(vec3(10, 15, 10) - p))) * l2c * ao;
    l1 += S01(g2);

    // Combine into final color.
    return mix(l1 * sha * vec3(.12, 1, 2.5) * c + l2, vec3(.012, .1, .25), fre * sha) + g;
}

vec3 scene(vec3 rd) {
    vec3 p = vec3(0),
         col = vec3(0);
    float i, d;

    // March the water.
    for (i = Z0; i < 70.; i++) {
        d = wat(p);
        if (abs(d) < .0015) break;
        p += d * rd;
    }

    vec2 h;
    if (abs(d) < .0015) {
        vec3 ord,
             n = Nw(p);
        col = lights(p, rd, n, vec2(d, 1));
        vec3 watP = p;
        ord = rd;

        // Hit the water - Get reflection.
        rd = U(reflect(p, n));
        for (i = Z0; i < 120.; i++) {
            h = env(p);
            if (abs(h.x) < .0015) break;
            p += h.x * rd;
        }

        if (abs(h.x) < .0015) col = mix(col, lights(p, rd, Ne(p), h) * fog(watP - p), .5);

        // ...and now the refraction.
        p = watP;
        rd = refract(ord, n, .75);
    }
    else p = vec3(0);

    // March the environment.
    for (i = Z0; i < 70.; i++) {
        h = env(p);
        if (abs(h.x) < .0015) break;
        p += h.x * rd;
    }

    return col + lights(p, rd, Ne(p), h) * fog(p);
}

#define rgba(col)    vec4(pow(max(vec3(0), col), vec3(.45)) * sat(t) * S(40., 39., t), 0)

void mainVR(out vec4 glFragColor, vec2 fc, vec3 ro, vec3 rd) {
    t = mod(time, 40.);
    rd.xz *= mat2(1, 0, 0, -1);
    glFragColor = rgba(scene(rd));
}

void main(void) {
    vec2 fc = gl_FragCoord.xy;
    t = mod(time, 40.);
    vec2 m = mix(vec2(.744, .175), vec2(-.138, .138), S(0., 3.5, t)),
         uv = (fc - .5 * R.xy) / R.y,
         q = fc.xy / R.xy;
    m = mix(mix(mix(mix(mix(m, vec2(.031, -.208), S(2.5, 7., t)), vec2(.031, .042), S(8.5, 12., t)), vec2(.313, .208), S(16.5, 21., t)), vec2(.069, -.142), S(23., 28.5, t)), vec2(0, -.554), S(34., 37., t));
    vec3 lookAt = vec3(0, -.2, 1);
    lookAt.yz *= rot(m.y);
    lookAt.xz *= rot(m.x);
    vec3 r = U(cross(vec3(0, 1, 0), lookAt)),
         col = scene(U(lookAt + r * uv.x + cross(lookAt, r) * uv.y));
    col *= .1 + .9 * pow(16. * q.x * q.y * (1. - q.x) * (1. - q.y), .4);
    glFragColor = rgba(col);
}
