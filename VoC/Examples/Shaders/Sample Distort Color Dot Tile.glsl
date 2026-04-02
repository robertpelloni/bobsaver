#version 420

// original https://neort.io/art/bnnctd43p9f5erb53hpg

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;
uniform sampler2D backbuffer;

out vec4 glFragColor;

void main() {
  vec2 st = (gl_FragCoord.xy * 2.0 - resolution) / min(resolution.x, resolution.y);

  float lng = length(st);
  float at = atan(st.y, st.x) + 0.5 * time;
  st = vec2(cos(at) * lng , sin(at) * lng);
  st /= 0.2 + dot(lng, lng) * 0.1 + abs(sin(time * 0.5) + 0.5);

  st *= 50.0;
  vec2 a = mod(st, 5.0);
  vec2 id = st - a;
  vec3 color = vec3(sin(id.y + time));

  color +=  vec3(sin(id.x + time));

  vec2 id2 = st - mod(st, 5.0);
  color *= vec3(sin(id2.x),0.5,sin(id2.y));

  glFragColor = vec4(color, 1.0);
}
