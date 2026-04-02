#version 420

// original https://www.shadertoy.com/view/fdcBR2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define TURN (6.283185307)
#define HEX(x) vec3((ivec3(x)>>ivec3(16,8,0))&255)/255.

float zig(float x) {return 1. - abs(1. - 2. * fract(x));}

float post(float x, float lvs) {
    return round(x * lvs) / lvs;
}

void main(void)
{
  float time = fract(time / 2.);
  // Normalized pixel coordinates (from 0 to 1)
  float scale = min(resolution.x, resolution.y);
  vec2 uv = (gl_FragCoord.xy - 0.50 * resolution.xy) / scale;
  float dist = log2(uv.x * uv.x + uv.y * uv.y);
  float a = -1. * time * TURN * 0.25 + 0.05 * dist;
  float distS = 2. * log2(max(
      abs(uv.x * cos(a) + uv.y * sin(a)),
      abs(uv.y * cos(a) - uv.x * sin(a))
  ));
  float aadistS = fwidth(distS) * 1.5;
  
  float raw1 = zig(
  0.4 * dist - 2. * time
  ) - 0.5;
  float aa1 = fwidth(raw1) * .75;
  float spiral1 = post(
  smoothstep(-aa1, aa1, raw1)
  , 2.);
  
  float raw2 = zig(
  0.25 * distS + 1. * time + 0.5
  ) - 0.5;
  float aa2 = fwidth(raw2) * .75;
  float spiral2 = post(
  smoothstep(-aa2, aa2, raw2)
  , 2.);
  
  vec3 col = mix(
      mix(
          HEX(0x009BE8), HEX(0xEB0072), spiral1
      ), mix(
          HEX(0x010a31), HEX(0xfff100), spiral1
      ), spiral2
  );
  // Output to screen
  glFragColor = vec4(
    col, 1.0
  );
}
