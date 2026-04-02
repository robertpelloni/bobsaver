#version 420

// original https://www.shadertoy.com/view/tsSXDt

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

mat2 rot(float a) {
  float c = cos(a);
  float s = sin(a);
  
  return mat2(c, s, -s, c);
}

float len(vec3 p, float l) {
  vec3 q = pow(abs(p), vec3(l));
  return pow(q.x + q.y + q.z, 1.0/l);
}

float len(vec2 p, float l) {
  vec2 q = pow(abs(p), vec2(l));
  return pow(q.x + q.y, 1.0/l);
}

float box(vec3 p, vec3 b) {
  vec3 q = abs(p) - b;
  return max(max(q.x, q.y), q.z);
}

float torus(vec3 p, vec2 h, float l) {
  vec2 q = vec2(len(p, l) - h.x, p.y);
  return len(q, l) - h.y;
}

vec2 shape(vec3 p) {
  float a = torus(p, vec2(1, 0.2), 16.0);
  
  p.y = abs(p.y) - 0.2;
  
  float b = torus(p, vec2(1.1, 0.14), 16.0);

  vec2 s = vec2(a, 1.0);  
  vec2 t = vec2(b, 2.0);

  return s.x < t.x ? s : t;
}

vec2 path(float z) {
  return vec2(0.5*sin(0.3*z + 1.0), cos(0.6*z));
}

float glow = 0.0;
vec2 de(vec3 p) {
  float sc = 1.0;
  
  p.xy += path(p.z);
  
  vec3 op = p;
  p.z = mod(p.z + 1.5, 3.0) - 1.5;
  vec4 q = vec4(p*sc, 1);
  
  q.xyz -= 1.0;
  
  for(int i = 0; i < 5; i++) {
    q.xyz = abs(q.xyz + 1.0) - 1.0;
    q.xz *= rot(0.55);
    q.xy *= rot(0.1);
    
    q *= 1.1;
  }
  
  vec2 s = shape(q.xyz)/vec2(q.w*sc, 1);
  
  float at = mod(time, 100.0);
  vec3 gop = op - vec3(0, 0, at);
  
  vec2 t = vec2(length(gop) - 0.1, 2.0);
  
  glow += 0.1/(0.01 + t.x*t.x);
  
  return s.x < t.x ? s : t;
}

float form(vec2 p) {
  p = mod(p + 2.0, 4.0) - 2.0;
  
  for(int i = 0; i < 10; i++) {
    p = abs(p)/clamp(dot(p, p), 0.5, 0.8) - vec2(0.0, 0.6);
  }
  
  return smoothstep(0.5, 0.8, abs(p.y));
}

float mat(vec3 p, vec3 n) {
  vec3 m = pow(abs(n), vec3(10.0));
  
  float x = form(p.yz);
  float y = form(p.xz);
  float z = form(p.xy);
  
  return (m.x*x + m.y*y + m.z*z)/(m.x + m.y + m.z);
}

vec3 bump(vec3 p, vec3 n, float bf) {
  vec2 h = vec2(0.01, 0.0);
  vec3 g = vec3(
    mat(p - h.xyy, n),
    mat(p - h.yxy, n),
    mat(p - h.yyx, n));
  
  g -= mat(p, n);
  g -= n*dot(g, n);
  
  return normalize(n + bf*g);
}

vec3 mat(vec3 p, vec3 n, sampler2D s) {
  //vec3 m = pow(abs(n), vec3(10.0));
  
  //vec3 x = texture(s, p.yz).rgb;
  //vec3 y = texture(s, p.xz).rgb;
  //vec3 z = texture(s, p.xy).rgb;
  
  //return (m.x*x + m.y*y + m.z*z)/(m.x + m.y + m.z);
  return vec3(0.0);
}

vec3 bump(vec3 p, vec3 n, sampler2D s, float bf) {
  vec2 h = vec2(0.009, 0.0);
  
  vec3 g = mat3(
    mat(p - h.xyy, n, s),
    mat(p - h.yxy, n, s),
    mat(p - h.yyx, n, s))*vec3(0.299, 0.589, 0.114);
  
  g -= dot(mat(p, n, s), vec3(0.299, 0.589, 0.114));
  g -= n*dot(g, n);
  
  return normalize(n + bf*g);
}

void main(void) {
  vec2 uv = (gl_FragCoord.xy - 0.5*resolution.xy)/resolution.y;
  
  vec3 col = vec3(0);
  
  float at = mod(time, 100.0);
  
  vec3 ro = vec3(0, 0, -3.0 + at);
  ro.xy -= path(ro.z);
  
  vec3 la = vec3(0, 0, at);
  la.xy -= path(la.z);
  
  vec3 ww = normalize(la-ro);
  vec3 uu = cross(vec3(0, 1, 0), ww);
  vec3 vv = cross(ww, uu);
  vec3 rd = normalize(mat3(uu, vv, ww)*vec3(uv, 1));
  
  float t = 0.0, m = -1.0, mx = 50.0;
  for(int i = 0; i < 200; i++) {
    vec2 d = de(ro + rd*t);
    if(d.x < 0.001 || t >= mx) break;
    t += d.x*0.75;
    m = d.y;
  }
  
  vec2 h = vec2(0.001, 0.0);
  vec3 salb = vec3(1.00, 0.89, 0.25);
  vec3 lp = ro + vec3(0, 0, 3);
  
  if(t < mx) {
    vec3 p = ro + rd*t;
    vec3 n = normalize(vec3(
      de(p + h.xyy).x - de(p - h.xyy).x,
      de(p + h.yxy).x - de(p - h.yxy).x,
      de(p + h.yyx).x - de(p - h.yyx).x));
   
    vec3 alb = salb;
    
    vec3 ld = normalize(lp-p);
    
    if(m == 1.0) {
      alb = vec3(0.1, 0.2, 0.3);
      n = bump(p*0.25, n, 2.0);
    } else if(m == 2.0) {
      alb = vec3(0.3, 0.2, 0.1);
      n = bump(p, n,  1.0);
    }
    
    float ot = t/50.0;
    float occ = exp2(-pow(max(0.0, 1.0 - de(p + n*ot).x/ot), 2.0));
    float dif = max(0.0, dot(ld, n));
    
    float spe = pow(max(0.0, dot(reflect(-ld, n), -rd)), 16.0);
    float fre = pow(dot(rd, n) + 1.0, 2.0);
    
    col = 2.0*mix(occ*(alb*(0.1 + dif) + salb*spe), alb, fre);
  }
  
  col += 0.05*salb*glow;
   
  //col = mix(col, vec3(0.2, 0.3, 0.4), 1.0 - exp(-0.1*t));
  //col = vec3(1)*form(uv);
  glFragColor = vec4(pow(col, vec3(0.4545)), 1);
}
