#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

mat2 rotate(float a) {
    float c = cos(a),
        s = sin(a);
    return mat2(c, -s, s, c);
}

void main() {
    vec2 uv = (2. * gl_FragCoord.xy - resolution) / resolution.y;
    float s = 1.;
    float t = 0.;
    uv = fract(uv) - .5;
    for (int i = 0; i < 32; i++) {
        uv = abs(uv) - s;
        uv *= rotate(.3 + time * .1);
        s *= .955;
    }
    glFragColor = vec4(vec3(.05 / length(uv)), 1.);
}
