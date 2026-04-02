#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/sdG3zw

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define TAU (6.283185307)

// A single iteration of Bob Jenkins' One-At-A-Time hashing algorithm.
uint hash(uint x) {
    x &= 65535u;
    x += ( x << 10u );
    x ^= ( x >>  6u );
    x += ( x <<  3u );
    x ^= ( x >> 11u );
    x += ( x << 15u );
    return x & 65535u;
}
// fade function defined by ken perlin
vec2 fade(vec2 t) {
  return t * t * t * (t * (t * 6. - 15.) + 10.);
}
// corner vector
vec2 cvec(vec2 uv, float time) {
  uint x = uint(mod(uv.x, 256.));
  uint y = uint(mod(uv.y, 256.));
  float n = (float(hash(x + hash(y))) / 65535. + time) * TAU;
  return vec2(
      sin(n), cos(n)
  );
}
// perlin generator
float perlin(vec2 uv, float offset) {
  vec2 i = floor(uv);
  vec2 f = fract(uv);

  vec2 u = fade(f);
  offset = fract(offset);

  return
  mix(
    mix(
      dot( cvec(i + vec2(0.0,0.0), offset ), f - vec2(0.0,0.0) ),
      dot( cvec(i + vec2(1.0,0.0), offset ), f - vec2(1.0,0.0) ),
    u.x),
    mix(
      dot( cvec(i + vec2(0.0,1.0), offset ), f - vec2(0.0,1.0) ),
      dot( cvec(i + vec2(1.0,1.0), offset ), f - vec2(1.0,1.0) ),
    u.x),
  u.y);
}

void main(void)
{
  float time = fract(time / 2.5);
  // Normalized pixel coordinates (from 0 to 1)
  float scale = min(resolution.x, resolution.y);
  vec2 uv = (gl_FragCoord.xy - 0.50 * resolution.xy) / scale;
  float dist = log(uv.x * uv.x + uv.y * uv.y);
  float angle = atan(uv.y, uv.x) / TAU;

  float noise = perlin(uv * 10.5, time);
  noise += 0.5 * perlin(uv * 34.0, -2. * time);
  noise *= max(0.0, dist * 0.2 + 2.);
  
  float dark = smoothstep(
      0.0, 0.4, (0.2 + length(uv)) * sin(TAU * 2. * time + 0.6 * dist) + 0.3 * noise
  );
  
  const vec3 colBaseL = vec3(92, 128, 1) / 255.;
  const vec3 colSp1L = vec3(124, 181, 24) / 255.;
  const vec3 colSp2L = vec3(251, 176, 45) / 255.;
  
  const vec3 colBaseD = vec3(50, 13, 109) / 255.;
  const vec3 colSp1D = vec3(0, 36, 0) / 255.;
  const vec3 colSp2D = vec3(251, 97, 7) / 255.;
  
  vec3 colBase = mix(colBaseL, colBaseD, dark);
  vec3 colSp1  = mix(colSp1L,  colSp1D, dark);
  vec3 colSp2  = mix(colSp2L,  colSp2D, dark);
  
  float spiral1 = step(fract(0.2 * noise + 2. * angle + 0.5 * dist + time), 0.4);
  float spiral2 = step(fract(0.2 * noise + 2. * angle + 0.5 * dist + 2. * time + 0.5), 0.2);
  
  vec3 col = mix(
      mix(
          colBase, colSp1, spiral1
      ), colSp2, spiral2
  );
  // Output to screen
  glFragColor = vec4(
    col, 1.0
  );
}
