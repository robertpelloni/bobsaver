#version 420

// original https://www.shadertoy.com/view/fljGDK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const vec2 LEFT = vec2(.32, .6);
const vec2 RIGHT = vec2(1.0 - LEFT.x, LEFT.y);
const float RADIUS = .15;

const float ZOOM_INCREMENT = 0.725;
const float ZOOM_TIME = 8.86;  // number of seconds to increment one zoom level, about.

float zoom_of_depth(float depth) {
  return tanh(depth * ZOOM_TIME);
  float z = ZOOM_INCREMENT;
  while (depth-- > 0.0) z += ZOOM_INCREMENT * (1.0 - z);
  return z;
}

vec2 rotate2(vec2 v, float r) {
  v = mat2(cos(r), -sin(r), sin(r), cos(r)) * (v - .5);
  v += .5;
  return v;
}

vec4 rotate4_around_z(vec4 v, float r) {
  v = mat4(-cos(r), sin(r), cos(r),  0.0,
           sin(r),  cos(r), -sin(r), 0.0,
           -sin(r), -sin(r), -cos(r),  0.0,
           0.0,     0.0,    0.0,     1.0) * (v - .5);
  v += .5;
  return v;
}

vec2 left(vec2 v, float zoom_factor, float depth) {
  return (v - (LEFT - RADIUS)) * (1.0 / (RADIUS * 2.0));
  float z_level = zoom_of_depth(depth+1.0);
  float r = atanh(z_level - zoom_factor) * (depth + 1.0);
  return rotate2(v, r);
}

vec2 right(vec2 v, float zoom_factor, float depth) {
  return (v - (RIGHT - RADIUS)) / (RADIUS * 2.0);
  float z_level = zoom_of_depth(depth+1.0);
  float r = atanh(z_level - zoom_factor) * (depth + 1.0);
  return rotate2(v, -r);
}

vec2 deeper(vec2 uv, vec2 new_center) {
  return (uv - (new_center - RADIUS)) / (RADIUS * 2.0);
}

float sdf_circle(vec2 uv, vec2 position, float radius){
    float d = length(uv - position);
    float c = smoothstep(radius, radius-0.005, d); 
    return c;
}

float sdf_smile(vec2 uv, vec2 position, float offset, float radius, float radius_off) {
    return clamp(
    sdf_circle(uv, position, radius) - 
    sdf_circle(uv, vec2(position.x, position.y + offset), radius + radius_off),
    0.0, 1.0);
}

float sdf_rim(vec2 uv, vec2 position, float radius_offset, float radius) {
    return clamp(
        sdf_circle(uv, position, radius) -
        sdf_circle(uv, position, radius - radius_offset),
        0.0, 1.0);
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    float aspect = resolution.x / resolution.y;
    uv.x *= aspect;
    uv.x -= .45;
    
    float t = time - 10.0;
    
    vec2 zoom_point = vec2(.3842109, .642857);
    float zoom_factor = tanh(min(time - 10.0, 60.0) / 10.0);
    
    //if (zoom_factor > zoom_of_depth(2.0)) {
    //glFragColor = vec4(1,0,0,1);
    //return;
    //}
    
    vec2 off = zoom_point - uv;
    uv += off * zoom_factor;
    
    float depth = 0.0;
    for (; depth < 100.0; ++depth) {
      if (distance(LEFT, uv) < RADIUS) {
        uv = left(uv, zoom_factor, depth);
      } else if (distance(RIGHT, uv) < RADIUS) {
        uv = right(uv, zoom_factor, depth);
      } else {
        break;
      }
    }
    
    float smile = sdf_smile(uv, vec2(.5, .4), .08, .3, .025);
    float rim = sdf_rim(uv, vec2(.5, .5), .06, .51);
    float outline = smile + rim;
    
    float inside = sdf_circle(uv, vec2(.5, .5), .45);
    
    depth -= zoom_factor;
    vec4 depth_color = rotate4_around_z(
        normalize(vec4(.75, .3, .4, 1.0)),
        2.0 * (depth - sin(time / 2.f)));
    
    float intensity = dot(vec2(1.0 - uv.x, uv.y), vec2(0.9, 1.0));
    vec4 in_circle_color = depth_color * intensity / (depth + 1.0);
    
    glFragColor = outline * vec4(1, 1, 1, 0) + inside * in_circle_color;
}
