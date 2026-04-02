#version 420

// original https://www.shadertoy.com/view/sdlBWf

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Author: John Ao
// License: CC BY-NC 4.0

#define AA 16
#define eps 0.001
#define R 0.07
#define N_STEP 100
#define offset vec3(0.5)

float sdf(vec3 p) {
    p = fract(p + offset);
    p = min(p, 1. - p);
    p *= p;
    return sqrt(p.x < p.y ? p.x + min(p.y, p.z) : p.y + min(p.x, p.z)) - R;
}

float sum3(vec3 x) {
    return x.x + x.y + x.z;
}

float max3(vec3 x) {
    return max(x.x, max(x.y, x.z));
}

float min3(vec3 x) {
    return min(x.x, min(x.y, x.z));
}

float cube_intersect(vec3 o, vec3 d) {
    vec3 a = 1. / d, b = -o * a, c = abs(a) * 0.5;
    float t1 = max3(b - c), t2 = min3(b + c);
    return 0. < t1 && t1 < t2 ? t1 : -1.;
}

float random2(vec2 seed) {
    return fract(1e3 * sin(seed.x * 12345. + seed.y) * sin(seed.y * 1234. + seed.x));
}

void main(void) {
    vec3 cam = normalize(vec3(sin(time), cos(time), sin(time * 0.7 + 1.)));
    vec3 x_ = normalize(cross(vec3(0., 0., 1.), cam));
    vec3 y_ = normalize(cross(cam, x_));
    cam *= 3.;
    vec2 uv;
    float col = 0.;
    // col = random2(vec2(time)*1e-5+uv);
    for (int i = 0; i < AA; ++i) {
        uv = 1.5 * (2. * (gl_FragCoord.xy + vec2(random2(vec2(time) * 1e-5 + uv), random2(vec2(time) * 1e-4 + uv))) - resolution.xy) / max(resolution.x, resolution.y);
        vec3 d = normalize(uv.x * x_ + uv.y * y_ - cam);
        float r = cube_intersect(cam, d);
        if (r > 0.) {
            float r_ = sdf(cam + r * d);
            if (r_ > eps) {
                r += r_;
                for (int j = 0; j < N_STEP; ++j) {
                    r_ = sdf(cam + r * d);
                    r += r_;
                    if (r_ < eps) {
                        col += pow(0.7, sum3(abs(floor(cam + r * d + offset))));
                        break;
                    }
                }
            }
        } else {
            col += 0.3;
        }
    }
    glFragColor = vec4(vec3(col / float(AA)), 1.0);
}
