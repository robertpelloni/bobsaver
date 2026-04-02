#version 420

// original https://neort.io/art/bob6d743p9fd1q8obbj0

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;
uniform sampler2D backbuffer;

out vec4 glFragColor;

const float PI = acos(-1.0);

mat2 rotate(float r) {
    float c = cos(r);
    float s = sin(r);
    return mat2( c, -s, s, c);
}

vec3 tex(vec2 st){
    st *= rotate(PI/3.55);
    st *= 2.5;

    float f = length(st.y) + length(st.x);
    float at = atan(st.y, st.x) + length(st) * 5.0;

    return vec3(sin(f + at - time),sin(f + f + at - time),sin(f + f + f + at - time));
}

void main() {
    vec2 st = (gl_FragCoord.xy * 2.0 - resolution) / min(resolution.x, resolution.y);

    st *= rotate(PI/4.0);
    st *= 10.0;

    st = mod(st,2.0);
    st -= 1.0;

    vec3 color = tex(st);
    glFragColor = vec4(color, 1.0);
}
