#version 420

uniform sampler2D state;

uniform mat4 color;
uniform vec4 offset;

in vec2 coord;

out vec4 color_out;

void main()
{
  vec4 s = texture(state, coord);
  vec4 c = color * s + offset;
  color_out = clamp(c, 0.0, 1.0);
}
