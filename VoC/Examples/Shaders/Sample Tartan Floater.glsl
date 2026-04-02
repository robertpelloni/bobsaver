#version 420

// original https://www.shadertoy.com/view/3lVGDy

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define M_PI 3.1416

void main(void)
{     
  vec2 t = gl_FragCoord.xy/resolution.y;
  float r = M_PI/4. * sin(time*.5);
  t = mat2(cos(r), sin(r), -sin(r), cos(r))*(t - .5);
  t *= 2. + .8*sin(time);
  t.y += time;
  t = fract(t);
  float lines = 9.;

  vec2 ic = (floor(t*lines*10.));
  float pat = step(mod(ic.x-ic.y, 3.), 1.);
  float bc = .8;

  vec2 cut = step(abs((t-.5)*lines*2.), vec2(5.));
  float hb = mod(ceil(t.y*lines), 2.);
  float hw = 1. - hb;

  float alpha = 0.95;
  float col = mix(bc, 1. - (hb*pat), alpha*hb*cut.y*pat);
  col = mix(col, hw*pat, alpha*hw*cut.y*pat);

  pat = 1. - pat;
  float vb = mod(ceil(t.x*lines), 2.);
  col = mix(col, 1. - (vb*pat), alpha*vb*cut.x*pat);
  float vw = 1. - vb;
  col = mix(col, vw*pat, alpha*vw*cut.x*pat); 

  vec2 red = step(lines*2.-1., floor(abs(t-.5)*lines*4.));
  vec3 vcol = vec3(col);
  vcol = mix(vcol, vec3(red.x*pat, 0., 0.), alpha*red.x*pat);
  vcol = mix(vcol, vec3(red.y*(1.-pat), 0, 0.), alpha*red.y*(1.-pat));

  glFragColor = vec4(vcol, 1.);

}
