#version 420

// original https://www.shadertoy.com/view/MdVfWy

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.141592654
#define HASHSCALE1 .1031

const float EPS = 1e-2;
float OFFSET = EPS * 5.0;
float TIME;

vec3 hue(float hue) {
    vec3 rgb = fract(hue + vec3(0., 2. / 3., 1. / 3.));
    rgb = abs(rgb * 2. - 1.);
    return clamp(rgb * 3. - 1., 0., 1.);
}

vec3 hsvToRgb(vec3 hsv) {
    return ((hue(hsv.x) - 1.) * hsv.y + 1.) * hsv.z;
}

float hash11(float p) {
    vec3 p3 = fract(vec3(p) * HASHSCALE1);
    p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.x + p3.y) * p3.z);
}

float hash12(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * HASHSCALE1);
    p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.x + p3.y) * p3.z);
}

vec2 rotate2d(vec2 p, float angle) {
    return p * mat2(cos(angle), -sin(angle),
        sin(angle), cos(angle));
}

vec3 rotateX(vec3 p, float angle) {
    float c = cos(angle);
    float s = sin(angle);
    return vec3(p.x, c * p.y + s * p.z, -s * p.y + c * p.z);
}

vec3 rotateY(vec3 p, float angle) {
    float c = cos(angle);
    float s = sin(angle);
    return vec3(c * p.x - s * p.z, p.y, s * p.x + c * p.z);
}

float qinticInOut(float t) {
    return t < 0.5 ?
        +16.0 * pow(t, 5.0) :
        -0.5 * pow(2.0 * t - 2.0, 5.0) + 1.0;
}

float sineInOut(float t) {
    return -0.5 * (cos(PI * t) - 1.0);
}

float box(vec2 p, float size) {
    p += 0.5;
    size = 0.5 + size * 0.5;
    p = step(p, vec2(size)) * step(1.0 - p, vec2(size));
    return p.x * p.y;
}

float postEffectPattern(vec2 p) {
    float t1 = fract(TIME);
    float e11 = qinticInOut(t1) - 0.5;

    float t2 = fract(TIME - 0.05);
    float e21 = qinticInOut(t2) - 0.5;
    float e22 = sineInOut(t2) - 0.5;

    float ofs = 0.6 + TIME * 0.2;
    float diff = 0.35;
    float scale = 1.3;

    float index = 2.;
    index = mix(index, 5., box(rotate2d(p, PI * e11 + ofs + diff * 1.), scale * 3.6 * abs(e11)));
    index = mix(index, 4., box(rotate2d(p, PI * e11 + ofs + diff * 2.), scale * 3.6 * abs(e11)));
    index = mix(index, 1., box(rotate2d(p, PI * e21 + ofs + diff * 3. + 0.2), scale * 3.6 * abs(e21)));
    index = mix(index, 0., box(rotate2d(p, PI * e21 + ofs + diff * 3. + 0.2), scale * 3.0 * abs(e21)));
    index = mix(3., index, box(rotate2d(p, PI * e22 + ofs + diff * 0.), 20. * abs(e22)));

    return index;
}

float sdHexPrism(vec3 p, vec2 h) {
    vec3 q = abs(p);
    return max(q.z - h.y, max((q.x * 0.866025 + q.y * 0.5), q.y) - h.x);
}

float sdPlane(vec3 p) {
    return p.y + 5.;
}

float udBox(vec3 p, vec3 b, float r) {
    return length(max(abs(p) - b, 0.0)) - r;
}

float sdSphere(vec3 p, float s) {
    return length(p) - s;
}

float sdTorus(vec3 p, vec2 t) {
    vec2 q = vec2(length(p.xz) - t.x, p.y);
    return length(q) - t.y;
}

float dGlass(vec3 p) {
    float it = mod(floor(TIME - 0.5), 4.);

    if (it == 0.)
        return sdSphere(p, .6);
    if (it == 1.)
        return sdTorus(rotateX(p, PI / 2.), vec2(.5, .2));
    if (it == 2.)
        return sdHexPrism(p, vec2(0.45));
    if (it == 3.)
        return udBox(rotateY(rotateX(p, PI / 4.), PI / 4.), vec3(0.4), 0.05);
}

float map(vec3 p) {
    float b = sdPlane(p);
    float c = dGlass(p);
    return min(b, c);
}

