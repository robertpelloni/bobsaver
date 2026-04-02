#version 420

// original https://www.shadertoy.com/view/ldSfW3

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14159265359
#define NUM_PI_DIVS 8.0

#define PI_DIV PI/NUM_PI_DIVS
#define HALF_PI_DIV PI_DIV*0.5
#define THIRD_PI_DIV PI_DIV/3.0

#define SMOOTH_HALF_INTERVAL HALF_PI_DIV*0.5

#define SIN_AMP_MAX HALF_PI_DIV*3.0
#define SIN_AMP_TIME_AMP 3.0
#define SIN_FREQ_MAX 10.0
#define SIN_FREQ_TIME_AMP 0.5

#define SIN_TIME_AMP 10.0
#define MOD_TIME_AMP 1.5

float posSin(float x) {
  return (sin(x)/2.0 + 0.5);
}

float plot(float pct, vec2 st){
  return smoothstep(pct - SMOOTH_HALF_INTERVAL, pct, st.y)
      - smoothstep(pct, pct + SMOOTH_HALF_INTERVAL, st.y);
}

float computeAmp(float time_factor) {
  return SIN_AMP_MAX*(sin(time*time_factor*SIN_AMP_TIME_AMP)/2.0 + 0.5);
}

void main(void) {
  vec2 st = vec2(gl_FragCoord.x /resolution.x, gl_FragCoord.y/resolution.y);
  st = (st - 0.5) * 2.0;
  st.x *= resolution.x/resolution.y;

  // Determine the polar coordinate
  float oTheta = atan(st.y, st.x);
  float r = length(st);

  float theta = mod(oTheta + time*MOD_TIME_AMP, PI_DIV) - HALF_PI_DIV;
  float theta2 = mod(oTheta - THIRD_PI_DIV + time*MOD_TIME_AMP*2.0/3.0, PI_DIV) - HALF_PI_DIV;
  float theta3 = mod(oTheta - 2.0*THIRD_PI_DIV + time*MOD_TIME_AMP/3.0, PI_DIV) - HALF_PI_DIV;

  float freq = SIN_FREQ_MAX*posSin(time*SIN_FREQ_TIME_AMP);

  float ampR = computeAmp(1.0/3.0);
  float ampG = computeAmp(2.0/3.0);
  float ampB = computeAmp(1.0);

  float polarPct = plot(ampR*sin(r*freq - time*SIN_TIME_AMP), vec2(theta));
  float polarPct2 = plot(ampG*sin(r*freq - time*SIN_TIME_AMP/3.0), vec2(theta2));
  float polarPct3 = plot(ampB*sin(r*freq - time*SIN_TIME_AMP*2.0/3.0), vec2(theta3));

  vec3 color = vec3(polarPct, polarPct2, polarPct3);
  // vec3 color = vec3(polarPct*posSin(u_time*2.0/3.0), polarPct2*posSin(u_time), polarPct3*posSin(u_time/3.0));

  glFragColor = vec4(color, 1.0);
}
