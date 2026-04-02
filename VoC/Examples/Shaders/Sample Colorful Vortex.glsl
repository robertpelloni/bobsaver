#version 420

// original https://neort.io/art/bnmmn9k3p9f5erb53f3g

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;
uniform sampler2D backbuffer;

out vec4 glFragColor;

void main() {
  vec2 st = (gl_FragCoord.xy * 2.0 - resolution) / min(resolution.x, resolution.y);

  float lng = length(st);
  float at = atan(st.y, st.x) + 0.5 * time + lng * 5.0;
  st = vec2(cos(at) * lng, sin(at) * lng);
  st *= 1.0 + dot(lng, lng) * 0.5 + sin(time);

  st *= 2.0;
  vec2 a = mod(st, 5.0);
  vec2 id = st - a;

  vec3 color = vec3(length(sin(id+time)),sin(id.x+time),sin(id.y+time));

  st *= 2.0;
  vec2 id2 = st - mod(st, cos(time));
  color *= vec3(sin(id2.x),sin(id2.y),sin(id2.y));

  glFragColor = vec4(color, 1.0);
}
