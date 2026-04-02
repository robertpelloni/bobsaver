#version 420

// original https://www.shadertoy.com/view/3l2XRW

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

mat2 rot(float a) {
    float c = cos(a);
    float s = sin(a);
    return mat2(c, s, -s, c);
}

float hash(float x) {
    return mod(x*324327. * sin(x*423254.), 1.0);
}

float smax(float x, float y) {
    return log(exp(x*10.) + exp(y*10.))/10.;
}

float smin(float x, float y) {
    return -smax(-x, -y);
}

float box(vec3 p, vec3 s) {
    vec3 d = abs(p) - s;
    return length(max(d, 0.0)) + min(max(d.x, max(d.y, d.z)), 0.0);
}

vec3 eyepos() {
    return vec3(4. * cos(time * .3), 5. * sin(time * .26), 3. * sin(time * .11));
}

float sdf(vec3 p) {
    float eyeball = length(p - eyepos()) - .1;
    float d0 = 1.;
    float s = 1.;
    float m = 1.35 + .2 * sin(time * 0.29);
    for (int i = 0; i < 6; i++) {
        p.xy = rot(time * .23) * p.xy;
        p.y = -abs(p.y);
        p += vec3(.3, 1.+sin(time * 0.27), cos(time * .29));
        p.yz = rot(time * .07) * p.yz;
        p.x = -abs(p.x - .4) + .9;
        p *= m;
        s *= m;
        float d = min(box(p, vec3(0.5)), box(p - vec3(0.5), vec3(0.5)));
        d0 = smin(d/s, d0);
    }
    return smax(d0, -eyeball);
}

vec3 normal(vec3 p) {
    float h = 0.001;
    vec3 a1 = vec3(1., 1., 1.);
    vec3 a2 = vec3(1., -1., -1.);
    vec3 a3 = vec3(-1., 1., -1.);
    vec3 a4 = vec3(-1., -1., 1.);
    return normalize(a1 * sdf(p + h * a1) + a2 * sdf(p + h * a2) + a3 * sdf(p + h * a3) + a4 * sdf(p + h * a4));
}

vec3 sky(vec3 r) {
    return vec3(.5, .2, .2) + r.y * vec3(-.5 * r.y, -.1 * r.y, .1);
}
vec3 march(vec3 start, vec3 r) {
            vec3 c = vec3(1.);
    float t = 0.0;
    for (int i = 0; i < 99; i++) {
        vec3 p = start + t * r;
        float d = min(sdf(p), .5);
        c -= vec3(.01);

        if (d < 0.001) {
            vec3 n = normal(p);
            float ao = exp(sdf(p + n/5.) + sdf(p + n/4.)+ sdf(p + n/3.));
            return mix( c * (vec3(.5 + .2 * dot(n, normalize(eyepos() - p)),.6,.9 + .5 * n.y) + .0 * n) * ao , sky(r),t/(vec3(5., 3., 1.)+t));
        }
        t += d;
    }
    return sky(r);
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy - resolution.xy * 0.5)/resolution.y;
    vec3 eye = eyepos();
    vec3 look = vec3(0.);
    vec3 fwd = normalize(look - eye);
    vec3 up = vec3(0., 1., 0.);
    vec3 right = normalize(cross(fwd, up));
    up = normalize(cross(right, fwd));
    vec3 r = normalize(uv.x * right + uv.y * up + fwd);
    float vignette = 1. - length(uv)/3.;
    vec3 c = march(eye, r) * vignette;
    float w = (c.r + c.g + c.b) / 3.+ .1 * hash(uv.x+hash(uv.y)+hash(time*.1));
    glFragColor = vec4(c * w / (.1 + w), 1.0) * vignette;
}
