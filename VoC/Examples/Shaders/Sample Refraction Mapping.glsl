#version 420

// original https://www.shadertoy.com/view/4dVfR3

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define TAU 6.283185307
#define PI 3.141592654

const float EPS = 1e-2;
const float EPS_N = 1e-3;
float OFFSET = EPS * 300.0;

float TIME;

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

vec4 permute(vec4 x) { return mod(((x * 34.0) + 1.0) * x, 289.0); }
vec4 taylorInvSqrt(vec4 r) { return 1.79284291400159 - 0.85373472095314 * r; }

float snoise(vec3 v) {
    const vec2 C = vec2(1.0 / 6.0, 1.0 / 3.0);
    const vec4 D = vec4(0.0, 0.5, 1.0, 2.0);

    vec3 i = floor(v + dot(v, C.yyy));
    vec3 x0 = v - i + dot(i, C.xxx);

    vec3 g = step(x0.yzx, x0.xyz);
    vec3 l = 1.0 - g;
    vec3 i1 = min(g.xyz, l.zxy);
    vec3 i2 = max(g.xyz, l.zxy);

    vec3 x1 = x0 - i1 + 1.0 * C.xxx;
    vec3 x2 = x0 - i2 + 2.0 * C.xxx;
    vec3 x3 = x0 - 1. + 3.0 * C.xxx;

    i = mod(i, 289.0);
    vec4 p = permute(permute(permute(
                i.z + vec4(0.0, i1.z, i2.z, 1.0)) +
            i.y + vec4(0.0, i1.y, i2.y, 1.0)) +
        i.x + vec4(0.0, i1.x, i2.x, 1.0));

    float n_ = 1.0 / 7.0; // N=7
    vec3 ns = n_ * D.wyz - D.xzx;

    vec4 j = p - 49.0 * floor(p * ns.z * ns.z); //  mod(p,N*N)

    vec4 x_ = floor(j * ns.z);
    vec4 y_ = floor(j - 7.0 * x_); // mod(j,N)

    vec4 x = x_ * ns.x + ns.yyyy;
    vec4 y = y_ * ns.x + ns.yyyy;
    vec4 h = 1.0 - abs(x) - abs(y);

    vec4 b0 = vec4(x.xy, y.xy);
    vec4 b1 = vec4(x.zw, y.zw);

    vec4 s0 = floor(b0) * 2.0 + 1.0;
    vec4 s1 = floor(b1) * 2.0 + 1.0;
    vec4 sh = -step(h, vec4(0.0));

    vec4 a0 = b0.xzyw + s0.xzyw * sh.xxyy;
    vec4 a1 = b1.xzyw + s1.xzyw * sh.zzww;

    vec3 p0 = vec3(a0.xy, h.x);
    vec3 p1 = vec3(a0.zw, h.y);
    vec3 p2 = vec3(a1.xy, h.z);
    vec3 p3 = vec3(a1.zw, h.w);

    //Normalise gradients
    vec4 norm = taylorInvSqrt(vec4(dot(p0, p0), dot(p1, p1), dot(p2, p2), dot(p3, p3)));
    p0 *= norm.x;
    p1 *= norm.y;
    p2 *= norm.z;
    p3 *= norm.w;

    // Mix final noise value
    vec4 m = max(0.6 - vec4(dot(x0, x0), dot(x1, x1), dot(x2, x2), dot(x3, x3)), 0.0);
    m = m * m;
    return 42.0 * dot(m * m, vec4(dot(p0, x0), dot(p1, x1),
        dot(p2, x2), dot(p3, x3)));
}

float sdPlane(vec3 p) {
    return p.y + 3.5;
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

float sdGlass(vec3 p) {
    float t = TIME * 1.9;
    float it = mod(floor(t), 4.);
    float ft = smoothstep(0.3, 0.9, fract(t));
    float nt = step(it, 0.) - step(it, 1.);

    p.yx += snoise(p * 1. + vec3(t, -t, 0)) * sin(fract(t) * PI) * nt * 0.2;
    float torus = sdTorus(rotateX(p, PI / 2.), vec2(.5, .2));
    float sphere = sdSphere(p, .6);
    float box = udBox(rotateY(rotateX(p, PI / 4.), PI / 4.), vec3(0.4), 0.05);

    if (it == 0.)
        return mix(box, sphere, ft);
    if (it == 1.)
        return sphere;
    if (it == 2.)
        return mix(sphere, torus, ft);
    if (it == 3.)
        return mix(torus, box, ft);
}

float map(vec3 p) {
    float b = sdPlane(p);
    float c = sdGlass(p);
    return min(b, c);
}

float rand(vec2 st) {
    return fract(sin(dot(st, vec2(12.9898, 78.233))) * 43758.5453);
}

float box_size(vec2 st, float n) {
    st = (floor(st * n) + 0.5) / n;
    float offs = rand(st) * 5.;
    return (1. + sin(TIME * 3. + offs)) * 0.5;
}

float box(vec2 st, float size) {
    size = 0.5 + size * 0.5;
    st = step(st, vec2(size)) * step(1.0 - st, vec2(size));
    return st.x * st.y;
}

vec3 pattern(vec2 p) {
    float n = 1.;
    vec2 st = fract(p * n);
    float size = box_size(p, n);
    return vec3(box(st, size)) * 0.5;
}

vec2 intersect(vec3 ro, vec3 ray) {
    float t = 0.0;
    for (int i = 0; i < 256; i++) {
        float res = map(ro + ray * t);
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

vec3 render(vec2 p) {
    vec3 ro = vec3(6., 2.5, 6.);
    vec3 ta = vec3(0);
    mat3 cm = createCamera(ro, ta, 0.);
    vec3 ray = cm * normalize(vec3(p, 10.0));

    vec3 lim = vec3(0, 0, 0);

    for (int i = 0; i < 2; i++) {
        // marching loop
        vec2 res = intersect(ro, ray);

        // hit check
        if (res.y > -0.5) {
            vec3 pos = ro + ray * res.x;
            vec3 nor = normal(pos, 0.008);

            if (sdGlass(pos) > 0.005) {
                vec3 col = vec3(0);
                col += pattern(pos.xz);
                col += lim;
                return col + vec3(0.001, 0.002, 0.004) * res.x;
            }

            if (i == 0 && dot(-ray, nor) < 0.5) {
                float a = 1. - dot(-ray, nor) * 2.;
                lim = mix(lim, vec3(0., 0.8, 0.8), a);
            }

            float eta = 0.9;
            ray = normalize(refract(ray, nor, eta));
            ro = pos + ray * OFFSET;

        } else {
            return vec3(1.0);
        }
    }
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

void main(void)
{
  vec2 uv = (gl_FragCoord.xy * 2.0 - resolution.xy) / min(resolution.x, resolution.y);

  TIME = time;
  vec3 color = aaRender(uv) + 0.2;
  glFragColor = vec4(color, 1.0);
}
