#version 420

// original https://neort.io/art/bqql4lc3p9f48fkis4qg

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;
uniform sampler2D backbuffer;

out vec4 glFragColor;

mat2 rotate(float r) {
    float c = cos(r);
    float s = sin(r);
    return mat2( c, -s, s, c);
}

void main() {
    vec2 st = (gl_FragCoord.xy * 2.0 - resolution) / min(resolution.x, resolution.y);

    st *= rotate(time);
    float lng = length(st);
    float at = atan(st.y, st.x) + lng * 3.0;
    st = vec2(cos(at) * lng, sin(at) * lng);
    st *= 1.0 + dot(lng, lng) * 0.5;

    vec3 color = vec3(0.5);
    for(int i=0; i<8; ++i) {
      st = abs(st / dot(st,st));
      st -= 0.8 - cos(time * 0.5) * 0.3;
    }
    color.g -= length(st) - 0.5;
    color -= st.xyy;

    glFragColor = vec4(color, 1.0);
}
