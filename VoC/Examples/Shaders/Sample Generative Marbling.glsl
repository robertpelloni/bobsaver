#version 420

// original https://www.shadertoy.com/view/tssXR8

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const int AMOUNT = 11;

void main(void)
{
  vec2 p = 20.0 * (gl_FragCoord.xy - resolution.xy / 2.0) / min(resolution.y, resolution.x);

  float len;

  for(int i = 0; i < AMOUNT; i++){
    len = length(vec2(p.x, p.y));

    p.x = p.x - cos(p.y + sin(len)) + cos(time / 9.0);
    p.y = p.y + sin(p.x + cos(len)) + sin(time / 12.0);
  }

  vec3 col = vec3(0.2, cos(len), sin(len*4.6));
  
  glFragColor = vec4(col,1.0);
}
