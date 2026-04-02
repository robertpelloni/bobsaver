#version 420

// original https://www.shadertoy.com/view/ts3GWB

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

precision lowp float;
precision lowp int;

const float space = 15.0;
const float width = 4.0;
const float speed = 20.0;

float modF(float a,float b) {
  float m = a - floor((a + 0.5) / b) * b;
  return m + 0.5;
}

vec3 hueShift( vec3 color, float hueAdjust ){
    const vec3  kRGBToYPrime = vec3 (0.299, 0.587, 0.114);
    const vec3  kRGBToI      = vec3 (0.596, -0.275, -0.321);
    const vec3  kRGBToQ      = vec3 (0.212, -0.523, 0.311);

    const vec3  kYIQToR     = vec3 (1.0, 0.956, 0.621);
    const vec3  kYIQToG     = vec3 (1.0, -0.272, -0.647);
    const vec3  kYIQToB     = vec3 (1.0, -1.107, 1.704);

    float   YPrime  = dot (color, kRGBToYPrime);
    float   I       = dot (color, kRGBToI);
    float   Q       = dot (color, kRGBToQ);
    float   hue     = atan (Q, I);
    float   chroma  = sqrt (I * I + Q * Q);

    hue += hueAdjust;

    Q = chroma * sin (hue);
    I = chroma * cos (hue);

    vec3    yIQ   = vec3 (YPrime, I, Q);

    return vec3( dot (yIQ, kYIQToR), dot (yIQ, kYIQToG), dot (yIQ, kYIQToB) );
}

void main(void) {
  vec2 center = resolution.xy / 2.0;

  float dist = min(
    distance(gl_FragCoord.xy, vec2(0, resolution.y)),
    min(
      distance(gl_FragCoord.xy, resolution.xy),
      min(
        distance(gl_FragCoord.xy, center),
        min(
          distance(gl_FragCoord.xy, vec2(0, 0)),
          distance(gl_FragCoord.xy, vec2(resolution.x, 0))
        )
      )
    )
  );
    
  vec3 col1 = hueShift(vec3(1, 0, 0), time);
  vec3 col2 = hueShift(col1, dist / 40.0);
  float a = modF(time * speed - dist, space + width);
  glFragColor = vec4(a < width ? col2 : vec3(0, 0, 0), 1);
}
