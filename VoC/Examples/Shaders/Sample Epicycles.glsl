#version 420

// epicycles... co3moz

uniform float time;
uniform vec2 resolution;
uniform sampler2D backbuffer;

out vec4 glFragColor;
vec2 p, a, c, z;
vec3 col;
void epicycle(float, float, float);
float pixel;

#define STRIPES 
#define LINES
#define RED_BODY_DOTS

void main() {
  a = resolution.xy / min(resolution.x, resolution.y);
  p = (gl_FragCoord.xy / resolution.xy) * a;
  c = a * 0.5;
  z = vec2(0.0);
  col = vec3(0.0);
  pixel = 1.5 / min(resolution.x, resolution.y);
    
    
  epicycle(0.0, 0.0, 0.0); // origin
  epicycle(1.0, 1.0, 0.0); // first long leg
    
  // other shit
  for (float i = 1.0; i<30.0;i++) {
    epicycle(0.4 / i, mod(i, 2.0) == 0.0 ? 1.0 : -2.0 * log(i+1.0), i * 0.3);
    #ifdef STRIPES
    col += distance(p, c + z * 0.2) > pixel ? vec3(0.0, 0.0, 0.0) : vec3(0.0, 1.0, 0.0); // green dot
    #endif
  }

  #ifndef STRIPES
  col += distance(p, c + z * 0.2) > 0.005 ? vec3(0.0, 0.0, 0.0) : vec3(0.0, 1.0, 0.0); // last green dot  
  #endif
  col += vec3(0.0, texture2D(backbuffer, p / a).y, 0.0); // green backbuffer
  col *= 0.99899; // fading effect
  glFragColor = vec4(col - 0.0019, 1.0);
}

float drawLine(vec2 p1, vec2 p2) { // took it from stackoverflow, lazy..
  float a = abs(distance(p1, p));
  float b = abs(distance(p2, p));
  float c = abs(distance(p1, p2));
  if (a >= c || b >= c) return 0.0;
  float e = (a + b + c) * 0.5;
  float h = 2. / c * sqrt( e * ( e - a) * ( e - b) * ( e - c));
  return mix(1.0, 0.0, smoothstep(0.0015, 0.0045, h));
}

void epicycle(float power, float speed, float phase) {
  vec2 pre = z; // save current position
  z += vec2(sin(time * speed + phase) * power, cos(time * speed + phase) * power); // calculate next position
  #ifdef RED_BODY_DOTS
  col += distance(p, c + z * 0.2) > 0.005 ? vec3(0.0, 0.0, 0.0) : vec3(1.0, 0.0, 0.0); // draw red dots
  #endif
  #ifdef LINES
  col += vec3(0.0, 0.0, drawLine(pre * 0.2 + c, z * 0.2 + c)); // draw lines
  #endif
}

