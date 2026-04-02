#version 420

// original https://neort.io/art/bnfg4ks3p9f5erb52mqg

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;
uniform sampler2D backbuffer;

out vec4 glFragColor;

#define PI 3.14159265359
#define TWO_PI 6.28318530718

vec2 random( vec2 p ) {
    return fract(sin(vec2(dot(p,vec2(127.1,311.7)),dot(p,vec2(269.5,183.3))))*43758.5453);
}

float shape(vec2 p,float radius){

    float at = atan(p.x,p.y) + time * 0.5 + PI;
    float ar = TWO_PI/12.0;
    float d = cos(floor(0.5 + at/ar) * ar - at) * length(p);

    float r = length(p) * radius * 10.0;
    float a = atan(length(p)) - time;
    return abs(tan(r + a - d));
}

void main() {
  vec2 st = (gl_FragCoord.xy * 2.0 - resolution) / min(resolution.x, resolution.y);

  st *= 20.0;
  // Tile the space
  vec2 i_st = floor(st);
  vec2 f_st = fract(st);

  float m_dist = 0.5;  // minimun distance
  for (int y= -1; y <= 1; y++) {
     for (int x= -1; x <= 1; x++) {
         // Neighbor place in the grid
         vec2 neighbor = vec2(float(x),float(y));
         // Random position from current + neighbor place in the grid
         vec2 point = random(i_st + neighbor);
         // Animate the point
         point = 0.5 + 0.5 * sin(time * point);
         // Vector between the pixel and the point
         vec2 diff = neighbor + point - f_st;
         // Distance to the point
         float dist = length(diff);
         // Keep the closer distance
         m_dist = min(m_dist, dist);
     }
   }

  vec3 color = vec3(shape(st, 0.1),shape(st, 0.14),shape(st, 0.16));
  color *= length(0.5 - m_dist);

  glFragColor = vec4(color, 1.0);

}
