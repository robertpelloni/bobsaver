#version 420

// original https://www.shadertoy.com/view/3d2yWy

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float hash(float a, float b) {
  return fract(sin(dot(vec2(a,b), vec2(12.9898, 78.233))) * 43758.5453)*2.-1.;
}

float id;
float scene(vec3 p) {
  float xscale = 1.;
  id = floor(p.x*xscale);
  p.x = (fract(p.x*xscale)-0.5)/xscale;
  
  float m1 = hash(id, 69.);
  float m2 = hash(id, 38.);
  float m3 = hash(id, 41.);
  float myTime = time + m3*10.;
  p.yz += vec2(m1,m2)*0.2 * sin(myTime*2.);
  
  return 0.8*(length(vec2(length(p.yz)-0.5, p.x))-0.1);
}

vec3 norm(vec3 p) {
  mat3 k = mat3(p,p,p)-mat3(0.001);
  return normalize(scene(p) - vec3(scene(k[0]), scene(k[1]), scene(k[2])));
}

vec3 srgb(float a, float b, float c) {
  return pow(vec3(a,b,c), vec3(2.));
}

vec3 erot(vec3 p, vec3 ax, float ro) {
  return mix(dot(ax,p)*ax, p, cos(ro)) + sin(ro)*cross(ax,p);
}

void main(void)
{
  vec2 uv = (gl_FragCoord.xy - 0.5*resolution.xy)/resolution.y;
  
  float n1 = hash(hash(uv.x, uv.y), time * 11.);
  float n2 = hash(hash(uv.x, uv.y), time * 23.);
  uv += vec2(n1,n2)*0.002;

  vec3 cam = normalize(vec3(1, uv));
  float rot = time;
  float shift = time;
  float outside = smoothstep(0.0,0.5, asin(sin(time*acos(-1.)/4.)));
  float look = mix(0.05, 0.4, outside);
  vec3 init = vec3(shift,0,0) + vec3(0, sin(rot), cos(rot))*mix(0.15, 1., outside);
  cam = erot(cam, vec3(0,1,0), cos(rot)*look);
  cam = erot(cam, vec3(0,0,1), -sin(rot)*look);
  vec3 p = init;
  bool hit = false;
  float mini = 100000.;
  int i;
  for (i = 0 ; i < 100 && !hit; i++) {
    float dist = scene(p);
    mini = min(dist, mini);
    hit = dist*dist < 1e-6;
    p+=dist*cam;
  }
  float glow = pow(exp(-mini*20.), 2.);
  float idloc = id;
  float fog = (float(i)/100.);
  vec3 n = norm(p);
  vec3 r = reflect(cam, n);
  float diff = length(sin(n*2.)*0.5+0.5)/sqrt(3.);
  float spec = length(sin(r*2.)*0.5+0.5)/sqrt(3.);
  vec3 col = mix(srgb(0.4,0.1,0.2), srgb(0.9,0.7,0.4), spec);
  col = abs(erot(col, normalize(vec3(1,7,1)), idloc)) + pow(spec, 15.)*2.;
  vec3 bg = mix(srgb(0.5, 0.2, 0.3), srgb(0.2, 0.1, 0.3), sqrt(length(uv))) + glow*0.2;
  glFragColor.xyz = hit ? mix(col, bg, fog) : bg;
  glFragColor.xyz = sqrt(glFragColor.xyz) + hash(hash(uv.x, uv.y), time)*0.04;
  
  glFragColor.xyz = smoothstep(vec3(-0.1), vec3(1.1), glFragColor.xyz);
}
