#version 420

// original https://www.shadertoy.com/view/fdl3R7

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float twopi = 4. * asin(1.);       // 6.283
const float K = float(0x3d28) / 65536.;  // 0.238
const float dirZ = 92. / 256.;           // 0.359

// Estimate the distance to the two parts of the complement of the gyroid surface.
// Find out which one is the closest.
float gyroid(vec3 p, out int id) {
  float d = dot(sin(p+vec3(K*twopi)), sin(p.zxy));  // sin(p+1.501) is almost a cos
  id = int(round(d));
  return 0.21552 * (1.442695 - abs(d));
}

// Step along the ray. Return the position of the hit.
vec3 trace(in vec3 pos, in vec3 dir, out int id, out int iters) {
  iters = 23;
  for (int i=23; i>0; i--) {
    float d = gyroid(twopi*pos, id);
    pos += d*dir;
    if (d < 0.041) break;
    iters = i-1;
  }
  return pos;
}

void main(void) {
  vec2 uv = (gl_FragCoord.xy - resolution.xy*0.5) / resolution.x;  // x:-0.5..0.5 like in the intro
  uv.y = -uv.y;
  uv = floor(uv*320.) / 320.;    // simulate 320x200 pixels
  float t = time * 35. / 256.;  // aim for 35 fps, period = 256 frames

  int id, iters;
  vec3 pos = trace(vec3(K,0.,t), vec3(uv,dirZ), id, iters);
  int tex = int(4. * fract(pos.x * 16.));
  float col = float(iters + tex);
  glFragColor = vec4(col/32., id>0? col/64. : 0., 0., 1.);
}
