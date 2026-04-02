#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec2 rotate(vec2 k, float t) {
  return vec2(cos(t)*k.x - sin(t)*k.y, sin(t)*k.x + cos(t)*k.y);
}

float cast_sky(vec3 p) {
  float t1 = length( abs(mod(vec3(p.x, p.y - time, p.z - time), 2.0) - 1.0)) - 0.4;
  return t1;
}

void main( void ) {
  vec2 position = ( gl_FragCoord.xy / resolution.xy );
  vec2 uv = -1.0 + 2.0 * position;
  vec3 dir = normalize(vec3(uv * vec2(1.25, 1.0), 1.0));
  
  dir.xy = rotate(dir.xy, time * 0.2);
  dir.zx = rotate(dir.zx, time * 0.01);
  vec3 pos = vec3(0.0, 2.0, time * 3.0);
  vec3 ray = pos;
  float  t = 0.0;
  for(int i = 0 ; i < 70; i++) {
    float k = cast_sky(ray + dir * t);
    t += k * 0.75;
  }
  vec3 hit = ray + dir * t;
  vec2 h   = vec2(0.01, 0.00);

  vec3 N   = normalize(vec3(
    cast_sky(hit + h.xyy),
    cast_sky(hit + h.yxy),
    cast_sky(hit + h.yyx)) - cast_sky(hit));
    glFragColor = vec4(1.0-(N + t * 0.1), 1);
}
