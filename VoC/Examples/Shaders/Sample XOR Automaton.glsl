#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/Wl2yWw

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// "Circuit Diagram2" by ntsutae (modified by jarble)
// https://twitter.com/ntsutae/status/1268820823952916486
// https://www.openprocessing.org/sketch/912094
void main(void) {
  int x = int(gl_FragCoord.xy.x);
  int y = int(gl_FragCoord.xy.y);
  int r = (x+y+int(time*50.0))^(x-y);
  bool b = abs(r*r*r/(y+x)) % (999970) < 100000;
  glFragColor = vec4(vec3(b ? 1.0 : 0.0), 1.0);
}
