#version 420

// original https://www.shadertoy.com/view/NdjGRc

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float sd_box(vec3 p, vec3 b) {
  vec3 q = abs(p) - b;
  return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);
}

float sd_sphere(vec3 p, float r) {
  return length(p) - r;
}

float opSmoothUnion( float d1, float d2, float k ) {
    float h = clamp( 0.5 + 0.5*(d2-d1)/k, 0.0, 1.0 );
    return mix( d2, d1, h ) - k*h*(1.0-h); }

float opSmoothSubtraction( float d1, float d2, float k ) {
    float h = clamp( 0.5 - 0.5*(d2+d1)/k, 0.0, 1.0 );
    return mix( d2, -d1, h ) + k*h*(1.0-h); }

float scene(vec3 ray_pos, vec3 ray_origin) {
    float a = 0.5 * ray_pos.z + 2.0 * time;
    
    vec3 r0;
    r0.xy = vec2(ray_pos.x * cos(a) - ray_pos.y * sin(a),
                      ray_pos.x * sin(a) + ray_pos.y * cos(a));
    r0.z = ray_pos.z;

    
    
    float d0 = sd_sphere(fract((r0) / 2.5) * 2.5 - 1.25, 0.5);
    
    
    a = -0.5 * ray_pos.z - 4.0 * time;
    
    ray_pos.xy = vec2(ray_pos.x * cos(a) - ray_pos.y * sin(a),
                      ray_pos.x * sin(a) + ray_pos.y * cos(a));

    float d1 = sd_box(fract((ray_pos) / 5.0) * 5.0 - 2.5, vec3(1.0, 1.0, 10.0));
    
    return opSmoothUnion(d0, d1, 0.25);
}

vec3 scene_normal(vec3 p, vec3 ray_origin) {
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

vec3 sRGB(vec3 linear)
{
  vec3 a = 12.92 * linear;
  vec3 b = 1.055 * pow(linear, vec3(1.0 / 2.4)) - 0.055;
  vec3 c = step(vec3(0.0031308), linear);
  return mix(a, b, c);
}

void main(void) {
  vec3 ray_dir = vec3(gl_FragCoord.xy / resolution.xy * 2.0 - 1.0, -1.0 / 4.0);
  ray_dir.x *= resolution.x / resolution.y;
  ray_dir = normalize(ray_dir);

  vec3 ray_origin = vec3(0.0, 0.0, -10.0 * time + sin(time));
  vec3 ray_pos = ray_origin;
  
  int max_iterations = 128;
  float total_distance = 0.0;

  for (int max_iterations = 0; max_iterations < 64; ++max_iterations) {
    float dist = scene(ray_pos, ray_origin);
    total_distance += dist;

    ray_pos = ray_origin + total_distance * ray_dir;

    if (dist < 0.0001) {
      break;
    }
  }

  vec3 n = scene_normal(ray_pos, ray_origin);
  
  vec3 col = pal(total_distance * .25 + time, vec3(0.5,0.5,0.5),vec3(0.5,0.5,0.5),vec3(1.0,1.0,0.5),vec3(0.8,0.90,0.30) );
  
  col = 2.0 * col * -dot(n, ray_dir);
  col *= clamp(1.0 / (total_distance - 1.0), 0.0, 1.0);
  
  glFragColor = vec4(sRGB(col), 0.0);
}
