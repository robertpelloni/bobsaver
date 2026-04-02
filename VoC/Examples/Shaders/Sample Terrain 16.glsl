#version 420

// original https://www.shadertoy.com/view/mlt3W2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define EPSILON 0.001
#define MAX_DIST 200.
#define MAX_ITER 300

vec2 fixUV(vec2 uv) {
    return (2. * uv - resolution.xy) / resolution.x;
}

float random(vec2 pos) {
    vec3 p3  = fract(vec3(pos.xyx) * .1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

vec3 noised(vec2 pos) {
    vec2 i = floor(pos);
    vec2 f = fract(pos);
    vec2 u = f * f * (3.0 - 2.0 * f);
    vec2 du = 6.0 * f * (1.0 - f);

    float a = random(i);
    float b = random(i + vec2(1.0, 0.));
    float c = random(i + vec2(0.0, 1.0));
    float d = random(i + vec2(1.0, 1.0));

    return vec3(mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y,
                du*(vec2(b-a,c-a)+(a-b-c+d)*u.yx));
}

const mat2 m2 = mat2(0.8, -0.6, 0.6, 0.8);

float ground(vec2 p) {
    float a = 0.0;
    float b = 1.0;
    vec2 d = vec2(0.0);
    for (int i = 0; i < 9; i++) {
        vec3 n = noised(p);
        d += n.yz;
        a += b * n.x / (1.0 + dot(d, d));
        b *= 0.5;
        p = m2 * p * 2.0;
    }
    return a;
}

float rayMarch(vec3 ro, vec3 rd) {
    float t = 0.;
    for (int i = 0; i < MAX_ITER; i++) {
        vec3 p = ro + t * rd;
        float h = p.y - ground(p.xz);
        if (abs(h) < EPSILON * t || t > MAX_DIST)
            break;
        t += 0.2 * h;
    }
    return t;
}

vec3 calcNorm(vec3 p) {
    vec2 epsilon = vec2(1e-5, 0);
    return normalize(vec3(
        ground(p.xz + epsilon.xy) - ground(p.xz - epsilon.xy),
        2.0 * epsilon.x,
        ground(p.xz + epsilon.yx) - ground(p.xz - epsilon.yx)
    ));
}

mat3 setCamera(vec3 ro, vec3 target, float cr) {
    vec3 z = normalize(target - ro);
    vec3 up = normalize(vec3(sin(cr), cos(cr), 0));
    vec3 x = cross(z, up);
    vec3 y = cross(x, z);
    return mat3(x, y, z);
}

vec3 render(vec2 uv) {
    vec3 col = vec3(0);

    float an = sin(time * .2) * .2 + .4;
    float r = 3.1;
    vec3 ro = vec3(r * sin(an), 1., r * cos(an));
    vec3 target = vec3(0, 0, 0);
    mat3 cam = setCamera(ro, target, 0.);

    float fl = 1.;
    vec3 rd = normalize(cam * vec3(uv, fl));

    float t = rayMarch(ro, rd);

    if (t < MAX_DIST) {
        vec3 p = ro + t * rd;
        vec3 n = calcNorm(p);
        vec3 difColor = vec3(0.67, 0.57, 0.44);
        col = difColor * dot(n, vec3(0, 1, 0));
    }

    return pow(col, vec3(1.0/2.2));
}

void main(void) {
    vec3 col = vec3(0.0);
    int AA = 1;
    if (AA > 1) {
    for (int m = 0; m < AA; m++)
    for (int n = 0; n < AA; n++) {
        vec2 o = vec2(float(m), float(n)) / float(AA) - 0.5;
        vec2 s = fixUV(gl_FragCoord.xy + o);
        col += render(s);
    }
    col /= float(AA * AA);
    } else {
    col = render(fixUV(gl_FragCoord.xy));
    }
    glFragColor = vec4(col, 1.);
}
