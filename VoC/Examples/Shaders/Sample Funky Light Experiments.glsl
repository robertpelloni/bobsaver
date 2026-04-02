#version 420

// original https://www.shadertoy.com/view/WlKSzw

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define time time
#define ZPOS -30.

float PI = acos(-1.);

mat2 rot2d(float a) {
  float c = cos(a), s = sin(a);
  
  return mat2(c, s, -s, c);
}

float sph(vec3 p, float r) {
  return length(p) - r;
}

float wave(float t, float a) {
    return a * (.5 * sin(time) + .5);
}

vec3 kifs(vec3 p, float r, float s, float tf, float it) {
    float t = tf * time;
    for (float i = 0.; i < it; i++) {
        p.xy *= rot2d(t * .6);
        p.yz *= rot2d(t * .7 - i);
        p = abs(p);
        p -= s;
        s *= r;
    }
    
    return p;
}

float tube(vec3 p, vec3 a, vec3 b, float r) {
  vec3 ab = b - a;
  vec3 ap = p - a;
  float t = dot(ab, ap) / dot(ab, ab);
  t = clamp(t, 0., 1.);
  vec3 c = a + ab * t;
  
  return length(p - c) - r;
}

vec3 rep(vec3 p, vec3 r) {
  vec3 q = mod(p, r) - .5 * r;
  
  return q;
}

float at = 0.;
float map(vec3 p) {
    p = kifs(p, 1.3, .7, 1., 4.);
//    p.xz *= rot2d(time);
//    float d = p.y + 1.;
      float d = 500.;  
    float obj = sph(p, 1.);
    obj = max(obj, -tube(p, vec3(-2, 0, 0), vec3(2, 0, 0), .5));
    d = min(d, obj);
    
    at += .2 / (.1 + pow(d, 3.));
    
    return d;
}

float secondary_light(vec3 p) {
    vec3 lp = vec3(0, 0, 0);
    vec3 tl = lp - p;
    vec3 tln = normalize(tl);

    float d = 0.;
    for (int i = 0; i < 100; i++) {
        vec3 p_rm = p + d * tln;
        float ds = map(p_rm);
        
        if (ds < .01 || ds > 100.) {
            break;
        }
        
        d += ds;
    }
    
    if (d < length(tl)) {
        return 0.;
    }
    
    
    return 1.;
}

vec3 glow = vec3(0, 0, 0);
vec3 glow2 = vec3(0, 0, 0);
float rm(vec3 ro, vec3 rd) {
  float d = 0.;
  
  for (int i = 0; i < 100; i++) {
    vec3 p = ro + d * rd;
    float ds = map(p);
    
    if (ds < 0.01 || ds > 100.) {
      break;
    }
    
    d += ds * 1.;
    glow += .0002 * at * vec3(.5, 0., 0.);
      
    float sec_light = secondary_light(p);
    glow2 += (.05 + wave(2.3, .1)) * sec_light * vec3(0., 0., 1.);
  }
  
  return d;
}

vec3 normal(vec3 p) {
  vec2 e = vec2(0.01, 0);
  
  vec3 n = map(p) - vec3(
    map(p - e.xyy),
    map(p - e.yxy),
    map(p - e.yyx)
  );
  
  return normalize(n);
}

float light(vec3 p) {
  vec3 lp = vec3(2, 5, ZPOS);
//  lp.xz *= rot2d(time);
  vec3 tl = lp - p;
  vec3 tln = normalize(tl);
  vec3 n = normal(p);
  float dif = dot(n, tln);
  float d = rm(p + .01 * n, tln);
  
  if (d < length(tl)) {
    dif *= .1;
  }
  
  return dif;
}

void main(void)
{
    vec2 uv = vec2(gl_FragCoord.xy.x / resolution.x, gl_FragCoord.xy.y / resolution.y);
    uv -= 0.5;
    uv /= vec2(resolution.y / resolution.x, 1);
//    uv *= sin(time);
//    uv *= rot2d(sin(time) * PI);

    vec3 ro = vec3(0, 0, ZPOS);
      vec3 rd = normalize(vec3(uv, 1.));
    
      float d = rm(ro, rd);
      vec3 p = ro + d * rd;
//      float dif = light(p);
      
//    vec3 col = .2 * dif * glow;
//      vec3 col = vec3(dif) + glow2 + glow;
      vec3 col = glow2 + glow;
    
    glFragColor = vec4(col,1.0);
}
