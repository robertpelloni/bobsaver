#version 420

// original https://www.shadertoy.com/view/stdfRj

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// "Circuit Diagram2" by ntsutae (modified by jarble)
// https://twitter.com/ntsutae/status/1268820823952916486
// https://www.openprocessing.org/sketch/912094

//mutated by derSchamane 2022 = Colored Ancient Circuit Diagram =

void main(void) {
  int x = int(gl_FragCoord.xy.x);
  int y = int(gl_FragCoord.xy.y + 30. * time + 10000.);
  int r = (x+y)^(x-y);
  float k = smoothstep(.5, 1., cos(time/5.+float(r)/(1000.+sin(time/11.)*300.)))-sin(time/8.+float(r)/100.)*0.2;
  float b = smoothstep(k*1., 1.+k*3., float(abs(r*r*r/(y+x+int(time*50.))) % (9970))/1000.);
  glFragColor = vec4(vec3((1.+cos(time/9.)*.3-k)-b*b, (1.-k)-b, b*.3+k*.2), 1.);
}
