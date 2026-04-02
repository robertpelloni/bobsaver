#version 420

// original https://www.shadertoy.com/view/MtyyRw

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// toggle for high quality
//#define HIGH_QUALITY

#ifdef HIGH_QUALITY
#define MARCH_STEPS 128
#else
#define MARCH_STEPS 32
#endif

int id = -1;

mat2 rotate(float a) {
    float c = cos(a);
    float s = sin(a);
    return mat2(c, s, -s, c);
}

float sinp(float a) {
    return .5 + sin(a) * .5;
}

float sinr(float a, float x, float y) {
    return x + sinp(a) * (y - x);
}

float hash21(in vec2 uv) {
    return fract(43758.5453 * sin(dot(uv, vec2(12.9898, 78.565))));
}

float noise(in vec2 uv) {

    vec2 fv = fract(uv);
    fv = fv * fv * (3. - 2. * fv);
    vec2 iv = floor(uv);
    vec2 o = vec2(1., 0.);

    float a = hash21(iv);
    float b = hash21(iv + o.xy);
    float c = hash21(iv + o.yx);
    float d = hash21(iv + o.xx);
    float ab = mix(a, b, fv.x);
    float cd = mix(c, d, fv.x);

    float mx = mix(ab, cd, fv.y);
    return mx;

}

// loopless fbm - 4 octaves
float fbm(in vec2 uv) {
    float v = 0.;
    v += noise(uv);
    v += noise(uv * 2.) * .5;
    v += noise(uv * 4.) * .25;
    v += noise(uv * 8.) * .125;
    return v / 1.625;
}

float water(in vec2 uv) {
    uv *= 4.;
    return fbm(uv + fbm(uv - time));
}

float map(in vec3 p) {
    float w = 1. - .1 * water(p.xz);
    float y = min(1.8 * fbm(p.xz), w);
    float d = dot(vec3(0., 1., 0.), vec3(p.x, p.y + y, p.z));
    if (y > w - .02) id = 1;
    else id = 2;
    return d;
}

vec3 normal(in vec3 p) {
    vec2 E = vec2(.001, 0.);
    return normalize(vec3(
        map(p + E.xyy) - map(p - E.xyy),
        map(p + E.yxy) - map(p - E.yxy),
        map(p + E.yyx) - map(p - E.yyx)
    ));
}

void main(void) {
    vec4 O = glFragColor;
    vec2 I = gl_FragCoord.xy;
    float T = time;
    vec2 R = resolution.xy;
    vec2 uv = (2. * I - R) / R.y;
    uv *= rotate(sinr(T * .5, -.3, .3));
    vec3 ro = vec3(10. * cos(T * .2), 1.25 + sin(T), T);
    vec3 rd = vec3(uv, 1.);
    float t = 0.;
    for (int i = 0; i < MARCH_STEPS; i++) {
        vec3 p = ro + rd * t;
        t += .5 * map(p);
    }   
    vec3 p = ro + rd * t;
    vec3 sc = vec3(.3, .05, 0.);
    if (t < 30.) {
        if (id == 1) {
            O = vec4(.0, 1. - fbm(p.xz), water(p.xz), 1.);
        }
        if (id == 2) {
            vec3 l = ro;
            vec3 p = ro + rd * t;
            vec3 n = normal(p);
            vec3 lp = normalize(l - p);
            vec3 d = vec3(0.650, 0.498, 0.407) *
                max(dot(lp, n), 0.);
            float s = .02 * pow(max(dot(reflect(lp, n), ro), 0.), .5);
            O = vec4(vec3(d + s), 1.);
        }
    } else {
        O = vec4(mix(vec3(0., .0, .1), vec3(.3, .05, 0.), uv.y + .5), 1.);
    }
    glFragColor = O;
}
