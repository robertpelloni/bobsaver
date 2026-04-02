#version 420

// original https://neort.io/art/bnpcdh43p9f5erb53sg0

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;
uniform sampler2D backbuffer;

out vec4 glFragColor;

#define PI 3.14159265359
#define TWO_PI 6.28318530718

float shape(vec2 p,float radius){
    float at = atan(p.x,p.y) + PI;
    float ar = TWO_PI/float(3);
    float d = cos(floor(0.5 + at/ar) * ar - at) * length(p);

    float r = length(p) * radius;
    float a = atan(length(p)) - time;
    return abs(tan(r + a - d));
}

void main() {
  vec2 st = (gl_FragCoord.xy
     * 2.0 - resolution) / min(resolution.x, resolution.y);

  float lng = length(st);
  float at = atan(st.y, st.x) + 0.1 * time;
  st = vec2(cos(at) * lng , sin(at) * lng);
  st /= 0.1 + dot(lng, lng) * 2.0;

  st *= 10.0;
  st = mod(st,2.0);
  st -= 1.0;

  vec3 color = vec3(shape(st,1.0),step(shape(st,0.1),1.0),shape(st,2.0));
  color -= vec3(length(st));

  glFragColor = vec4(color, 1.0);
}
