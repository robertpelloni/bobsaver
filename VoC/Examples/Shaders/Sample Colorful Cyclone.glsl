#version 420

// original https://neort.io/art/bn1k6kc3p9f80jer82vg

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

  // bump
  float lng = length(st);
  float at = atan(st.y, st.x) * 2.0 + lng * 20.0;
  st = vec2(cos(at) * lng, sin(at) * lng) * rotate(time * 0.5);
  st *= 2.0 + dot(lng, lng) * 0.5;

  vec3 color = vec3(sin(length(st) * st.x + time),
    sin(length(st) * st.x + time),
    sin(length(st) * st.x + time + 1.0));
  color = mix(color,
    vec3(1.0 - sin(length(st) * st.y + time),
    sin(length(st) * st.y + time + 1.0),
    sin(length(st) * st.y + time)),0.5);

  glFragColor = vec4(color, 1.0);

}
