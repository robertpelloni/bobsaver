#version 420

// original https://www.shadertoy.com/view/WtB3RW

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec2 rotate(vec2 p, float a) {
  return p * mat2(cos(a), -sin(a), sin(a), cos(a));
}

void main(void) {
  vec2 uv = (gl_FragCoord.xy - .5 * resolution.xy) / resolution.y;

  vec2 gv = fract(abs(uv) * length(uv) * 5.) - .5;
  vec2 id = floor((abs(uv) - length(uv * sin(uv.y - time * .04) * 2.)) * 4.);
  float t = ((mod(id.y, 2.) == 0.) ? -5. : 2.) * time * .05;

  gv = rotate(dot(gv, gv) + (gv + sin(t * .02) * .5 + .5) * ((gv.y * gv.x) + cos(t * .2) * .5 + .5), t);
  gv.y += sin(t * .5);

  vec3 color = vec3(0.);

  float m = smoothstep(.34, .32, max(abs(gv.x), abs(gv.y))) +
    (smoothstep(.5, 0., length(gv))*1.1);

  float squares = cos(max(abs(gv.x), abs(gv.y)) * (28. * (sin(time * .02) * .4 + 1.))) - uv.x;
  float diamonds = cos(max(abs(gv.x+gv.y), abs(gv.y-gv.x)) * 28. - (time * .02)) - uv.y;

  color += smoothstep(.1, .9, diamonds) * vec3(uv.y + .5);// *  2.;
  color += mix(vec3(.2), vec3(.5), cos(length(uv)*5.*cos(gv.y) - time * .02)) * (uv.x + .5) * .2;

  color += mix(color, vec3(.2, .3, .9), smoothstep(.05, .8, squares));
  color *= mix(color, vec3(.8, .4, .2), smoothstep(.05, .8, diamonds-m));

  color += smoothstep(.1, .2, squares) * vec3(.3, .2, .8);

  // filter
  color *= smoothstep(1.1, .1, length(uv))*2.;
  color -= smoothstep(.8, .5, 1. - length(id * abs(uv)));

  glFragColor = vec4(color, 1.);
}
