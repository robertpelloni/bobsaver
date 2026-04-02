#version 420 core

uniform sampler2D state;
uniform sampler2D history;

uniform vec4 blur;
uniform mat4 coupling;
uniform vec4 speed;
uniform vec4 decay;

in vec2 coord;
out vec4 glFragColor;

out vec4 state_out;
out vec4 history_out;

void main()
{
  vec4 s1 = texture(state, coord, 1.0);
  vec4 s100 = texture(state, coord, 100.0);
  vec4 s;
  for (int k = 0; k < 4; ++k)
    s[k] = texture(state, coord, blur[k])[k];
  vec4 h = texture(history, coord);
  s = coupling * (s - s100) + h;
  s = speed * s;
  s = mix(s1, vec4(0.5) + 0.5 * cos(s), 0.125);
  h = mix(s, h, decay);
  state_out = s;
  history_out = h;
}
