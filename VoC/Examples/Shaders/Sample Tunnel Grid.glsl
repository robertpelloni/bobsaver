#version 420

// original https://www.shadertoy.com/view/sdtyD7

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define TAU (6.283185307)
#define HEX(x) (vec3((x >> 16) & 255, (x >> 8) & 255, x & 255) / 255.)

float fade(float t) {
  return t * t * t * (t * (t * 6. - 15.) + 10.);
}

float fadestep(float t) {
  return floor(t) + fade(min(1., fract(t) * 1.2));
}

float zigzag(float x) {
    return 1. - abs(1. - 2. * fract(x));
}

#define DISTSCALE -0.1
#define ZOOMDIST -4.
#define ZOOMCONST -1.
#define SPEED 1./3.
#define DISTSTEP 12.0
#define ANGLESTEP 16.0

void main(void)
{
  float time = fract(time * SPEED);
  // Normalized pixel coordinates (from 0 to 1)
  float scale = min(resolution.x, resolution.y);
  vec2 uv = (gl_FragCoord.xy - 0.50 * resolution.xy) / scale;
  
  float dist = DISTSCALE / (sqrt(uv.x * uv.x + uv.y * uv.y));
  float angle = atan(uv.y, uv.x) / TAU;
  float dark = mod(floor(time * 50.), 2.);
  
  const vec3 col0 = HEX(0x010a31);
  const vec3 col1 = HEX(0xEB0072);
  const vec3 col2 = HEX(0x009BE8);
  const vec3 col3 = HEX(0xfff100);
  
  float dStep = round((dist - ZOOMCONST * time) * DISTSTEP) / DISTSTEP;
  float aStep = round(ANGLESTEP * angle) / ANGLESTEP;
  
  float spiral1 = step(fract(0.1 +
      + 2. * aStep
      + dStep
      + ZOOMDIST * fadestep(time)
      + ZOOMCONST * time
  ), 0.5);
  float spiral2 = step(fract(0.1 +
      - 2. * aStep
      + dStep
      + ZOOMDIST * fadestep(fract(time + 0.5))
      + ZOOMCONST * time
  ), 0.5);
  
  vec3 col = mix(
      mix(col0, col1, spiral1),
      mix(col2, col3, spiral1),
      spiral2
  );
  
  float alpha = step(abs(dist), 4.2);
  alpha *= step(0.125, zigzag(0.5 + (dist - ZOOMCONST * time) * DISTSTEP));
  alpha *= step(0.125, zigzag(0.5 + angle * ANGLESTEP));
  
  col = mix(
      vec3(1), col, alpha
  );
  // Output to screen
  glFragColor = vec4(
    col, 1.0
  );
}
