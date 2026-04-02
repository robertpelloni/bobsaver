#version 420

// original https://www.shadertoy.com/view/fd3yDB

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define TAU (6.283185307)
#define HEX(x) (vec3((x >> 16) & 255, (x >> 8) & 255, x & 255) / 255.)

#define HEARTCOUNT 8.
#define HEARTSCALE 1.

#define LAYERS 32.
#define LAYERSPERLOOP 6.
#define LAYERSTAGGER -2.
#define ALLROT 1./48.
#define LAYERSCALE 0.5
#define TOOFAR 1./16.

float genHearts(float dist, float angle) {
    angle = min(1.0, 1.5 * abs(2. * fract(angle * HEARTCOUNT) - 1.));
    float angle2 = (1. - angle) * (1. - angle) * -0.2 + abs(1. - 2. * fract(angle));
    angle2 *= angle2;
    float dist2 = abs(dist - 1.0) * HEARTCOUNT / 8. * HEARTSCALE;
    return mix (
    step(
        dist2 * dist2 * 8. + angle - 0.9
    , 0.), step(
        dist2 * 16.0 + angle2 * 3.0 - 2.
    , 0.), step(1.0, dist)
    );
}
void main(void)
{
  float time = fract(1./3.*time);
  // Normalized pixel coordinates (from 0 to 1)
  float scale = min(resolution.x, resolution.y);
  vec2 uv = (2. * gl_FragCoord.xy - resolution.xy) / scale;
  
  float dist = length(uv) * 3.;
  float angle = atan(uv.y, uv.x) / TAU;
  
  float hearts = 0.;
  
  for (float i = 0.; i < LAYERS; i++) {
      float depth = (
          LAYERS - i
          - time * LAYERSPERLOOP
      );
      hearts = mix(
          hearts, 1. - 2. * step(0.5, fract(i * 0.5)),
          genHearts(
              dist * depth * LAYERSCALE,
              angle + depth * ALLROT + i * (LAYERSTAGGER / LAYERSPERLOOP / HEARTCOUNT)
          )
      );
  }
  float toofar = step(TOOFAR, dist);
  
  float palette = step(0.5, fract(
      0.3 * log(dist) + angle * 1. + time
  ));
  
  vec3 col = mix(
      vec3(0.22, 0.19, 0.36), // dark
      vec3(1.0, 0.85, 0.95), // light
      palette
  );
  // positive hearts
  col = mix(
      col, mix(
          vec3(0.6, 0.5, 0.9),
          vec3(1.),
          palette
      ),
      step(0.5, hearts)
  );
  // negative hearts
  col = mix(
      col, mix(
          vec3(0.),
          vec3(1.0, 0.65, 0.8),
          palette
      ),
      step(0.5, -hearts)
  );
  
  // too far
  col *= toofar;
  
  // Output to screen
  glFragColor = vec4(
    col, 1.0
  );
}
