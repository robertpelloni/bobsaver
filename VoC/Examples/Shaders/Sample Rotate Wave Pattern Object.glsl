#version 420

// original https://neort.io/art/boaccpc3p9fd1q8oba7g

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

float plot(vec2 p, float v){
  return  smoothstep( v - 2.0, v, p.y) - smoothstep( v, v + 2.0, p.y);
}

void main() {
  vec2 st = (gl_FragCoord.xy * 2.0 - resolution) / min(resolution.x, resolution.y);
  vec3 color = vec3(1.0);
  st *= 10.0;
  vec2 rst = mod(st * 2.0, 1.0);
  rst -= 0.5;
  vec2 id = rst - st;

  float lng = length(st) + 2.0;
  float at = atan(st.y, st.x);
  st = vec2(cos(at) * lng, sin(at) * lng) * rotate(time * 0.2);
  vec2 st2 = st * (dot(lng, lng) * 0.01 + 1.0) * rotate(time * 0.4);
  st *= dot(lng, lng) * 0.01 - 1.0;

  color *= vec3(plot(st,sin(st.x + time)));
  color += vec3(plot(st,cos(st2.x + time)));
  color *= vec3(cos(time + id.x * 10.0),0.2,0.5);
  color += vec3(sin(id.x * 50.0)) * 0.2;

  glFragColor = vec4(color, 1.0);
}
