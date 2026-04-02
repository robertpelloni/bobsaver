#version 420

// original https://www.shadertoy.com/view/3sdXDS

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define time time
#define SPEED 20.

float PI = acos(-1.);

vec3 palette(float x) {
  float wave = sin(3. * time) * 0.5 + 0.5;
  vec3 p = vec3(1, 1, 1);
  vec3 q = vec3(.3, .6, 1);
  vec3 r = vec3(.3, .6, .3);
  vec3 s = vec3(.9, .5, .3);
  
  return p + q * sin(2. * PI * (x * r + s));
}

mat2 rot2d(float a) {
  float c = cos(a), s = sin(a);

  return mat2(c, s, -s, c);
}

vec3 kifs(vec3 p, float s, float tf) {
  float t = tf * time;
  float wave = sin(time * .3) * 0.5 + 0.5;

  for (float i = 0.; i < 4.; i += 1.) {
    p.xy *= rot2d(t + i);
    p.xz *= rot2d(t * 0.6 - i);
    vec3 p2 = p;
    p2.xy *= rot2d(PI / 2.);
    p = mix(abs(p), abs(p2), wave);
    p -= s;
    s *= 0.8 /* + .2 * sin(.3 * time)*/;
  }

  return p;
}

float map(vec3 p) {
  float d = 10000.;
  float old_z = p.z;

  p.xy *= rot2d(p.z / 40.);
  vec3 rep = vec3(20);
  p = mod(p, rep) - 0.5 * rep;

  vec3 pc = kifs(p, 1. + .1 * cos(sin(p.x / 300.) + old_z / 100.), .4 + .1 * sin(old_z / 200.));

  d = min(d, length(pc - vec3(0., .5 * sin(time), 0.)) - 1.);

  return d;
}

void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / resolution.x, gl_FragCoord.y / resolution.y);
  uv -= 0.5;
  uv /= vec2(resolution.y / resolution.x, 1);

  vec3 ro = vec3(0, 0, -20. + SPEED * time);
  vec3 rd = normalize(vec3(uv, 1));

  float d = 0.;
  int i;
  for (i = 0; i < 100; i++) {
    vec3 p = ro + d * rd;
    float ds = map(p);

    if (ds < 0.01 || ds > 100.) {
      break;
    }

    d += ds / 2.;
  }
  vec3 p = ro + d * rd;
  vec2 e = vec2(0.01, 0);
  vec3 n = normalize(map(p) - vec3(map(p - e.xyy), map(p - e.yxy), map(p - e.yyx)));
//  vec3 l = vec3(3, 2, -1);
  vec3 l = vec3(0, 0, -70. + SPEED * time);
  float dif = dot(n, normalize(l - p));

//  vec3 col = vec3(d / 10);
  vec3 col = vec3(dif * palette(p.z / 5.));
  glFragColor = vec4(col, 1.);
}

/*
void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;

    // Time varying pixel color
    vec3 col = 0.5 + 0.5*cos(time+uv.xyx+vec3(0,2,4));

    // Output to screen
    glFragColor = vec4(col,1.0);
}
*/
