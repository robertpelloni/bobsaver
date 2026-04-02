#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/wttGzr

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//see updated version here: https://www.shadertoy.com/view/3lc3R8
float corner(vec2 p) {
  bool t = sign(p.y)+sign(p.x) == 2.;
  return t ? length(p) : max(p.x,p.y);
}

float cylinf(vec3 p, vec2 dim) {
  vec2 crds = vec2(length(p.xy), p.z);
  return corner(crds-dim);
}

float cyl(vec3 p, vec2 dim) {
  vec2 crds = vec2(length(p.xy), abs(p.z));
  return corner(crds-dim);
}

#define FK(k) floatBitsToInt(cos(k))^floatBitsToInt(k)
float hash(vec2 p) {
  int x = FK(p.x);int y = FK(p.y);
  return float((x*x-y)*(y*y+x)+x)/2.14e9;
}

float PAW = acos(-1.)*1.5;
float blackles_correction = 2./1.5;

vec2 piston(vec3 p, vec2 id, float scale) {
  vec2 center = id/scale;
  
  vec2 offset = vec2(hash(id*vec2(0.5,0.69)),hash(id*vec2(0.85,0.19)));
  center += offset;
  
  float off1 = hash(id)*PAW*blackles_correction;
  float off2 = hash(id+vec2(off1,cos(off1)))*PAW*blackles_correction;
  float off3 = hash(id+vec2(off2,cos(off2)))*PAW*blackles_correction;
  float height = sin(time + off1) + sin(time*1.9 + off2)*0.9 + sin(time*2.9 + off3)*0.7;
  
  float rod = cylinf(p-vec3(center,0), vec2(0.6,height));
  float scop = cylinf(p-vec3(center,0.), vec2(1.,(10.+height)/2.-10.));
  float best = min(rod, scop);
  float cap = cyl(p-vec3(center,height), vec2(1.2,0.1));
  if (cap < best) {
    return vec2(cap-0.05,1);
  }
  return vec2(best-0.1,0);
}

float mat = 0.;
vec2 bestid = vec2(0);
float scene(vec3 p) {
  float scale =0.2;
  
  vec2 id = floor(p.xy*scale);
  float dist = 10000.;
  for (int i = -1; i < 2; i++) {
    for (int j = -1; j < 2; j++) {
      vec2 currid = vec2(id)+vec2(i,j);
      vec2 pi = piston(p, currid, scale);
      if (pi.x < dist) {
        dist = pi.x;
        mat = pi.y;
        bestid = currid;
      }
    }
  }
  return dist;
}

vec3 norm(vec3 p) {
  mat3 k = mat3(p,p,p) - mat3(0.001);
  return normalize(scene(p) - vec3(scene(k[0]),scene(k[1]),scene(k[2])));
}

void erot(inout vec3 p, vec3 ax, float ro) {
  p = mix(dot(ax,p)*ax,p,cos(ro)) + sin(ro)*cross(ax,p);
}

float samp(vec3 p, vec3 i, float dist) {
  return tanh(2.*scene(p + i*dist)/dist)*0.5+0.5;
}

vec3 planeinterp(vec3 a, vec3 b, vec3 c, vec3 d, vec2 k) {
  a*=a;
  b*=b;
  c*=c;
  d*=d;
  return sqrt(mix(mix(a, b, k.x), mix(c, d, k.x),k.y));
}

vec3 prettycol(vec2 k) {
  return planeinterp(vec3(1,0,0), vec3(1,0.1,0.5), vec3(0.1,0.6,0.9), vec3(0.5,0.5,1), k*0.5+0.5);
}

vec3 shade(vec3 p, vec3 cam) {
  vec2 localbest = bestid;
  vec3 col = vec3(0.8);
  vec2 colr = vec2(hash(localbest*vec2(0.75,0.19)),hash(localbest*vec2(0.35,0.59)));
  if (mat == 1.) {
    col = mix(vec3(0.8),prettycol(colr),0.6);
  } else {
    col *= 0.9+colr.x*0.2;
  }
  vec3 n = norm(p);
  vec3 i = reflect(cam, n);
  float frensel = 1.-pow(abs(dot(n, cam)),2.)*0.5;
  float s = (samp(p, i, 0.5)+samp(p, i, 2.)+samp(p, i, 4.))/3.;
  return col*frensel*s;
}

void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / resolution.x, gl_FragCoord.y / resolution.y);
  uv -= 0.5;
  uv /= vec2(resolution.y / resolution.x, 1);

  vec3 cam = normalize(vec3(1.4, uv));
  vec3 init = vec3(-9,0,5);
  float ang1 = 0.6;
  float ang2 = 0.6;
  erot(cam, vec3(0,1,0), ang1);
  erot(init, vec3(0,1,0), ang1);
  init += vec3(time*5.,0,0);
  erot(cam, vec3(0,0,1), ang2);
  erot(init, vec3(0,0,1), ang2);

  vec3 p = init;
  bool hit = false;
  for (int i = 0; i < 100; i++) {
    float dist = scene(p);
    if (abs(dist) < 0.001) { hit = true; break; }
    if (distance(init, p) > 100.) break;
    p += dist*cam;
  }
  glFragColor.xyz = hit ? shade(p,cam) : vec3(0.5);
  glFragColor.xyz = smoothstep(vec3(0.1,0.1,0.05),vec3(0.9),glFragColor.xyz) + hash(uv*time)*0.025;
}
