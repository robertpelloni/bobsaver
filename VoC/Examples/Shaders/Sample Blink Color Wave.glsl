#version 420

// original https://neort.io/art/bn2q5hs3p9f80jer87hg

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
  float at = atan(st.y, st.x) + lng;
  st = vec2(cos(at) * lng, sin(at) * lng) * rotate(-time * 0.2);
  st *= 4.0 + dot(lng, lng) * 0.5;

  vec2 id = mod(st * 2.0,1.0);
  id -= 0.5;

  float t = time * 5.0;
  vec3 color = vec3(
    sin(length(st) * st.x + t + 0.5),
    sin(length(st) * st.x + time),
    sin(length(st) * st.x + t - 0.5));
  color = mix(color,
    vec3(
      sin(length(id) * st.y + time + 0.5),
      sin(length(id) * st.y + t),
      sin(length(id) * st.y + time - 0.5)
    ),0.5);

  glFragColor = vec4(color, 1.0);

}
