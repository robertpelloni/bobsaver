#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec2 opU(vec2 a, vec2 b) { return a.x < b.x ? a : b; }

mat2 rot(float a) {
  float s = sin(a);
  float c = cos(a);
  
  return mat2(c, s, -s, c);
}

float box(vec3 p, vec3 r) {
  vec3 q = abs(p) - r;
  return max(max(q.x, q.y), q.z);
}

float box2(vec2 p, vec2 r) {
  vec2 q = abs(p) - r;
  return max(q.x, q.y);
}

vec2 shape(vec3 p) {
  vec2 s = vec2(box(p, vec3(0.25)), 1);
  vec2 b = vec2(box2(p.xy, vec2(0.15)), 2);
  vec2 e = vec2(box2(p.yz, vec2(0.15)), 3);
  
  return opU(opU(s, b), e);
}

float glow = 0.0;
vec2 de(vec3 p) {
  float s = 0.5;
  
  vec3 op = p;
  p *= s;
  p.z = mod(p.z + 2.5, 5.0) - 2.5;
  
  vec4 q = vec4(p, 1);
  
  for(int i = 0; i < 5; i++) {
    q.xyz = abs(q.xyz) - vec3(0.1, 0.9, 0.7);
    q.xz *= rot(float(i)*1.3);
    q.xy *= rot(1.31);
    q.yz *= rot(0.35);
    
    q *= 1.3;
  }
  
  q.w *= s;
  
  glow += 0.1/(0.01 + pow(abs(length(op + vec3(0, 0, 0.5-mod(time, 100.0))) - 0.25), 5.0));
  
  return shape(q.xyz)/vec2(q.w, 1);
}

void main(void)
{
  vec2 uv = (2.0*gl_FragCoord.xy - resolution)/resolution.y;
  
  vec3 col, bg;
  col = bg = vec3(0.04)*(1.8 - (length(uv) - 0.2));
  
  float at = mod(time, 100.0);
  
  vec3 ro = vec3(0, 0, -3.0 + at);
  vec3 ww = normalize(vec3(0, 0, at)-ro);
  vec3 uu = normalize(cross(vec3(0, 1, 0), ww));
  vec3 vv = normalize(cross(ww, uu));
  vec3 rd = normalize(mat3(uu, vv, ww)*vec3(uv, 1.0));
  
  float mx = 50.0, t = 0.0, m = -1.0;
  for(int i = 0; i < 200; i++) {
    vec2 d = de(ro + rd*t);
    if(d.x < 0.001 || t >= mx) break;
    t += d.x*0.5;
    m = d.y;
  }
  
  vec2 e = vec2(1, -1)*0.001;
  vec3 ld = normalize(vec3(0, 0.5, -0.5));
  
  if(t < mx) {
    vec3 p = ro + rd*t;
    vec3 n = normalize(
      e.xxx*de(p + e.xxx).x +
      e.xyy*de(p + e.xyy).x +
      e.yxy*de(p + e.yxy).x +
      e.yyx*de(p + e.yyx).x);
    
    vec3 ld = normalize(ro-p);
    float lt = length(ld);
    float att = 1.0/(1.0 + 500.4*lt + 90.4*lt*lt);
    
    float aot = t/50.0;
    float ao = exp2(-pow(max(0.0, 1.0 - de(p+n*aot).x/aot), 2.0));
    
    float dif = max(0.0, dot(n, ld));
    float sss = smoothstep(-1.0, 1.0, de(p+ld*0.4).x/0.4);
    
    vec3 sp = vec3(1)*pow(max(0.0, dot(reflect(-ld, n), -rd)), m == 1.0 ? 1.0 : 16.0);
    float fr = max(0.0, pow(1.0 + dot(rd, n), 2.0));
    
    vec3 al = vec3(0.2);
    if(m == 1.0) al = vec3(2.0, 0.3, 0.5); 
    
    col = mix(al*ao*(sss + dif + 2.0*sp), bg, fr);
  }
 
  col += 0.1*vec3(1.0, 0.15, 0.25)*glow;
  col = mix(col, vec3(0), 1.0 - exp(-1.1*t));
  glFragColor = vec4(pow(col, vec3(0.45)), 1);
}
