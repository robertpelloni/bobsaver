#version 420

// original https://www.shadertoy.com/view/4dccR4

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const vec3 red = vec3(10., 2.5, 0.);
const vec3 green = vec3(0., 10., 2.5);
const vec3 blue = vec3(2.5, 0., 10.);

void main(void) {
  vec2 st = gl_FragCoord.xy/resolution.xy;
  st.x *= resolution.x/resolution.y;
  vec3 color = vec3(0.0);
  vec3 color2 = vec3(0.0);
  vec3 color3 = vec3(0.0);
  vec3 color4 = vec3(0.0);
  vec3 color5 = vec3(0.0);
  vec3 color6 = vec3(0.0);

  float off = (resolution.x/resolution.y - 1.0)/2.;
  vec2 pos = vec2(0.5, 0.5)-vec2(st.x-off, st.y);

  float r = length(pos)*2.0;
  float a = atan(pos.y,pos.x) - time;
  float f = 0.5*sin(12.*a)*cos(30.*a) + 0.25*tan(3.*a - 1.5);

  float a2 = atan(pos.y,pos.x) - time*0.9;
  float f2 = 0.5*sin(12.*a2)*cos(30.*a2) + 0.25*tan(3.*a2 - 1.5);

  float a3 = atan(pos.y,pos.x) - time*0.8;
  float f3 = 0.5*sin(12.*a3)*cos(30.*a3) + 0.25*tan(3.*a3 - 1.5);

  float a4 = atan(pos.y,pos.x) - time*0.95;
  float f4 = 0.5*sin(12.*a4)*cos(30.*a4) + 0.25*tan(3.*a4 - 1.5);

  float a5 = atan(pos.y,pos.x) - time*0.85;
  float f5 = 0.5*sin(12.*a5)*cos(30.*a5) + 0.25*tan(3.*a5 - 1.5);

  float a6 = atan(pos.y,pos.x) - time*0.75;
  float f6 = 0.5*sin(12.*a6)*cos(30.*a6) + 0.25*tan(3.*a6 - 1.5);

  float func = 1.-smoothstep(f-1.,f+1.,r);
  float func2 = 1.-smoothstep(f2-1.,f2+1.,r);
  float func3 = 1.-smoothstep(f3-1.,f3+1.,r);
  float func4 = 1.-smoothstep(f4-1.,f4+1.,r);
  float func5 = 1.-smoothstep(f5-1.,f5+1.,r);
  float func6 = 1.-smoothstep(f6-1.,f6+1.,r);

  color = mix(vec3(0.), red, func);
  color2 = mix(vec3(0.), green, func2);
  color3 = mix(vec3(0.), blue, func3);
  color4 = mix(vec3(0.), red, func4);
  color5 = mix(vec3(0.), green, func5);
  color6 = mix(vec3(0.), blue, func6);

  float mixAmt = pow(distance(vec2(0.5), st), .707);

  color = mix(color, color2, mixAmt);
  color = mix(color, color3, mixAmt);
  color = mix(color, color4, mixAmt);
  color = mix(color, color5, mixAmt);
  color = mix(color, color6, mixAmt);

  color = mix(vec3(.1, 0., .2), color, smoothstep(0., 1.4142, 1.-length(pos)*2.));

  glFragColor = vec4(color, 1.0);
}
