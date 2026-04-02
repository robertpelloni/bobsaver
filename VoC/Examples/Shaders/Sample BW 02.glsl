#version 420

// original https://neort.io/art/bp6l0ac3p9f2ibmm1ct0

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float random(float x){
  return fract(sin(x * 12.9898) * 43758.5453);
}

void main(void) {
  vec2 st = (2.0 * gl_FragCoord.xy - resolution) / min(resolution.x, resolution.y);

  st.x *= 15.0;
  float xi = floor(st.x);

  float xl = xi - 1.0 + random(xi - 1.0);
  float xc = xi + random(xi);
  float xr = xi + 1.0 + random(xi + 1.0);

  float mxl = 0.5 * (xc + xl);
  float mxr = 0.5 * (xc + xr);
  float dxl = abs(mxl - st.x);
  float dxr = abs(mxr - st.x);
  float dx = min(dxl, dxr);

  float xs = xi + (st.x < mxl ? -1.0 : st.x < mxr ? 0.0 : 1.0);

  st.y *= 15.0;
  st.y += 20.0 * random(xs) * time;
  float yi = floor(st.y);

  float yl = yi - 1.0 + random(xs + yi - 1.0);
  float yc = yi + random(xs + yi);
  float yr = yi + 1.0 + random(xs + yi + 1.0);

  float dyl = abs(0.5 * (yc + yl) - st.y);
  float dyr = abs(0.5 * (yc + yr) - st.y);
  float dy = min(dyl, dyr);

  float tx = smoothstep(0.0, 0.05, dx);
  float ty = smoothstep(0.0, 0.05, dy);
  vec3 c = vec3(1.0 - tx * ty);

  glFragColor = vec4(c, 1.0);
}
