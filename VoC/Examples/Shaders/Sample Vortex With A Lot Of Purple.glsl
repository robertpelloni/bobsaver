#version 420

// original https://neort.io/art/bn889043p9f5erb51tc0

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;
uniform sampler2D backbuffer;

out vec4 glFragColor;
#define PI 3.14159265359
#define TWO_PI 6.28318530718

float shape(vec2 p,float radius){

    float at = atan(p.x,p.y) - time * 0.2 + PI;
    float ar = TWO_PI/float(8);
    float d = cos(floor(0.5 + at/ar) * ar - at) * length(p);

    float r = length(p) * radius;
    float a = atan(length(p)) + time;
    return abs(tan(r + a - d));
}

void main() {
  vec2 st = (gl_FragCoord.xy * 2.0 - resolution) / min(resolution.x, resolution.y);
  vec2 st2 = st * 2.0;

  float lng = length(st);
  float at = atan(st.y, st.x) + lng * 5.0;
  st = vec2(cos(at) * lng, sin(at) * lng);
  st *= 10.0 + dot(lng, lng) * 0.5;

  vec3 color = vec3(shape(st, 0.5));
  color *= vec3(1.0,0.2,0.8);
  color *= vec3(1.0,0.5,shape(st2, 2.0) + sin(time * 2.0));

  glFragColor = vec4(color, 1.0);

}
