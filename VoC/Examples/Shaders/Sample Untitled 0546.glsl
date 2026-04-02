#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float layer(vec2 uv) {
    float s = .5;
    for (int i = 0; i < 8; i++) {
        uv = abs(uv) - s;
        uv *= 1.25;
        uv = uv.yx;
        float cs = cos(time * .1);
        float sn = sin(time * .1);
        uv *= mat2(cs, sn, -sn, cs);
        s *= .995;
    }
    float d = abs(max(abs(uv.x), abs(uv.y)) -.3);
     return .01 / d;
}

void main() {
    vec2 uv = (2. * gl_FragCoord.xy - resolution) / resolution.y;
    float s = .5;    
    for (int i = 0; i < 4; i++) {
        uv = abs(uv) - s;
        uv *= 1.25;
        uv = uv.yx;
        float cs = cos(time * .1);
        float sn = sin(time * .1);
        uv *= mat2(cs, sn, -sn, cs);
        s *= .995;
    }
    float cs = cos(time * .1);
    float sn = sin(time * .1);
    uv *= mat2(cs, sn, -sn, cs);
    vec3 col = vec3(0.);
    for (float i = 0.; i < 1.; i += .4) {
        float cs = cos(.8);
        float sn = sin(.8);
        uv *= mat2(cs, sn, -sn, cs);
        float t = fract(i + time * .5);
        float s = smoothstep(1., 0., t);
        float f = smoothstep(2., .1, t);
        f *= smoothstep(0., 1., t);
        col += layer(uv * s) * f;
    }
    glFragColor = vec4(col, 1.);
}
