#version 420

// original https://www.shadertoy.com/view/tltSWr

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec2 path[18];
vec2 a[10], b[10];  // 10 = int(18 / 2) + 1
void init() {
    // manual point set
    path[0] = vec2(1.0137, 0.3967);
    path[1] = vec2(0.5626, 0.5417);
    path[2] = vec2(0.3414, -0.0639);
    path[3] = vec2(0.1158, 0.6121);
    path[4] = vec2(-0.7459, 0.7070);
    path[5] = vec2(-0.8443, 0.1465);
    path[6] = vec2(-0.3618, 0.1444);
    path[7] = vec2(-0.1585, 0.4285);
    path[8] = vec2(-0.3173, 0.3743);
    path[9] = vec2(-0.4706, -0.2456);
    path[10] = vec2(-0.7936, -0.3968);
    path[11] = vec2(-0.5655, -0.1589);
    path[12] = vec2(0.2119, -0.6991);
    path[13] = vec2(0.2968, -0.9548);
    path[14] = vec2(0.3969, -0.4136);
    path[15] = vec2(0.7119, 0.0779);
    path[16] = vec2(0.6283, 0.2814);
    path[17] = vec2(0.7057, -0.0209);

    // calculate Fourier coefficients, b[0] is always zero
    float t, dt;
    for (int k = 0; k < 10; k++) {
        a[k] = vec2(0.), b[k] = vec2(0.);
        t = 0.0, dt = 6.283185 * float(k) / 18.;
        for (int i = 0; i < 18; i++, t += dt)
            a[k] += path[i] * cos(t), b[k] += path[i] * sin(t);
        a[k] = a[k] * (2.0 / 18.), b[k] = b[k] * (2.0 / 18.);
    }
    a[0] = a[0] * 0.5;
}

vec2 eval(float t) {
    vec2 r = a[0];
    float x = t;
    for (int k = 1; k < 10; k++) r += a[k] * cos(x) + b[k] * sin(x), x += t;
    return r;
}

// an improvement of iq's https://www.shadertoy.com/view/Xlf3zl
float sdSqSegment(in vec2 p, in vec2 a, in vec2 b) {
    vec2 pa = p - a, ba = b - a;
    vec2 q = pa - ba * clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    return dot(q, q);
}
float sd(vec2 p) {
    float o = sin(0.5*time); o = .04 + .005*o*o;  // path offset
    float o2 = (o + .02)*(o + .02);
    float t_max = 6.3*min(1.5*fract(0.15*time), 1.0);
    vec2 a = eval(0.0), b, c;
    float dt = 0.05, t = dt;
    float d = 1e8, dd;
    while (t < t_max) {
        b = eval(t);
        dd = sdSqSegment(p, a, b);
        if (dd < o2) {  // more accurate and doesn't reduce much speed
            c = eval(t - 0.5*dt);
            dd = min(sdSqSegment(p, a, c), sdSqSegment(p, c, b));
        }
        d = min(d, dd);
        dt = clamp(0.026*length(a - p) / length(a - b), 0.02, 0.1);
        t += dt;
        a = b;
    }
    d = min(d, sdSqSegment(p, a, eval(t_max)));     // add this line to eliminate gaps
    d = min(sqrt(d), abs(length(p) - 0.15));
    return d - o;
}

void main(void) {
    init();
    vec2 p = 5.0 * (gl_FragCoord.xy - 0.5*resolution.xy) / length(resolution.xy);
    float d = sd(p - vec2(-.1, .08));

    // modified from iq's sdf visualizing function
    vec3 col = d > 0. ? vec3(1.0, 0.3, 0.5) : vec3(0.3, 1.5, 2.7);
    col *= 1.0 - 0.9*exp(-6.*abs(d));
    col *= 0.8 + 0.2*cos(120.*d - 3.0*time);
    col = mix(col, vec3(1.0), 1.0 - smoothstep(0.0, 0.02, abs(d)));
    glFragColor = vec4(col, 1.0);
}
