#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define SEED vec3(5.8, 45.85, 7545.45)
float hash21(vec2 uv) {
    return fract(SEED.z * sin(dot(uv, SEED.xy)));
}

float valueNoise(vec2 uv) {
    vec2 i = floor(uv);
    vec2 f = fract(uv);
    f = f * f * (3. - 2. * f);
    vec2 o = vec2(1., 0.);
    return mix(
        mix(hash21(i + o.yy), hash21(i + o.xy), f.x),
        mix(hash21(i + o.yx), hash21(i + o.xx), f.x), f.y);
}

float fbm(vec2 uv) {
    float v = valueNoise(uv);
        v += valueNoise(uv * 2.) * .5;
        v += valueNoise(uv * 4.) * .25;
        v += valueNoise(uv * 8.) * .125;
        return v / 1.75;
}

// thanks to IQ :)
float noiseLayers(vec2 uv) {
    return fbm(uv + fbm(uv * 2. + time + fbm(uv * 4. + time)));
}

void main() {
    vec2 uv = (2. * gl_FragCoord.xy - resolution) / resolution.y;
    uv *= 2.;
    uv = abs(uv) + (2. + .8 * sin(time / 2.));
    float c = cos(.785398);
    float s = sin(.785398);
    mat2 r = mat2(c, s, -s, c);
    glFragColor = smoothstep(.3, .8, vec4(
        noiseLayers(r * uv + vec2(0., .1)),
        noiseLayers(r * r * uv + vec2(0., .15)),
        noiseLayers(r * r * r * uv + vec2(0., .1)),
        1.
    ));
}
