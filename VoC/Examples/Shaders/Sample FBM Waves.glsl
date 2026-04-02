#version 420

// original https://www.shadertoy.com/view/sdjSDR

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define draw(d, c) color = mix(color, c, smoothstep(unit, 0.0, d))

vec2 const2dual(in float x) {
    return vec2(x, 0.0);
}

vec2 var2dual(in float x) {
    return vec2(x, 1.0);
}

vec2 fMul(in vec2 a, in vec2 b) {
    return vec2(a.x * b.x, a.x * b.y + a.y * b.x);
}

vec2 fDiv(in vec2 a, in vec2 b) {
    return vec2(a.x / b.x, (b.x * a.y - a.x * b.y) / (b.x * b.x));
}

vec2 fSquare(in vec2 z) {
    return vec2(z.x * z.x, 2.0 * z.x * z.y);
}

vec2 fCos(in vec2 z) {
    return vec2(cos(z.x), -sin(z.x) * z.y);
}

vec2 fMin(in vec2 a, in vec2 b) {
    return a.x < b.x ? a : b;
}

vec2 fMax(in vec2 a, in vec2 b) {
    return a.x > b.x ? a : b;
}

vec2 fFloor(in vec2 z) {
    return vec2(floor(z.x), 0.0);
}

vec2 fCeil(in vec2 z) {
    return vec2(ceil(z.x), 0.0);
}

vec2 fFract(in vec2 z) {
     return vec2(fract(z.x), z.y);
}

vec2 fClamp(in vec2 z, in vec2 edge0, in vec2 edge1) {
    return fMax(edge0, fMin(edge1, z));
}

vec2 fSmoothstep(in vec2 edge0, in vec2 edge1, in vec2 z) {
    z = fClamp(fDiv(z - edge0, edge1 - edge0), vec2(0.0), vec2(1.0, 0.0));
    vec2 sq = fSquare(z);
    return 3.0 * sq - 2.0 * fMul(sq, z);
}

vec2 fMix(in vec2 a, in vec2 b, in vec2 t) {
    return a + fMul(b - a, t);
}

vec2 noise(in vec2 x) {
    return fFract(367.436 * fCos(439.573 * x));
}

vec2 snoise(in vec2 x) {
    return fMix(noise(fFloor(x)), noise(fCeil(x)), fSmoothstep(const2dual(0.0), const2dual(1.0), fFract(x)));
}

vec2 rollingNoise(in vec2 x, in float scale, in float roll, in int octaves) {
    x /= scale;

    vec2 value = const2dual(0.0);
    float tscale = 0.0;
    float nscale = 1.0;

    for (int o=0; o < octaves; o++) {
        value += snoise(x - const2dual(roll)) * nscale;
        tscale += nscale;
        nscale *= 0.5;
        x *= 2.0;
    }

    return value / tscale;
}

void main(void) {
    vec2 uv = (gl_FragCoord.xy - 0.5 * resolution.xy) / resolution.y * 8.0;
    float unit = 16.0 / resolution.y;

    // Draw the function
    vec2 y = rollingNoise(var2dual(uv.x), 3.0, time, 10) * 3.0;
    float d = abs(uv.y - y.x) / sqrt(1.0 + y.y * y.y);

    glFragColor = vec4(smoothstep(unit, 0.0, d) + 0.25 * y.x);
}
