#version 420

// original https://www.shadertoy.com/view/slfGR4

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.1415926535897932384626

vec2 grid_random(vec2 p) {
  return fract(sin(vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)))) * 43758.5453);
}
  
void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    
    vec2 mn = resolution.xy / 40.0;

    vec4 _o = vec4(0.0, 0.0, 0.0, 1.0);

    float scale = 0.4;
    for(int l = 0; l < 8; l++){
      vec2 _uv = uv;
      float rad = time * scale * 0.1;
      _uv.x += cos(rad);
      _uv.y += sin(rad);
      _uv *= mn / scale;
      vec2 i = floor(_uv);
      vec2 f = fract(_uv);

      float m_dist = 1.0;
      vec2 m_point;
      for (float j = -1.0; j <= 1.0; j++) {
        for(float k = -1.0; k <= 1.0; k++) {
          vec2 neighbor = vec2(k, j);
          vec2 point = grid_random(i + neighbor);
          point = 0.5 + 0.5 * sin(time + point * PI * 2.0);
          float dist = distance(neighbor + point, f);
          if (dist < m_dist) {
            m_dist = dist;
            m_point = point;
          }
        }
      }
      m_dist = 1.0 - m_dist;
      float value = (smoothstep(0.65, 0.7, m_dist) - smoothstep(0.75, 0.8, m_dist)) * 0.3;
      value += smoothstep(0.85, 0.9, m_dist);
      _o.xyz = mix(_o.xyz, vec3(scale, scale, scale), value);
      scale *= 1.1;
    }

    // Output to screen
    glFragColor = _o;
}
