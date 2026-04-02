#version 420

// original https://www.shadertoy.com/view/MsK3zG

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
  vec2 R = resolution.xy, m = mouse*resolution.xy.xy / R;
  glFragColor = vec4(gl_FragCoord.xy / R.y, .5-m.x+.02*sin(time),0);
  for (int i = 0; i < 128; i++)
    glFragColor.xzy = vec3(1.3, 1, .777) * abs(glFragColor.xyz/dot(glFragColor,glFragColor)-vec3(1,1,m.y*.3));
}
