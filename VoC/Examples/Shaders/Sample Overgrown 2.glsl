#version 420

// original https://www.shadertoy.com/view/wdy3D3

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14159

// polynomial smooth min (k = 0.1);
// https://www.iquilezles.org/www/articles/smin/smin.htm
float smin(float a, float b, float k) {
  float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
  return mix(b, a, h) - k * h * (1.0 - h);
}

float sdCylinder(vec3 p, vec3 c) { return length(p.xz - c.xy) - c.z; }

mat3 rotx(in float rad) {
  return mat3(1., 0., 0., 0., cos(rad), sin(rad), 0., -sin(rad), cos(rad));
}
mat3 roty(in float rad) {
  return mat3(cos(rad), 0., sin(rad), 0., 1., 0., -sin(rad), 0., cos(rad));
}
mat3 rotz(in float rad) {
  return mat3(cos(rad), sin(rad), 0., -sin(rad), cos(rad), 0., 0., 0., 1.);
}

float map(in vec3 p) {
  vec3 cyl = vec3(0., 0., .2);

  float displace = 
      cos(p.x * PI + mod(time,PI) * 10.)
      +cos(p.y * PI + time * .2)
      +cos(p.z * PI + time * .6)
      ;
  displace *= .05;

  float vert = sdCylinder(p, cyl) + displace;
  p *= rotz(PI * .5);
  float hori = sdCylinder(p, cyl) + displace;
  p *= rotx(PI * .5);
  float dept = sdCylinder(p, cyl) + displace;

  float blending = (sin(time * 2.) + 2.) * .2;
  return smin(dept, smin(hori, vert, blending), blending);
}

float raymod(in vec3 p, in vec3 c) {
  vec3 q = mod(p + 0.5 * c, c) - 0.5 * c;
  return map(q);
}

vec3 grad(vec3 p) {
  vec2 ep = vec2(0.00001, 0.);
  return normalize(map(p) -
                   vec3(map(p - ep.xyy), map(p - ep.yxy), map(p - ep.yyx)));
}

void main(void) {
  vec2 uv = (2. * gl_FragCoord.xy - resolution.xy) / resolution.y;
  vec3 color = vec3(0.);

  vec3 eye = vec3(.5, .5, 1.5);
  vec3 ray = normalize(vec3(uv, -.5));

  // some camera motion
  mat3 rotx = rotx(time * .2);
  mat3 roty = roty(time * .3);
  mat3 rotz = rotz(time * .4);
  mat3 rot = rotx * roty * rotz;
  eye *= rot;
  ray *= rot;

  float t = 0.;
  for (int i = 0; i < 100; i++) {
    vec3 p = eye + ray * t;
    float d = raymod(p, vec3(2.));
    if (d < .001 && i > 32) {
        
      vec3 n = grad(p);
      
      vec3 lcol = vec3(0., .6, .2);
      vec3 ldir = normalize(vec3(1., 1., 1.));
      
      vec3 lcol2 = vec3(.0, .8, .5);
      vec3 ldir2 = normalize(vec3(1., -1., -1.));
        
      float atten = pow(1. / (.2 + t), .5);
      color = (dot(n, ldir) * lcol + pow(.5 + dot(n, ldir2), 2.) * lcol2) * atten;
        
      break;
    }
    t += d;
    if (t > 100.) {
      color = vec3(0.);
      break;
    }
  }

  glFragColor = vec4(color, 1.);
}
