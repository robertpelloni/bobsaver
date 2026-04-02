#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/7d3XzX

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define TAU (6.283185307)
#define HEX(x) (vec3((x >> 16) & 255, (x >> 8) & 255, x & 255) / 255.)
#define STRIPECOUNT 14.

void main(void)
{
  float time = fract(time / 4.);
  // Normalized pixel coordinates (from 0 to 1)
  float scale = min(resolution.x, resolution.y);
  vec2 uv = (gl_FragCoord.xy - 0.50 * resolution.xy) / scale;
  
  float dist = length(uv);
  float angle = atan(uv.y, uv.x);
  // for calculating the parity of the stripe
  float dark = floor(mod(angle * STRIPECOUNT / TAU - 2. * time, 2.));
  // for calculating the stripes’ angle
  float stripeAngle = ((0.5) * time * TAU) + (0.5 + floor(angle * STRIPECOUNT / TAU - 2. * time) + 2. * time) * TAU / STRIPECOUNT;
  vec2 angleVec = vec2(cos(stripeAngle), sin(stripeAngle));
  // for calculating which palette to use
  float palette = step(fract(
      log(dist + 0.01) + angle / TAU + time * 1.
  ), 0.5);
  
  const vec3 col0L = HEX(0x840DaE);
  const vec3 col1L = HEX(0x3BCEAC);
  const vec3 col2L = HEX(0xFFD23F);
  const vec3 col3L = HEX(0xEE4266);
  
  const vec3 col0D = HEX(0x118AB2);
  const vec3 col1D = HEX(0xEF476F);
  const vec3 col2D = HEX(0xFFD166);
  const vec3 col3D = HEX(0x06D6A0);
  
  vec3 col0 = mix(col0L, col0D, palette);
  vec3 col1 = mix(col1L, col1D, palette);
  vec3 col2 = mix(col2L, col2D, palette);
  vec3 col3 = mix(col3L, col3D, palette);
  
  float spiral = fract(
      0.7 * log(
          abs(
              dot(uv, angleVec)
          ) + 0.02
      ) * (
          1.1 - cos(TAU * (0.5 - time))
      ) + (
          -12. * time
      )
  );
  
  vec3 col = mix(
      mix(
          col0, col1, step(spiral, 0.75)
      ), mix(
          col2, col3, step(spiral, 0.25)
      ), step(spiral, 0.5)
  );
  // Output to screen
  glFragColor = vec4(
    col, 1.0
  );
}
