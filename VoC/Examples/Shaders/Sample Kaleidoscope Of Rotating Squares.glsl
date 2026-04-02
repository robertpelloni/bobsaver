#version 420

// original https://www.shadertoy.com/view/3lB3RW

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec2 rotate(vec2 p, float a) {
  return p * mat2(cos(a), -sin(a), sin(a), cos(a));
}

void main(void) {
  vec2 uv = (gl_FragCoord.xy - .5 * resolution.xy) / resolution.y;

  vec2 gv = fract(abs(uv) * 2.) - .5;
  vec2 id = floor(abs(uv) * 2.);
  float t = ((mod(id.x, 2.) == 0.) ? -1. : 1.) * time * .1;
  gv = rotate(gv, t);

  vec3 color = vec3(0.);

  float m = smoothstep(.34, .32, max(abs(gv.x), abs(gv.y))) +
    (smoothstep(.5, 0., length(gv))*1.1);

  float squares = cos(max(abs(gv.x), abs(gv.y)) * (80. * (sin(time * .2) * .4 + 1.)));
  float diamonds = cos(max(abs(gv.x+gv.y), abs(gv.y-gv.x)) * 50. - time);

  color += smoothstep(.1, .9, diamonds)*vec3(.35);
  color += mix(vec3(.2), vec3(.5), cos(length(uv)*150.*cos(gv.y) - time * 2.)) * .01;

  color = mix(color, vec3(.3, .4, .5), squares * m) * 1.2;
  color *= mix(color, vec3(.8, .4, .2), diamonds / m) * 2.;

  color += smoothstep(.1, .2, squares) * vec3(.3, .2, .8);
  color -= mix(vec3(0.), vec3(.8, .2, .3), smoothstep(.1, .12, diamonds * m)) * .5;

  color *= 1.-length(uv)*.6;

  glFragColor = vec4(color, 1.);
}
