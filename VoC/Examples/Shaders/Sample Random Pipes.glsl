#version 420

// original https://www.shadertoy.com/view/tdVXzK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

precision highp float;

float rand(vec2 co){ return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453); }

vec2 repeat(vec2 uv, float tile_x, float tile_y, float xoff, float yoff) {
    return vec2 (mod(uv.x-xoff/tile_x, 1.0/tile_x) * tile_x,
                 mod(uv.y-yoff/tile_y, 1.0/tile_y) * tile_y);
}

float circle(vec2 uv, float radius) {
    vec2 coord = uv - vec2(0.5, 0.5);
    coord /= radius;
     float c=(coord.x*coord.x+coord.y*coord.y);
     c = pow(c,30.0);
     c = 1.0 - c;
    return c;
}

float line_horizontal(vec2 uv, float y, float thickness) {
    float ycoord = uv.y - y;
    return 1.0-pow(clamp(abs(ycoord)/thickness,0.0,1.0),50.0);
}

float line_vertical(vec2 uv, float x, float thickness) {
    float xcoord = uv.x - x;
    return 1.0-pow(clamp(abs(xcoord)/thickness,0.0,1.0),50.0);
}

vec2 pipe_id(vec2 uv, float tile_x, float tile_y, float xoff, float yoff) {
    vec2 uv_id = vec2(uv.x+xoff/tile_x, uv.y+yoff/tile_y);
    return floor(vec2(uv_id.x*tile_x, uv_id.y*tile_y));
}

float random_select(vec2 id) {
    return floor(rand(id)+0.5);
}

void main(void)
{
  float mx = max(resolution.x, resolution.y);
  vec2 center = vec2(resolution.x, resolution.y) / 2.0;
  vec2 uv_static = gl_FragCoord.xy / mx;
  vec2 uv_full = uv_static;
  //uv-= center / mx;

  uv_full.x += time/5.0;
  uv_full.y += time/5.0;
    
  const float tile_size = 10.0;
    
  vec2 uv = repeat(uv_full, tile_size, tile_size, 0.0, 0.0);
    
  float c = circle(uv, 0.33);
  
  float l1 = line_horizontal(uv,0.5, 0.15);
  float l2 = line_vertical(uv,0.5, 0.15);
    
  
  vec2 id1 = pipe_id(uv_full, tile_size, tile_size, 0.5, 0.0);
  vec2 id2 = pipe_id(uv_full, tile_size, tile_size, 0.0, 0.5);
    
  l1 *= random_select(id1*1.1);
  l2 *= random_select(id2);

  float col = c;
  col = max(col, l1);
  col = max(col, l2);

  glFragColor = vec4(col, min(col-c,col), 0.0, 1.0);
}
