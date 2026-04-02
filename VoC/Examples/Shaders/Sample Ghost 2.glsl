#version 420

// original https://www.shadertoy.com/view/tstSDn

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define TAU 6.283
// https://www.iquilezles.org/www/articles/distfunctions2d/distfunctions2d.htm

float sdUnevenCapsule(vec2 p, float r1, float r2, float h) {
  p.x = abs(p.x);
  float b = (r1 - r2) / h;
  float a = sqrt(1.0 - b * b);
  float k = dot(p, vec2(-b, a));
  if (k < 0.0)
    return length(p) - r1;
  if (k > a * h)
    return length(p - vec2(0.0, h)) - r2;
  return dot(p, vec2(a, b)) - r1;
}

float sdLine(in vec2 p, in vec2 a, in vec2 b) {
  vec2 pa = p - a, ba = b - a;
  float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
  return length(pa - ba * h);
}

float sdArc( in vec2 p, in vec2 sca, in vec2 scb, in float ra, float rb )
{
    p *= mat2(sca.x,sca.y,-sca.y,sca.x);
    p.x = abs(p.x);
    float k = (scb.y*p.x>scb.x*p.y) ? dot(p.xy,scb) : length(p.xy);
    return sqrt( dot(p,p) + ra*ra - 2.0*ra*k ) - rb;
}

float wiggles(vec2 p, float h, float freq, float amp, float speed) {
  return p.y - (h + sin((time * speed + p.x) * freq) * amp);
}

float arms(vec2 p, float h, float l, float freq, float amp) {  
  return sdLine(p + vec2(0., h) + vec2(0., sin(p.x * freq) * amp), vec2(-l, 0.), vec2(l, 0.)) - .1;
}

float map(vec2 uv) {
  uv.x += sin((uv.y + time) * 4.) * .05;
  uv.y += sin(time) * .2+.15;
    
  float dist = 100.;

  float body = sdUnevenCapsule(uv + vec2(0., .2), .5, .4, .5);
  dist = max(-dist, body);

  float wigg = wiggles(uv, -.3, 8., .1, .5);
  dist = max(-wigg, dist);

  float arms = arms(uv, -.1, .7, 8., .1 * sin(time));
  dist = min(arms, dist);
    
  float eyel = length(uv - vec2(-.18,.4 + sin(time) * .02)) - .1;
  dist = max(-eyel, dist);
    
  float eyer = length(uv - vec2(.2,.3 + sin(time * 1.2) * .03)) - .1;
  dist = max(-eyer, dist);
    
  float mouthwiggle = .76 + sin(time*3.) * .01;
    float mouthwid = .1 + sin(time*2.) * .01;
  float mouth = sdArc(uv + vec2(.04,-0.35), vec2(sin(TAU*mouthwiggle), cos(TAU*mouthwiggle)), vec2(sin(TAU* mouthwid), cos(TAU* mouthwid)), .15, .02);
    dist = max(-mouth, dist);

  return dist;
}

void main(void) {
  // Normalized pixel coordinates (from 0 to 1)
  vec2 uv = (2. * gl_FragCoord.xy - resolution.xy) / resolution.y;
    
  float ghost = map(uv);

  //vec3 col = vec3(step(0.,ghost));
  vec3 col = pow(abs(vec3(ghost)), vec3(.2));

  // Output to screen
  glFragColor = vec4(col, 1.0);
}