vec3 floorPattern(vec2 p) {
    return vec3(0.2) * mod(floor(p.x * 0.3) + floor(p.y * 0.3), 2.0);
}

vec2 intersect(vec3 ro, vec3 ray) {
    float t = 0.0;
    for (int i = 0; i < 256; i++) {
        float res = abs(map(ro + ray * t));
        if (res < 0.005) return vec2(t, res);
        t += res;
    }

    return vec2(-1.0);
}

vec3 normal(vec3 pos, float e) {
    vec3 eps = vec3(e, 0.0, 0.0);

    return normalize(vec3(
        map(pos + eps.xyy) - map(pos - eps.xyy),
        map(pos + eps.yxy) - map(pos - eps.yxy),
        map(pos + eps.yyx) - map(pos - eps.yyx)));
}

mat3 createCamera(vec3 ro, vec3 ta, float cr) {
    vec3 cw = normalize(ta - ro);
    vec3 cp = vec3(sin(cr), cos(cr), 0.0);
    vec3 cu = normalize(cross(cw, cp));
    vec3 cv = normalize(cross(cu, cw));
    return mat3(cu, cv, cw);
}

vec3 renderScene(vec2 p) {
    float t1 = fract(TIME);
    float e1 = qinticInOut(t1) - 0.5;
    float e2 = sineInOut(t1) - 0.5;
    float ofs = 0.6 + TIME * 0.2;
    float t2 = abs(1. - e2 - ofs) * PI;

    vec3 ro = vec3(cos(t2) * 24. * e1, 2., sin(t2) * 24. * e1);
    vec3 ta = vec3(0);
    mat3 cm = createCamera(ro, ta, 0.);
    vec3 ray = cm * normalize(vec3(p, 10.0));

    vec3 fresnel = vec3(0);

    for (int i = 0; i < 6; i++) {
        vec2 res = intersect(ro, ray);

        if (res.y <= -0.5) {
            return vec3(1);
        }

        vec3 pos = ro + ray * res.x;
        vec3 nor = normal(pos, 0.008);

        if (dGlass(pos) > 0.005) {
            vec3 col = vec3(0);
            col += floorPattern(pos.xz);
            col += fresnel;
            return col + vec3(0.001, 0.002, 0.004) * res.x * 3.;
        }

        if (i == 0 && dot(-ray, nor) < 0.5) {
            float a = 1. - dot(-ray, nor) * 2.;
            fresnel = mix(fresnel, vec3(0., 0.8, 0.8), a);
        }

        float eta = 1.1;

        bool into = dot(-ray, nor) > 0.0;
        nor = into ? nor : -nor;
        eta = into ? 1.0 / eta : eta;

        ro = pos - nor * OFFSET;
        ray = refract(ray, nor, eta);

        if (ray == vec3(0.0)) {
            ro = pos + nor * OFFSET;
            ray = reflect(ray, nor);
        }
    }
}

vec3 render(vec2 p) {
    vec3 col = renderScene(p);
    float effect = postEffectPattern(p);
    float hue = hash11(floor(TIME + 0.5));

    if (effect == 0.)
        return col;
    if (effect == 1.)
        return hsvToRgb(vec3(hue + p.x * .08, 1, 1));
    if (effect == 2.)
        return mix(col, hsvToRgb(vec3(hue - 0.2 - p.y * .08, 1, 1)), 0.7);
    if (effect == 3.)
        return vec3(1.);

    return mix(col, hsvToRgb(vec3(hue + (effect - 4.) * 0.1, 1, 1)), 0.7);
}

vec3 aaRender(vec2 p) {
    vec3 col = vec3(0.0);
    const int num = 4;

    for (int i = 0; i < num; i++) {
        float fi = float(i + 1);
        col += render(p + vec2(step(fi, 2.001), mod(fi, 2.001)) * 0.0015);
    }

    return col / float(num);
}

void main(void) {
    vec2 uv = (gl_FragCoord.xy * 2.0 - resolution.xy) / min(resolution.x, resolution.y);

    float timeScale = 0.7;
    TIME = time * timeScale + 10.;

    vec3 col = aaRender(uv);
    glFragColor = vec4(pow(col, vec3(1.0 / 2.2)), 1.0);
}
