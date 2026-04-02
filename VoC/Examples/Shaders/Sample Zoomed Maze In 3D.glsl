#version 420

// original https://www.shadertoy.com/view/ctGGDz

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec3 axis_rotation(vec3 P, vec3 Axis, float angle) {
  Axis = normalize(Axis);
  return mix(Axis * dot(P, Axis), P, cos(angle)) + sin(angle) * cross(P, Axis);
}

float fsnoise(vec2 v) {
  return fract(sin(dot(v, vec2(12.9898, 78.233))) * 43758.5453);
}

void main(void) {
  vec3 uv = normalize(vec3(gl_FragCoord.xy - 0.5 * resolution.xy, -resolution.y));
  vec3 dir = axis_rotation(uv, vec3(2.,1.,1.), .9);  // view direction
  vec3 Po = vec3(0., 1., 1.);  // view origin
  float wall_thickness = 0.4;
  float scale = 4.0;
  float luminosity = 0.5;
  float steps = 0., distance = 0.;
  while (++steps < 99.) {
    vec3 P = Po + dir * distance;
    float l = length(P.xz);
    // https://www.osar.fr/notes/logspherical/
    // switch to 'polar' log-spherical coordinates
    P.xz = vec2(log(l) - time, atan(P.z, P.x)) * scale;
    vec2 I = ceil(P.xz);   // integer part = cell ID
    P.xz -= I;  // fractional part
    // the 'maze' itself:
    float v = abs(fract((fsnoise(I) < .5 ? -P.z : P.z) - P.x) - .5);
    v = (wall_thickness - v) * luminosity * l / scale;
    // here, walls are infinitely high, so we cut them with the plane P.y
    l = max(P.y, v);
    // advance the marching
    distance += l;
    if (l < 1e-4) break;
  }
  glFragColor = vec4(10. / steps);  // divide by steps => ~AO
}

