#version 420

// original https://neort.io/art/bmpmvts3p9f7m1g02d50

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;
uniform sampler2D backbuffer;

out vec4 glFragColor;

void main() {
    vec2 st = (gl_FragCoord.xy * 2.0 - resolution) / min(resolution.x, resolution.y);
    st *= 5.0;
    vec2 id = st * 2.0 + time * 5.0;

    vec3 color = vec3(
      sin(length(id.x)),
      sin(length(id.x) - 2.0),
      sin(length(id.x) + 2.0));

    color += vec3(cos(st.x) + 0.5);

    glFragColor = vec4(color, 1.0);
}
