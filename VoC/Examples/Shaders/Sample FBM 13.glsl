#version 420

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;

out vec4 glFragColor;

float random (in vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898,78.233)))* 43758.5453123);
}

float noise (in vec2 st) {
    vec2 i = floor(st);
    vec2 f = fract(st);

    float a = random(i);
    float b = random(i + vec2(1., 0.));
    float c = random(i + vec2(0., 1.));
    float d = random(i + vec2(1., 1.));

    vec2 u = f * f * (3. - 2. * f);

    return mix(a, b, u.x) + (c - a)* u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

    #define octaves 5

float fbm (in vec2 p) {
    float value = 0.;
    float freq = 1.;
    float amp = .5;

    for (int i = 0; i < octaves; i++) {
        value += amp * (noise((p - vec2(1.)) * freq));
        freq *= 2.3;
        amp *= .4;
    }

    return value;
}

float pattern(in vec2 p) {
    vec2 offset = vec2(-.1);

    vec2 aPos = vec2(sin(time * .1), sin(time * .1)) * 6. + time*0.1;
    vec2 aScale = vec2(3.);
    float a = fbm(p * aScale + aPos);

    vec2 bPos = vec2(sin(time * .1), sin(time * .1)) * 1. + time*0.05;
    vec2 bScale = vec2(.5);
    float b = fbm((p + a) * bScale + bPos);

    vec2 cPos = vec2(-.6, -.5) + vec2(sin(-time * .01), sin(time * .1)) * 2. - time*0.02;
    vec2 cScale = vec2(2.);
    float c = fbm((p + b) * cScale + cPos);

    return c;
}

void main() {
    vec2 p = 3. * gl_FragCoord.xy / resolution.xy;
    p.x *= resolution.x / resolution.y;

    float value = pow(pattern(p), 1.);

    glFragColor = vec4(vec3(value, value/2., value/1.5), 1.);
}
