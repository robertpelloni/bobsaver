#version 420

// original https://www.shadertoy.com/view/7d2GDG

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float height(vec3 p) {
  return ((sin(p.z) + cos(p.x)) * 0.5) * 2.0;
}

vec3 height_normal(vec3 p) {
  vec2 t = vec2(-0.5 * sin(p.x), 0.5 * cos(p.z));
  return normalize(vec3(-t.x, sqrt(1.0 - t.x * t.x - t.y * t.y), -t.y));
}

vec3 pal(in float t, in vec3 a, in vec3 b, in vec3 c, in vec3 d) {
  return a + b * cos(6.28318 * (c * t + d));
}

vec3 sRGB(vec3 linear)
{
  vec3 a = 12.92 * linear;
  vec3 b = 1.055 * pow(linear, vec3(1.0 / 2.4)) - 0.055;
  vec3 c = step(vec3(0.0031308), linear);
  return mix(a, b, c);
}

#define saturate(x) clamp(x, 0.0, 1.0)

void main(void) {
  // camera movement    
  vec3 up = vec3(sin(sin(time)), cos(sin(time)), 0.0);
  vec3 ray_origin = vec3(sin(time) * 8.0, 0.0, -10.0 * time);
  vec3 target = vec3(0.0, 0.0, -10.0 * time + 1.0 * (cos(time)));
  
  // camera matrix
  vec3 cw = normalize(target - ray_origin);
  vec3 cu = normalize(cross(cw, up));
  vec3 cv = normalize(cross(cu, cw));
  
  vec2 uv = (2.0 * gl_FragCoord.xy - resolution.xy) / resolution.y;

  vec3 ray_dir = (uv.x * cu + uv.y * cv - 1.0 * cw); // normalize for non plane paralel rays
  
  vec3 ray_pos = ray_origin;
  
  float total_distance = 1.0;
  float previous_distance = total_distance;
  int object = 0;
  float previous_height;
  float step_height = 999999999.9999999;
  
  const float max_dist = 10000000.0;
  bool inside = false;
  bool previous_inside = false;
  float base_step_size = 0.025;
  
  for (int it = 0; it < 256; ++it) {
    inside = false;
    float step_size = base_step_size * total_distance;
    total_distance += step_size;
    
    ray_pos = ray_origin + total_distance * ray_dir;

    previous_height = step_height;
    step_height = height(ray_pos);
    
    float d = ray_pos.y - step_height + 4.0;
    
    if (abs(d) <= 0.001 * total_distance) {
      object = 1;
      break;
    }
    
    if (d < 0.0) {
      inside = true;
    }
    
    d = -ray_pos.y - step_height + 4.0;
    
    if (abs(d) <= 0.001 * total_distance) {
      object = 2;
      break;
    }

    if (d < 0.0) {
      inside = true;
    }

    if (inside) {
      base_step_size = -0.5 * abs(base_step_size);
    }
    else {
      if (previous_inside) {
        base_step_size = -0.5 * base_step_size;
      }
    }
    

    if (total_distance >= max_dist) {
      break;
    }

    previous_distance = total_distance;
    previous_inside = inside;
  }
  
  
  vec3 n = height_normal(ray_pos);
  
  
  vec3 fog = pal(time, vec3(0.5,0.5,0.5),vec3(0.5,0.5,0.5),vec3(1.0,1.0,0.5),vec3(0.8,0.90,0.30) );;
  
  if (object == 0) {
    glFragColor = vec4(sRGB(fog), 0.0);
    return;
  }
  
  float fog_factor = saturate(total_distance * total_distance / 5000.0);
  
  if (object == 1) {
    vec3 col = pal(step_height / 2.0 - time, vec3(0.5,0.5,0.5),vec3(0.5,0.5,0.5),vec3(2.0,1.0,0.0),vec3(0.5,0.20,0.25) );
    col = mix(saturate(-dot(n, ray_dir)) * col, fog, fog_factor);
    glFragColor = vec4(sRGB(col), 0.0);
    return;
  }
  
  if (object == 2) {
    n.y = -n.y;
    vec3 col = pal(step_height / 2.0 + time, vec3(0.5,0.5,0.5),vec3(0.5,0.5,0.5),vec3(1.0,0.7,0.4),vec3(0.0,0.15,0.20) );
    col = mix(saturate(-dot(n, ray_dir)) * col, fog, fog_factor);
    glFragColor = vec4(sRGB(col), 0.0);
    return;
  } 
}
