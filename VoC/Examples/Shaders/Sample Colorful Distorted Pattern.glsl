#version 420

// original https://neort.io/art/bnrbbms3p9f5erb545lg

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;
uniform sampler2D backbuffer;

out vec4 glFragColor;

void main() {
  vec2 st = (gl_FragCoord.xy * 2.0 - resolution) / min(resolution.x, resolution.y);

  float lng = length(st);
  float at = atan(st.y, st.x) + 0.1 * time;
  st = vec2(cos(at) * lng , sin(at) * lng);
  st /= dot(lng, lng) + 0.5;

  st *= 10.0;

  float c1 = sin( st.x * cos( time * 0.5 ) * 2.0 ) + cos( st.y * cos( time * 0.1 ) * 2.0 );
  float c2 = c1 + sin(st.y * sin( time * 0.1 ) * 10.0 ) + sin( st.x * sin( time * 0.1 ) * 4.0 );
  float c3 = c2 + sin( st.x * sin( time * 0.1 ) * 1.0 ) + cos( st.y * sin( time * 0.1 ) * 8.0 );

  vec3 color = vec3(c1,c2,c3);

  glFragColor = vec4(color, 1.0);
}
