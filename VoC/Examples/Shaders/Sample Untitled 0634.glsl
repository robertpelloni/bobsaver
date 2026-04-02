#version 420

// original https://www.shadertoy.com/view/fsSGzK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float sd_box(vec3 p, vec3 b) {
  vec3 q = abs(p) - b;
  return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);
}

float scene(vec3 ray_pos, vec3 ray_origin) {
    float d = distance(ray_pos, ray_origin);

    ray_pos.x = mix(ray_pos.x, (ray_pos.x - ray_origin.x) * cos(time) + (ray_pos.y - ray_origin.y) * sin(time), clamp(d / 50.0, 0.0, 1.0));
    ray_pos.y = mix(ray_pos.y, (ray_pos.x - ray_origin.x) * sin(time) + (ray_pos.y - ray_origin.y) * cos(time), clamp(d / 50.0, 0.0, 1.0));
    
    return min(
             min(
               sd_box(fract((ray_pos + 2.5) / 5.0) * 5.0 - 2.5, vec3(1.0, 1.0, 1.0)),
               sd_box(fract((ray_pos + 2.5) / 5.0) * 5.0 - 2.5, vec3(0.25, 0.25, 4.0))),
             min(
               sd_box(fract((ray_pos + 2.5) / 5.0) * 5.0 - 2.5, vec3(0.25, 4.0, 0.25)),
               sd_box(fract((ray_pos + 2.5) / 5.0) * 5.0 - 2.5, vec3(4.0, 0.25, 0.25))));
}

vec3 scene_normal(vec3 p, vec3 ray_origin)
{
  const float h = 0.01;
  const vec2 k = vec2(1.0, -1.0);
  return normalize(k.xyy * scene(p + k.xyy * h, ray_origin) + 
                   k.yyx * scene(p + k.yyx * h, ray_origin) + 
                   k.yxy * scene(p + k.yxy * h, ray_origin) + 
                   k.xxx * scene(p + k.xxx * h, ray_origin));
}

vec3 pal(in float t, in vec3 a, in vec3 b, in vec3 c, in vec3 d) {
  return a + b * cos(6.28318 * (c * t + d));
}

void main(void) {
  vec3 ray_dir = vec3(gl_FragCoord.xy / resolution.xy * 2.0 - 1.0, -0.25);
  ray_dir.x *= resolution.x / resolution.y;
  ray_dir = normalize(ray_dir);

  vec3 ray_pos = vec3(cos(time) * 5.0 - 2.5, 2.5, 10.0 - 10.0 * time);
  vec3 ray_origin = ray_pos;
  int max_iterations = 64;
  float d = 99999999.999999999999;

  for (int max_iterations = 0; max_iterations < 64; ++max_iterations) {
    d = scene(ray_pos, ray_origin);
    
    if (d < 0.0001) {
      break;
    }

    ray_pos += d * ray_dir;
  }

  // Output to screen
  vec3 n = scene_normal(ray_pos, ray_origin);
  float dist = clamp(abs(5.0 / distance(ray_pos, ray_origin)), 0.0, 1.0);
  vec3 col = pal(dist - time, vec3(0.8,0.5,0.4),vec3(0.2,0.4,0.2),vec3(2.0,1.0,1.0),vec3(0.0,0.25,0.25) );
  
  glFragColor = vec4(mix(vec3(col * -dot(n, ray_dir)), vec3(0.0), 1.0 - dist), 0.0);
}
