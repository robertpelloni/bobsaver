#version 420

// original https://neort.io/art/bno2d4k3p9f5erb53mp0

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;
uniform sampler2D backbuffer;

out vec4 glFragColor;

void main() {
  vec2 st = (gl_FragCoord.xy
     * 2.0 - resolution) / min(resolution.x, resolution.y);

  float lng = length(st);
  float at = atan(st.y, st.x) + 0.1 * time;
  st = vec2(cos(at) * lng , sin(at) * lng);
  st /= 0.8 + dot(lng, lng) * 1.5;

  st *= 20.0;
  vec2 a = mod(st, 1.0);
  vec2 id = st - a;
  vec3 color = vec3(sin(length(id * sin(id.x)) + time));

  color +=  vec3(sin(id.x + time) + sin(id.y + time));

  vec2 id2 = st - mod(st, 1.0);
  color *= vec3(sin(length(id2)),0.5,sin(id2.x * id2.y));

  glFragColor = vec4(color, 1.0);
}
