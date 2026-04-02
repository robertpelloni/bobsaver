#version 420

// original https://www.shadertoy.com/view/mlc3Rs

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Fork of "Cube Tunnel Variation " by gam0022. https://shadertoy.com/view/dlc3Rs
// 2023-05-01 09:23:36

float beat, beatTau;
vec3 target;

#define time time
#define PI acos(-1.)
#define TAU (PI * 2.)
#define saturate(x) clamp(x, 0., 1.)
#define SOL 0.
#define VOL 1.

float phase(float x) { return floor(x) + 0.5 + 0.5 * cos(TAU * 0.5 * exp(-5.0 * fract(x))); }

void rot(inout vec2 p, float t) { p = mat2(cos(t), sin(t), -sin(t), cos(t)) * p; }

vec3 pal(float x) { return mix(saturate(sin((vec3(0.333, 0.6666, 0) + x) * TAU)), vec3(1), 0.1); }

float sdBox(vec3 p, vec3 b) {
    vec3 q = abs(p) - b;
    return length(max(q, 0.)) + min(0., max(q.x, max(q.y, q.z)));
}

void U(inout vec4 m, float d, float a, float b, float c) { m = d < m.x ? vec4(d, a, b, c) : m; }

vec4 map(vec3 p) {
    vec3 pos = p;
    // rot(p.xy, 0.2 * pos.z);
    vec4 m = vec4(1, VOL, 0, 0);
    vec3 a = vec3(14, 12, 12);
    p = mod(p, a) - 0.5 * a;
    vec3 of = vec3(3, 1, 1);
    vec3 ro = vec3(0.8 + 0.05 * sin(phase(time) * 0.2 * TAU), 0.4, 0.4);
    p -= of;
    for (int i = 0; i < 5; i++) {
        p = abs(p + of) - of;
        rot(p.zy, TAU * ro.x);
        rot(p.xz, TAU * ro.y);
        rot(p.yx, TAU * ro.z);
    }

    U(m, sdBox(p, vec3(1, 1, 1)), SOL, 0.5, 1.);
    float hue = 0.3;
    float emi = saturate(cos(TAU * (pos.z / 8. + time)));
    U(m, sdBox(p, vec3(0.1, 1.1, 1.1)), VOL, hue, emi);
    U(m, sdBox(p, vec3(1.1, 1.1, 0.1)), VOL, hue + 0.5, emi);

    vec3 p2 = pos - target;
    of = vec3(0.3, 0.1, 0.1);
    ro = vec3(0.3 + 0.1 * sin(phase(time) * 0.2 * TAU), 0.5, 0.4 + 0.05 * sin(phase(time)));
    p2 -= of;
    for (int i = 0; i < 3; i++) {
        p2 = abs(p2 + of) - of;
        rot(p2.zy, TAU * ro.x);
        rot(p2.xz, TAU * ro.y);
        rot(p2.yx, TAU * ro.z);
    }

    // U(m, length(p2 - target) - 1, VOL, 0.3, 1);
    emi = 1.;
    float s = 0.2;
    U(m, sdBox(p2, s * vec3(1)), SOL, 0.5, 1.);
    U(m, sdBox(p2, s * vec3(0.1, 1.1, 1.1)), VOL, 0.3 + beat / 8., emi);
    U(m, sdBox(p2, s * vec3(1.1, 1.1, 0.1)), VOL, 0.8 + beat / 8., emi);

    return m;
}

void main(void) {
    vec2 uv = vec2(gl_FragCoord.xy.x / resolution.x, gl_FragCoord.xy.y / resolution.y);
    uv -= 0.5;
    uv /= vec2(resolution.y / resolution.x, 1);

    float bpm = 120.;
    beat = time * bpm / 60.;
    beatTau = TAU * beat;
    target = vec3(0, 0, time * 10.);

    vec3 col = vec3(0);
    vec3 ro, ray;

    if (mod(beat, 32.) < 4.) {
        ro = vec3(0, 0, time * 10. - 5.);
        ray = vec3(uv, 1);
        // rot(ray.xy, time);
    } else {
        ro = target + vec3(5. * cos(beatTau / 32.), 2. * sin(beatTau / 16.), 5. * sin(beatTau / 32.));
        vec3 up = vec3(0, 1, 0);
        vec3 fwd = normalize(target - ro);
        vec3 right = normalize(cross(up, fwd));
        up = normalize(cross(fwd, right));
        ray = normalize(right * uv.x + up * uv.y + fwd);
    }

    float t = 0.;
    for (int i = 0; i < 300; i++) {
        vec3 p = ro + t * ray;
        vec4 m = map(p);
        float d = m.x;
        if (m.y == SOL) {
            if (d < 0.001) {
                col += vec3(1) * float(i) * 0.01;
                break;
            }
            t += 0.5 * d;
        } else {
            col += clamp(pal(m.z) * m.w * 0.01 / abs(d), 0.0, 0.3);
            t += 0.25 * abs(d) + 0.01;
        }
    }

    col = mix(vec3(0), col, exp(-0.1 * t));

    col = saturate(col);

    glFragColor = vec4(col, 1);
}