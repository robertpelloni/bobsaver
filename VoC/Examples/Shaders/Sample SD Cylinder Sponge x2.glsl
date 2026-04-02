#version 420

// original https://www.shadertoy.com/view/wlV3Wh

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Fork of "sdCylinder Sponge" by jorge2017a1. https://shadertoy.com/view/3lK3D1
// 2020-01-12 18:37:15

//referencia 60442.0
float smin(float a, float b, float k)
{
    float h = clamp(.5 + .5*(a-b)/k, 0., 1.);
    return mix(a, b, h) - k*h*(1.-h);
}

float maxcomp(vec2 p) {
  return max(p.x, p.y);
}

float sdBox(vec3 p, vec3 b) {
  p = abs(p) - b;
  return length(max(p, 0.0)) + min(max(p.x, max(p.y, p.z)), 0.0);
}

float sdBox(vec2 p, vec2 b) {
  p = abs(p) - b;
  return length(max(p, 0.0)) + min(max(p.x, p.y), 0.0);
}

float dsCapsule(vec3 point_a, vec3 point_b, float r, vec3 point_p)//cylinder SDF
{
     vec3 ap = point_p - point_a;
    vec3 ab = point_b - point_a;
    float ratio = dot(ap, ab) / dot(ab , ab);
    ratio = clamp(ratio, 0.f, 1.f);
    vec3 point_c = point_a + ratio * ab;
    return length(point_c - point_p) - r;
}

float sdCylinder( vec3 p, vec2 h )
{
    vec2 d = abs(vec2(length(p.xz),p.y)) - h;
    return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

/*
float sdCross(vec3 p) {
  float da = sdBox(p.xy, vec2(1.0));
  float db = sdBox(p.yz, vec2(1.0));
  float dc = sdBox(p.zx, vec2(1.0));
  return min(da, min(db, dc));
}
*/

float sdCross(vec3 p) {
  float da = maxcomp(abs(p.xy));
  float db = maxcomp(abs(p.yz));
  float dc = maxcomp(abs(p.xz));
  return min(da, min(db, dc)) - 1.0;
}

mat2 rotate(float r) {
  float c = cos(r);
  float s = sin(r);
  return mat2(c, s, -s, c);
}

float map(vec3 p) {
  p.zx *= rotate(time);
  p.yx *= rotate(time * 0.5);

  
  
  float d;
   
    float  distToCapsule =sdCylinder( p, vec2(.350,1.76) );
    
    d=distToCapsule;
    
    
  float s = 1.4;
  for (int m = 0; m < 3; m++) {
    vec3 a = mod(p * s, 2.0) - 1.0;
    s *= 3.0;
    vec3 r = 1.0 - 3.01 * abs(a*1.01);
    float c = sdCross(r) / s;
    d = max(d, c);
  }
    
      p.zx *= rotate(1.+time);
  p.yx *= rotate(time * 0.5);

  
  
  float d2;
   
    float  distToCapsule2 =sdCylinder( p, vec2(1.7,.12) );
    
    d2=distToCapsule2;
    
    
  float s2 = 1.1;
  for (int m2 = 0; m2 < 4; m2++) {
    vec3 a2 = mod(p * s2, 2.0) - 1.0;
    s2 *= 3.0;
    vec3 r2 = 1.0 - 3.1 * abs(a2*1.05);
    float c2 = sdCross(r2) / s2;
    d2 = max(d2, c2);
  }
    
  return smin(d,d2,.125);
                               
                               

                               
}

vec3 normal(vec3 p) {
  float d = 0.01;
  return normalize(vec3(
    map(p + vec3(d, 0.0, 0.0)) - map(p - vec3(d, 0.0, 0.0)),
    map(p + vec3(0.0, d, 0.0)) - map(p - vec3(0.0, d, 0.0)),
    map(p + vec3(0.0, 0.0, d)) - map(p - vec3(0.0, 0.0, d))
  ));
}

vec3 raymarch(vec3 ro, vec3 rd) {
  vec3 p = ro;
  for (int i = 0; i < 64; i++) {
    float d = map(p);
    p += d * rd;
    if (d < 0.01) {
      vec3 n = normal(p);
      return n * 0.5 + 0.5;
      //return vec3(0.1) + vec3(0.95, 0.5, 0.5) * max(0.0, dot(n, normalize(vec3(1.0))));
    }
  }
  return vec3(1.0);
}

void main(void)
{

  vec2 st = (2.0 * gl_FragCoord.xy - resolution.xy) / min(resolution.x, resolution.y);

  vec3 ro = vec3(0.0, 0.0, 3.0);
  vec3 ta = vec3(0.0);
  vec3 z = normalize(ta - ro);
  vec3 x = normalize(cross(z, vec3(0.0, 1.0, 0.0)));
  vec3 y = normalize(cross(x, z));
  vec3 rd = normalize(st.x * x + st.y * y + 1.5 * z);

  vec3 c = raymarch(ro, rd);

  glFragColor = vec4(c, 1.0);

}
