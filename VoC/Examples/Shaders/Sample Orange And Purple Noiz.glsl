#version 420

// original https://neort.io/art/bn298a43p9f80jer84q0

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;
uniform sampler2D backbuffer;

out vec4 glFragColor;

mat2 rotate(float r) {
    float c = cos(r);
    float s = sin(r);
    return mat2( c, -s, s, c);
}

highp float rand(vec2 co){
    highp float a = 12.9898;
    highp float b = 78.233;
    highp float c = 43758.5453;
    highp float dt= dot(co.xy ,vec2(a,b));
    highp float sn= mod(dt,3.14);
    return fract(sin(sn) * c);
}

void main() {
  vec2 st = (gl_FragCoord.xy * 2.0 - resolution) / min(resolution.x, resolution.y);

  // bump
  float lng = length(st);
  float at = atan(st.y, st.x) * 1.0 + lng;
  st = vec2(cos(at) * lng, sin(at) * lng) * rotate(time * 0.1);
  st *= 2.0 + dot(lng, lng) * 0.5;

  vec3 color = vec3(sin(length(st) * st.x + time),
    sin(length(st) * st.x + time),
    sin(length(st) * st.x + time));
  color = mix(color,
    vec3(1.0 - sin(length(st) * st.y + time),
    sin(length(st) * st.y + time + 3.0),
    sin(length(st) * st.y + time * rand(st))),0.5);

  glFragColor = vec4(color, 1.0);

}
