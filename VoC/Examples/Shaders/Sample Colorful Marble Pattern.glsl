#version 420

// original https://neort.io/art/bn4tgik3p9f80jer8fvg

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

void main() {
  vec2 st = (gl_FragCoord.xy * 2.0 - resolution) / min(resolution.x, resolution.y);
  vec2 st2 = st;
  st *= rotate(time * 0.1);
  // bump
  float lng = length(st);
  float at = atan(st.y, st.x) + lng;
  st = vec2(cos(at) * lng, sin(at) * lng) * rotate(-time * 0.2);
  st *= 10.0 + dot(lng, lng) * 0.5;
  st2 *= 5.0 + dot(lng, lng) * 0.5;

  vec2 id = st * 0.1 + sin(st.x + time);

  float t = time * 5.0;
  vec3 color = vec3(
    sin(length(id) * st.x + t + 0.5),
    sin(length(id) * st.x + time),
    sin(length(id) * st.x + t - 0.5));
  color *=
    vec3(
      sin(length(id) * st.y + time)
    );
  color += vec3(0.2,0.1,1.0) * 0.5;
  color += vec3(sin(length(id) * st2.x + time),0.0,0.0);

  glFragColor = vec4(color * 0.5, 1.0);

}
