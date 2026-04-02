#version 420

// original https://www.shadertoy.com/view/7dfGWs

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{

  float aspectRatio = resolution.x / resolution.y;

  vec2 uv = -1.0 + 2.0 * gl_FragCoord.xy / resolution.xy;
      uv.x *= aspectRatio;

  float speed = time * 4.0 + 4000.0;

  vec3 color = vec3(0.0);

  for (float i = 0.0; i < 320.0; i += 1.0) {
    float phase = sin(i * 1546.13 + 1.0) / 20.0 + 0.5;
    float size = pow(sin(i * 651.74) * 0.6 + 0.1, 4.0);

    float phase_times_speed = phase * speed;

    vec2 pos = vec2(
        i / 80.0 - 1.8,
        (( sin( phase_times_speed / (((i + 50.0) / 5.0) - 1.0) ) * cos(phase * 10.0) / 3.0 ) - ( sin( i / 26.0 + 1.0 ) * 0.1 )) * 0.5
    );

    float radius = 0.1 + 0.5 * size + sin(phase + size) / 40.0;
    float distance_from_origin = length(uv - pos) * 10.0;
    if (distance_from_origin < radius) {
      vec3 color_out = mix(
          vec3(0.615, 0.73, 0.8) * sin(phase_times_speed / 2.0) * 2.0,
          vec3(0.1, 0.3 * phase, 0.4 * sin(phase)),
          0.5 + sin(i) * 0.1
      );
      color += color_out.zyx * (1.0 - smoothstep(radius / 2.0, radius, distance_from_origin));
    }
  }
  color *= sqrt(1.5 - length(uv) * 0.1);
  glFragColor = vec4(color.r, color.g, color.b, 0.5);
}
