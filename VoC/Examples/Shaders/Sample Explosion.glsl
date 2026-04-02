#version 420

// original https://neort.io/art/bnbh3lk3p9f5erb528qg

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;
uniform sampler2D backbuffer;

out vec4 glFragColor;

#define PI 3.14159265359
#define TWO_PI 6.28318530718

float shape(vec2 p,float radius){

    float at = atan(p.x,p.y) * 5.0 + time * 0.5 + PI;
    float ar = TWO_PI/5.0;
    float d = cos(floor(0.5 + at/ar) * ar - at) * length(p);

    float r = length(p) * radius * 2.0;
    float a = atan(length(p)) + time * 2.0;
    return abs(tan(r + a - d));
}

void main() {
  vec2 st = (gl_FragCoord.xy * 2.0 - resolution) / min(resolution.x, resolution.y);
  vec2 st2 = st * 10.0;

  float lng = length(st);
  float at = atan(st.y, st.x) + lng * 20.0;
  st = vec2(cos(at) * lng, sin(at) * lng);
  st *= 2.0 + dot(lng, lng) * 0.5;

  vec3 color = vec3(shape(st, 0.1));
  color *= vec3(shape(st2, 0.1));
  color *= vec3(0.8,0.6,0.1);

  glFragColor = vec4(color, 1.0);

}
