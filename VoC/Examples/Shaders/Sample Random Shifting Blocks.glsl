#version 420

// original https://www.shadertoy.com/view/4llcWS

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec2 random2( vec2 p ) {
    return fract(sin(vec2(dot(p,vec2(127.1,311.7)),dot(p,vec2(269.5,183.3))))*(43758.5453 + time));
}

mat2 rotate2d(float _angle){
    return mat2(cos(_angle),-sin(_angle),
                sin(_angle),cos(_angle));
}

void main(void)
{
  float gridSize = 8.;
  vec2 uv = vec2(gl_FragCoord.x / resolution.x, gl_FragCoord.y / resolution.y);
  uv -= 0.5;
  uv *= rotate2d(time / 10. * 3.14);
  uv *= max(1., abs(cos(time / 5.)) * 3.);
  uv += vec2(cos(time / 2.), sin(time / 4.));
  uv /= vec2(resolution.y / resolution.x, 1);
  uv.x += step(1., mod(uv.y * gridSize, 2.)) * (time / 3.) * step(0., cos(time));
  uv.y += step(1., mod(uv.x * gridSize, 2.)) * (time / 3.) * step(0., sin(time));

  vec2 fpos = fract(uv);
  fpos.y = -fpos.y;
  uv *= gridSize;

  vec2 gridPosition = floor(random2(floor(uv)) * gridSize) / gridSize;

  vec4 color = vec4(abs(sin(time)), gridPosition, 1) * 0.5 + 0.5;

  glFragColor = color;
}
