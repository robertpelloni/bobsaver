#version 420

// original https://www.shadertoy.com/view/4cXXRj

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec3 sunpos = vec3(-150, -55, 140);
float sunradius = 64.;

struct WarpData3d {
    vec3 s1;
    vec3 s2;
    float sf;
};

// https://iquilezles.org/articles/palettes/
// https://github.com/thi-ng/cgg
// https://github.com/ReimuA/cgg
vec3 palette(float x) {
    float t = clamp(x, 0., 1.);
    vec3 a = vec3(0.500, 0.500, -3.142);
    vec3 b = vec3(1.098, 1.028, 0.500);
    vec3 c = vec3(0.158, -0.372, 1.000);
    vec3 d = vec3(-0.262, 0.498, 0.667);
    return a + b * cos(6.28318 * (c * t + d));
}

vec3 rotateX(vec3 p, float angle) {
    return p * mat3x3(1.0, 0.0, 0.0, 0.0, cos(angle), -sin(angle), 0.0, sin(angle), cos(angle));
}

vec3 rotateY(vec3 p, float angle) {
    return p * mat3x3(cos(angle), 0.0, sin(angle), 0.0, 1.0, 0.0, -sin(angle), 0.0, cos(angle));
}

vec3 rotateZ(vec3 p, float angle) {
    return  p * mat3x3(cos(angle), -sin(angle), 0.0, sin(angle), cos(angle), 0.0, 0.0, 0.0, 1.0);
}

// https://gist.github.com/patriciogonzalezvivo/670c22f3966e662d2f83
vec4 mod289(vec4 x) {
    return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec4 perm(vec4 x) {
    return mod289(((x * 34.0) + 1.0) * x);
}

float noise3(vec3 p) {
    vec3 a = floor(p);
    vec3 d = p - a;
    d = d * d * (3.0 - 2.0 * d);

    vec4 b = a.xxyy + vec4(0.0, 1.0, 0.0, 1.0);
    vec4 k1 = perm(b.xyxy);
    vec4 k2 = perm(k1.xyxy + b.zzww);

    vec4 c = k2 + a.zzzz;
    vec4 k3 = perm(c);
    vec4 k4 = perm(c + 1.0);

    vec4 o1 = fract(k3 * (1.0 / 41.0));
    vec4 o2 = fract(k4 * (1.0 / 41.0));

    vec4 o3 = o2 * d.z + o1 * (1.0 - d.z);
    vec2 o4 = o3.yw * d.x + o3.xz * (1.0 - d.x);

    return o4.y * d.y + o4.x * (1.0 - d.y);
}

float fbm3(vec3 x, float h) {
    vec3 p = x;
    float g = exp2(-h);
    float f = 1.0;
    float a = 1.0;
    float t = 0.0;

    for (int i = 0; i < 12; i++) {
        t += a * noise3(f * p);
        f *= 2.0;
        a *= g;
        p = rotateX(p, 0.4);
        p = rotateY(p, 0.1);
        p = rotateZ(p, 0.7);
    }
    return t;
}

// https://iquilezles.org/articles/warp/ (2d version)
WarpData3d warp3d(vec3 point) {
    WarpData3d warpData;

    vec3 x = point;

    vec3 s1 = vec3(
        fbm3(x + vec3(32, 12, 2), 1.),
        fbm3(x + vec3(-23, 51.3, -4), 1.),
        fbm3(x + vec3(-3, 251.3, -14), 1.)
    );

    vec3 s2 = vec3(
        fbm3(s1 * 3. + vec3(1245.7, 19.2, 14), 1.),
        fbm3(s1 * 3. + vec3(0.3, 42.8, 4), 1.),
        fbm3(s1 * 3. + vec3(12.3, 2.8, 14), 1.)
    );

    float p = fbm3(x + s2 * 2.1, 1.);

    warpData.s1 = s1;
    warpData.s2 = s2;
    warpData.sf = p;
    return warpData;
}

float c01(float p){
    return clamp(p, 0.0, 1.0);
}

float sdfSphere(vec3 p, float r) {
    return length(p) - r;
}

float sdf(vec3 p) {
    return sdfSphere(p - sunpos, sunradius);
}

struct RaymarchData {
    float distance;
    float minDistance;
};

RaymarchData raymarch(vec3 rayOrigin, vec3 rayDirection) {
    float distance = 0.0;
    float maxDistance = 400.0;
    float minHitDistance = 0.001;
    RaymarchData rData;

    rData.minDistance = 5000000.;

    for (int i = 0; i < 64; i++) {
        if (distance > maxDistance) {
            break;
        }

        vec3 pos = rayOrigin + rayDirection * distance;

        float res = sdf(pos);

        rData.minDistance = min(rData.minDistance, res);

        if (res < minHitDistance) {
            rData.distance = distance + res;
            return rData;
        }

        distance += res;
    }

    rData.distance = -1.;

    return rData;
}

vec3 render(vec3 rayOrigin, vec3 rayDirection) {
    RaymarchData rData = raymarch(rayOrigin, rayDirection);

    if (rData.distance < 0.) {
        vec3 c = vec3(0.1, 0., 0);
        float r = smoothstep(0., 1.5, rData.minDistance);
        return mix(0.05 / c, vec3(0.), r);
    }

    vec3 point = rayOrigin + rayDirection * rData.distance;
    vec3 nPos = point - sunpos;
    nPos /= 10.;
    nPos += vec3(1.1, -3, 12.) * time / 60.;
    nPos = rotateY(nPos, 1. * time / 24.);
    WarpData3d wd = warp3d(nPos);
    float idx = mix(length(wd.s1) / 4., length(wd.s2) / 3.6, (wd.sf));
    return palette(idx);
}

mat3x3 cam(vec3 ro, vec3 ta) {
    vec3 cw = normalize(ta - ro);
    vec3 cp = vec3(0.0, 1.0, 0.0);
    vec3 cu = normalize(cross(cw, cp));
    vec3 cv = cross(cu, cw);

    return mat3x3(cu, cv, cw);
}

void main(void) {
    float camspeed = 1.25;
    vec3 ta = vec3(0., -.75, 0.);
    vec3 ro = ta + vec3(4.9, 2., -4.9);
    mat3x3 ca = cam(ro, ta);

    vec2 st = (2. * gl_FragCoord.xy - resolution .xy) / resolution .y;
    vec3 rd = normalize(ca * normalize(vec3(st, 2.5)));
    vec3 color = render(ro, rd);
    vec3 gammaCorrected = pow(color, vec3(1.0 / 2.6));
    
    glFragColor = vec4(gammaCorrected, 1.0);
}
