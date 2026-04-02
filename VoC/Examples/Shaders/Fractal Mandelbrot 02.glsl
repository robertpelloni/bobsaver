#version 420

// co3moz - mandelbrot

uniform float time;
uniform vec2 resolution;

out vec4 glFragColor;

#define ITERATION 256

vec3 mandelbrot(vec2 p) {
  vec2 s = p;
  float d = 0.0, l;
    
  for (int i = 0; i < ITERATION; i++) {
    s = vec2(s.x * s.x - s.y * s.y + p.x, 2.0 * s.x * s.y + p.y);
    l = length(s);
    d += l + 5.9;
    if (l > 2.0) return vec3(sin(d * 0.0314), sin(d * 0.02), sin(d * 0.01));
  }
    
  return vec3(9.4);
}
    
void main() {
  vec2 a = resolution.xy / min(resolution.x, resolution.y);
  vec2 p = ((gl_FragCoord.xy / resolution.xy) * 4.0  - 2.0) * a;
  float f = sin(time * 0.05 + 99.0) * 0.5 + 0.5;
  p *= pow(1.5, f * (-30.0));
  p += vec2(-1.002029, 0.303864);
    
  glFragColor = vec4(1.0 - mandelbrot(p), 1.0);
}
