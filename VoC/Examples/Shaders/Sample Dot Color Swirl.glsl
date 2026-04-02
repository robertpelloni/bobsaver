#version 420

// original https://www.shadertoy.com/view/tsGSz3

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void) {
  vec2 uv = (2.0 * gl_FragCoord.xy - resolution.xy) / resolution.xy;
  vec3 c = uv.xyx / dot(uv.xy, uv.xy) * (cos(time / 10.0) + 1.0)
         + uv.yxx / dot(uv.xy, uv.xy) * (sin(time / 10.0) + 1.0);
  for(int i = 0; i < 10; i++) {
    float t = tan(dot(uv,uv) / 20.0) - 0.35 * sin(dot(c,c)) - 0.35 * cos(dot(c,c));
    c += t / 50.0;
  }
  //c += texture(iChannel0,uv).rgb;
  c += tan(c * (sin(time / 5.0) + 2.0) * 5.0);
  glFragColor = vec4(c, 1.0);
}
