#version 420

// original https://www.shadertoy.com/view/tsBXRh

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;
uniform sampler2D backbuffer;

out vec4 glFragColor;

// Bottomless depth
// Exploring procedural painting
// Licensed under hippie love conspiracy
// Leon Denise (ponk) 2019.03.17
// Using code from:
// Inigo Quilez (shadertoy.com/view/Xds3zN)
// Morgan McGuire (shadertoy.com/view/4dS3Wd)

const float zoomSpeed = 0.1;
const float noiseScale = 4.;
const float noiseSpeed = 0.01;

const float PI = 3.1415;
float hash(float n) { return fract(sin(n) * 1e4); }
float noise(vec3 x) {
    const vec3 step = vec3(110, 241, 171);
    vec3 i = floor(x);
    vec3 f = fract(x);
    float n = dot(i, step);
    vec3 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(mix( hash(n + dot(step, vec3(0, 0, 0))), hash(n + dot(step, vec3(1, 0, 0))), u.x),
                   mix( hash(n + dot(step, vec3(0, 1, 0))), hash(n + dot(step, vec3(1, 1, 0))), u.x), u.y),
               mix(mix( hash(n + dot(step, vec3(0, 0, 1))), hash(n + dot(step, vec3(1, 0, 1))), u.x),
                   mix( hash(n + dot(step, vec3(0, 1, 1))), hash(n + dot(step, vec3(1, 1, 1))), u.x), u.y), u.z);
}
float fbm (vec3 p) {
  float amplitude = .5;
  float result = 0.0;
  for (float index = 0.0; index <= 5.0; ++index) {
    result += noise(p / amplitude) * amplitude;
    amplitude /= 2.;
  }
  return result;
}
void main(void) {
  vec3 color = vec3(1);
  float timeline = time*zoomSpeed;
  vec2 unit = 1./resolution.xy;
  vec2 uv = gl_FragCoord.xy/resolution.xy;
  vec2 p = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
  float stage = floor(timeline);
  float ratio = fract(timeline);
  const float iterations = 3.;
  float spawn = 1.;
  float zoom = .5;
  float scale = noiseScale * resolution.y / 320.;
  for (float index = iterations; index > 0.; --index) {
    ratio = mod(ratio+1./iterations, 1.);
    vec3 s = vec3(p*scale*(zoom-ratio*zoom), 1. + timeline*noiseSpeed);
    float salty = fbm(s) * 2. - 1.;
    float angle = salty * PI * 8.;
    uv += vec2(cos(angle),sin(angle)) * unit * sin(ratio*PI);
    spawn *= 1. - abs(sin(angle)) * sin(ratio*PI);
  }
  color *= spawn;
  float blend = (.5+.5*(1.-spawn));
  glFragColor = texture2D(backbuffer, uv)*blend + (1.-blend)*vec4(color, 1);
}
