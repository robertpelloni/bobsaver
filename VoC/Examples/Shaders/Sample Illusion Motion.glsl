#version 420

// original https://www.shadertoy.com/view/3tSBzG

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float pi = 3.1416;
const int stops = 11;
const vec3[] colors = vec3[](
    vec3(0.0, 0.0, 0.0), 
    vec3(0.890, 0.745, 0.160), 
    vec3(0.890, 0.745, 0.160),
    vec3(0.992, 0.882, 0.309), 
    vec3(0.992, 0.882, 0.309),
    vec3(1.0, 1.0, 1.0),
    vec3(0.564, 0.196, 0.764), 
    vec3(0.564, 0.196, 0.764), 
    vec3(0.462, 0, 0.701),
    vec3(0.462, 0, 0.701), 
    vec3(0.0, 0.0, 0.0));
const int fans = 25;
const float spiral = 0.0;
const bool gradient = false;
const bool animate = false;

vec3 toSRGB(in vec3 color) { return pow(color, vec3(1.0 / 2.2)); }

vec3 toLinear(in vec3 color) { return pow(color, vec3(2.2)); }

float wave(in float x) {
  return sign(sin(x)) * (pow(abs(sin(x)), 0.6) - 0.1) * 0.007;
}

vec3 getColor(in float t, in bool gradient) {
  if (gradient) {
    t *= float(stops - 1);
    int stop = int(floor(t));
    return mix(toLinear(colors[stop]), toLinear(colors[stop + 1]),
               t - float(stop));
  } else {
    t *= float(stops - 1);
    int stop = int(floor(t + 0.5));
    return toLinear(colors[stop]);
  }
}

float sdBox(in vec2 position, in vec2 box) {
  vec2 d = abs(position) - box;
  return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
}

vec2 rotate(in vec2 vector, in float angle) {
  return vector * mat2(cos(angle), -sin(angle), sin(angle), cos(angle));
}

vec4 takeSample() {
  vec2 center = resolution.xy / 2.0;
  vec2 toPoint = gl_FragCoord.xy - center;

  float radius = pow(length(toPoint) / resolution.y, 0.2) * 250.0 -
                 (animate ? time : 0.0);
  float angle = (atan(toPoint.y, toPoint.x) + pi) / (pi * 2.0) -
                (animate ? time * 0.001 : 0.0);
  float fans = float(fans);
  angle = mod(angle + wave(radius) + radius * spiral, 1.0 / fans) * fans;

  //gl_FragCoord.xy -= center;
  float sd0 = sdBox(rotate(gl_FragCoord.xy-center, pi / 4.0), vec2(resolution.y / 3.1));
  float sd1 = sdBox(rotate(gl_FragCoord.xy-center, pi / 2.65), vec2(resolution.y / 1.8));
  bool invert = sd0 > 0.0 && sd1 < 0.0;
  if (invert) {
    angle = 1.0 - angle;
  }

  float shadow = sd1 > 0.0
                     ? 1.0
                     : 0.1 + min((sd0 > 0.0 ? max(-sd1, 0.0) : max(-sd0, 0.0)) /
                                     (resolution.y / 15.0), 0.9);

  return vec4(getColor(angle, gradient) * shadow, 1.0);
}

#define SAMPLE(p) takeSample(p)
vec4 superSample(in int samples) {
  if (samples == 1) {
    return SAMPLE();
  }  
  
  float divided = 1.0 / float(samples);

  vec4 outColor = vec4(0.0);
  for (int x = 0; x < samples; x++) {
    for (int y = 0; y < samples; y++) {
      vec2 offset = vec2((float(x) + 0.5) * divided - 0.5,
                         (float(y) + 0.5) * divided - 0.5);
      vec2 samplePosition = gl_FragCoord.xy + offset;
      outColor += SAMPLE();
    }
  }

  return outColor / float(samples * samples);
}

void main(void) {
  glFragColor = superSample( 4);
  glFragColor = vec4(toSRGB(glFragColor.rgb), 1.0);
}
