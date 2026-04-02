#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/wdScWw

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float linedist(vec3 p, vec3 a, vec3 b) {
  float k = dot(p-a, b-a)/dot(b-a, b-a);
  return distance(p, mix(a, b, clamp(k,0.,1.)));
}
float linedist(vec2 p, vec2 a, vec2 b) {
  float k = dot(p-a, b-a)/dot(b-a, b-a);
  return distance(p, mix(a, b, clamp(k,0.,1.)));
}

#define FK(k) floatBitsToInt(cos(k))^floatBitsToInt(k)
float hash(float a, float b) {
  int x = FK(a);int y = FK(b);
  return float((x*x-y)*(y*y+x)-y)/2.14e9;
}

vec3 erot(vec3 p, vec3 ax, float ro) {
  return mix(dot(ax,p)*ax, p, cos(ro)) + sin(ro)*cross(ax,p);
}

vec3 idglob;
float hsglob;
int mat;

float hillheight(vec2 p) {
  float hillscale = 0.5;
  return cos(dot(p.xy*hillscale, vec2(0.05,0.02)))*2.5
  + cos(dot(p.xy*hillscale, vec2(0.01,0.03)))*2.5
  + cos(dot(p.xy*hillscale, vec2(0.02,0.05)))*2.5
  + cos(dot(p.xy*hillscale, vec2(0.08,0.05)))*2.5;
}

float scene(vec3 p) {
  p.z += hillheight(p.xy);
  float fl = p.z;

  float scale = 10.;
  vec2 id = floor(p.xy/scale);
  idglob = idglob;
  p.xy = (fract(p.xy/scale)-0.5)*scale;

  
  float seed = hash(id.x, id.y);
  float h1 = hash(seed, seed);
  float h2 = hash(h1, seed);
  float h3 = hash(h2, seed);
  float h4 = hash(h3, seed);
  float h5 = hash(h4, seed);
  float h6 = hash(h5, seed);
  float arcx = fract(time+h6*5.);
  p.z -= arcx*(1.-arcx)*10.;
  hsglob = hash(h5, h5);
  vec3 ax = normalize(tan(vec3(h1, h2, h3)));
  vec3 off = vec3(0, 0, 1.2);
  p -= off;
  p = erot(p, ax, h4*100. + time);
  
  p = erot(p, vec3(0,0,1), h5*100.);
  p.x += asin(sin(time*0.5*acos(-1.)));
  p += off;
  
  float sphere = length(p.xy)-1.;
  float crds = linedist(vec2(sphere, p.z), vec2(0,2.2), vec2(0,0))/sqrt(2.);
  float bottom = linedist(vec2(length(p.xy), p.z), vec2(-0.5,0), vec2(1.,0))/sqrt(2.);
  
  float handle_skel = linedist(vec2(max(p.y,1.3), p.z), vec2(1.3,1.4), vec2(1.3,0.9))-0.3;
  float handle = linedist(vec2(p.x, handle_skel), vec2(-0.2, 0.), vec2(0.2, 0.))/sqrt(2.);
  handle = max(1.-p.y, handle);
  float cup = 0.9*min(crds, min(bottom,handle))-0.05;
  mat = 0;
  if (fl < cup) {
    mat = 1;
    return fl;
  }
  return cup;
}

vec3 norm(vec3 p) {
  mat3 k = mat3(p,p,p)-mat3(0.001);
  return normalize(scene(p) - vec3(scene(k[0]),scene(k[1]),scene(k[2])));
}

#define ITERCOUNT 500
void main(void)
{
  vec2 uv = (gl_FragCoord.xy-resolution.xy*0.5)/resolution.y;

  vec3 cam =normalize(vec3(1,uv));
  vec3 init = vec3(0,0,10);
  float rot = 0.1;
  float zrot = cos(time)*0.4-0.5;
  cam = erot(cam, vec3(0,1,0), rot);
  init = erot(init, vec3(0,1,0), rot);
  cam = erot(cam, vec3(0,0,1), zrot);
  init = erot(init, vec3(0,0,1), zrot);
  init += fract(time/100.)*2000.*vec3(1,1,0);
  init.z -= hillheight(init.xy) + sin(time)*5.;
  vec3 p = init;
  bool hit = false;
  int i;
  for (i = 0; i < ITERCOUNT && !hit; i++) {
    float dist = scene(p);
    hit = hit || dist*dist < 1e-6;
    p += cam*dist;
  }
  float perc = float(i)/float(ITERCOUNT);
  
  vec3 idloc = idglob;
  float hsloc = hsglob;
  int matloc = mat;
  
  float fog = pow(exp(-distance(init, p)*0.05), .05);
 
  vec3 n = norm(p);
  vec3 r = reflect(cam, n);
  float ao = sqrt(sqrt(scene(p+n*0.5)+0.5));
  
  vec3 col = pow(vec3(0.2,0.1,0.05), vec3(2));
  col = abs(erot(col,vec3(1,0,0), hsloc*400.));
  if (matloc == 1) {
    col = abs(erot(col,vec3(0,1,0), hsloc*900.));
  } else {
    col = abs(erot(col,vec3(0,1,0), hsloc*1800.));
  }
  float factor = ao*length(sin(r*3.)*0.5+0.5)/sqrt(3.);
  vec3 brass = mix(col, col*10., factor) + pow(factor, 7.);
  vec3 bgcol = mix(vec3(0.6,0.3,0.8), vec3(0.3,0.6,.9), smoothstep(0., 1., uv.y+0.5));
  
  glFragColor.xyz = hit ? mix(bgcol, brass, 1.-perc) : bgcol;
  glFragColor.xyz = sqrt(glFragColor.xyz) + hash(hash(uv.x,uv.y),time)*0.02;
}
