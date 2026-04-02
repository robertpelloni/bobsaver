#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/wsGXDh

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec3 erot(vec3 p , vec3 ax, float ro) {
  return mix(dot(p,ax)*ax, p, cos(ro)) + sin(ro)*cross(ax,p);
}

#define FK(k) floatBitsToInt(cos(k))^floatBitsToInt(k)
float hash(vec2 p) {
  int x = FK(p.x);int y = FK(p.y);
  return float((x*x+y)*(y*y-x)-x)/2.147e9;
}

vec2 linedist(vec2 p, vec2 a, vec2 b) {
  vec2 pa = p-a;
  float k = dot(p-a,b-a)/dot(b-a,b-a);
  float s = sign(dot(vec2(-pa.y,pa.x),b-a));
  float d = distance(p, mix(a,b,clamp(k,0.,1.)));
  return vec2(d,s);
}

float triangle(vec2 p, vec2 dim) {
  vec2 a = vec2(0,dim.y);
  vec2 b = vec2(dim.x,-dim.y);
  vec2 ldx = min(linedist(p, a, b), linedist(p, b, vec2(-b.x,b.y)));
  return -ldx.x*ldx.y;
}

float torus(vec3 p, vec2 di) {
  vec2 crd = vec2(length(p.xy), p.z);
  return length(crd-vec2(di.x,0)) - di.y;
}

float cylinder(vec3 p, vec2 di) {
  vec2 crd = vec2(length(p.xy), p.z);
  crd.y = abs(crd.y)-di.y;
  crd.x -= di.x;
  
  float sg = sign(crd.x)+sign(crd.y);
  return sg == 2. ? length(crd) : max(crd.x,crd.y);
}

float cone(vec3 p, vec2 di) {
  vec2 crd = vec2(length(p.xy), p.z);
  return triangle(crd, di);
}

float scene(vec3 p) {
  vec3 tor = p;
  tor = erot(tor, vec3(0,0,1), time);
  tor = erot(tor, vec3(0,1,0), 0.6);
  
  vec3 cyl = p - vec3(0,-1,0);
  cyl = erot(cyl, vec3(0,1,0), time);
  
  vec3 con = p - vec3(0,1,0);
  con = erot(con, vec3(0,1,0), -time);
  
  float best = cylinder(cyl, vec2(0.3, 0.8))-0.01;
  best = min(best, torus(tor, vec2(0.8,0.2)));
  best = min(best, cone(con, vec2(0.5,0.7)))-0.01;
  return min(best, p.z+0.9);
}

bool flor(vec3 cam, vec3 init, inout vec3 inter) {
  vec3 flooror = vec3(0,0,-0.9);
  vec3 floornor = vec3(0,0,1);
  float d = dot(cam, vec3(0,0,1));
  if (d > 0.) return false;
  
  float t = dot(flooror-init, floornor)/d;
  inter = t*cam+init;
  return true;
}

mat3 eps = mat3(0.001);
#define AP(f,k) vec3(f(k[0]),f(k[1]),f(k[2]))
vec3 norm(vec3 p) {
  mat3 k = mat3(p,p,p)-eps;
  return normalize(scene(p) - AP(scene, k));
}

vec3 shade(float d) {
  float str = cos(d*200.+3.1415)*0.2+0.8 * pow((exp(0.)-exp(-abs(d))), 0.3);
  return d > 0. ? vec3(1,0.5,0)*str : vec3(0,0.5,1)*str;
}

float skycol(vec3 angl) {
  return sqrt(max(angl.z,0.))*0.5+0.5;
}

float skyshade(vec3 norm) {
  float d = pow(norm.z+0.3,2.)*pow(norm.z*0.5+0.5,1.)/pow(1.3,2.)*0.9+0.1;
  return sqrt(sqrt(d))*0.8+0.2;
}

float ao(vec3 p, vec3 n, float sc) {
  float d1 = 0.001;
  float d2 = scene(p+n*sc);
  return sqrt(((d2-d1)/sc)*0.5+0.5);
}

float comp(float p) {
  //return p;
  return pow(abs(p),5.)*sign(p);
  
}

void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / resolution.x, gl_FragCoord.y / resolution.y);
  uv -= 0.5;
  uv /= vec2(resolution.y / resolution.x, 1);

  vec3 cam = normalize(vec3(1.4, uv));
  vec3 init = vec3(-4.,0.,0.);
  bool hit = false;
  vec3 p = init;
  for (int i = 0; i < 150; i++) {
    float dist = scene(p);
    if ( abs(dist) < 0.001) { hit = true; break; }
    if (distance(p, init) > 100.) break;
    p+=cam*dist;
  }
  vec3 inter;
  if (flor(cam, init, inter)) {
    if (distance(inter, init) < distance(init, p) || !hit) {hit=true; p = inter;}
  }
  float noise = comp(hash(uv*time));
  if (!hit) {
    glFragColor.xyz = vec3(skycol(cam)) + noise*0.05;
    return;
  }
  vec3 n = norm(p);
  float fog = exp(-distance(init,p)*0.03)/exp(0.)*0.4+0.6;
  float aoo = pow(ao(p, n, 0.1)*ao(p, n, 0.2)*ao(p, n, 0.33)*ao(p, n, 0.66)*ao(p, n, 1.),1./5.);
  glFragColor.xyz = vec3(skyshade(n)*0.8*aoo)*fog;
  glFragColor.xyz += noise*0.05;
}
