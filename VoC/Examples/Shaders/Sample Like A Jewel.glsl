#version 420

// original https://neort.io/art/brf1ltk3p9f9ke955fb0

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
    vec3 color = vec3(1.0);
    float lng = length(st);

    st *= rotate(time * 0.2);

    for(int i=0; i< 6; ++i) {
      st = abs(st / dot(st,st));
      st -= 0.9 - cos(time * 0.5) * 0.3;
    }

    float at = atan(st.y, st.x);
    color -= dot(cos(at), cos(at)) * 2.0;
    color *= fract(dot(cos(at),cos(at)) - time * 0.5);
    color *= mix(color, vec3(0.8,0.4,0.2), 0.5);
    color /= lng - 0.5;

    glFragColor = vec4(color * 2.0, 1.0);
}
