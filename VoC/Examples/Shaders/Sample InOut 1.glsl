#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/Nd3SzX

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
  // for calculating the stripes’ angle
  float stripeAngle = 0.3 * sin(time * TAU) + (0.5 + floor(angle * STRIPECOUNT / TAU - 2. * time) + 2. * time) * TAU / STRIPECOUNT;
  vec2 angleVec = vec2(cos(stripeAngle), sin(stripeAngle));
  // for calculating which color palette to use
  float dark = floor(mod(angle * STRIPECOUNT / TAU - 2. * time, 2.));
  
  const vec3 col0L = HEX(0x840DaE);
  const vec3 col1L = HEX(0x3BCEAC);
  const vec3 col2L = HEX(0xFFD23F);
  const vec3 col3L = HEX(0xEE4266);
  
  const vec3 col0D = HEX(0xEF476F);
  const vec3 col1D = HEX(0xFFD166);
  const vec3 col2D = HEX(0x06D6A0);
  const vec3 col3D = HEX(0x118AB2);
  
  vec3 col0 = mix(col0L, col0D, dark);
  vec3 col1 = mix(col1L, col1D, dark);
  vec3 col2 = mix(col2L, col2D, dark);
  vec3 col3 = mix(col3L, col3D, dark);
  
  float spiral = fract(
      3. * log(dot(uv, angleVec) * 2. + 0.05) + 8. * (2. * dark - 1.) * time
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
