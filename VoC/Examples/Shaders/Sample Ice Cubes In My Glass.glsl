#version 420

// original https://www.shadertoy.com/view/tdSGR1

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define t mod(time, 100.0)

struct Ray { vec3 o, d; };

float rectify(float f, float b) { return b+f*b*.5; }
mat2 rot(float a) { return mat2(cos(a),sin(a),-sin(a),cos(a)); }
float vmax(vec3 v) { return max(max(v.x,v.y),v.z); }
float sphere(vec3 p, float r) {return length(p)-r;}
float cube(vec3 p, vec3 s, float sm) {
  vec3 b=abs(p)-s;
  return length(max(b,0.0) + min(vmax(b), 0.0)) - sm;
}
vec3 rep(vec3 p, float n) { return mod(p-vec3(n*.5), n) - .5*n; }
float scene(vec3 p) {
  p = rep(p,3.0+sin(t*.42));
  p.xy = abs(p.xy);
  p.xz *= rot(t*.6+p.y);
  p.xy *= rot(t*.3);
  float s=sphere(p,.2);
  float c=cube(p, vec3(.5), .5);
  return max(-s,c);
}

Ray camera(vec2 uv, vec3 o, vec3 tg, float z) {
  Ray r;
  r.o = o;
  vec3 f = normalize(tg-o);
  vec3 s = cross(vec3(0,1,0), f);
  vec3 u = cross(f,s);
  vec3 i = (o+f*z)+uv.x*s+uv.y*u;
  r.d = normalize(i-o);
  return r;
}

vec3 normal(vec3 p) {
  vec2 e=vec2(-0.001, 0.001);
  return normalize(e.xyy*scene(p+e.xyy) + e.yxy*scene(p+e.yxy) + e.yyx*scene(p+e.yyx) + e.xxx*scene(p+e.xxx));
}

vec3 shade(vec3 p) {
  vec3 l=normalize(vec3(sin(t*.9), 2, cos(t)));
  vec3 n=normal(p);
  return vec3(max(0.0,dot(l, n)));
}

void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / resolution.x, gl_FragCoord.y / resolution.y);
  uv -= 0.5;
  uv /= vec2(resolution.y / resolution.x, 1);

  uv /= 1.0-length(uv)*1.5;
  //uv.x = abs(uv.x);
  vec3 eye = vec3(1,3,-2);
  eye.xz += 4.0*vec2(sin(t*.2),cos(t*.2));
  vec3 target = vec3(0);
  target.xy += 2.0*vec2(cos(t*.2),sin(t*.2));

  Ray r = camera(uv, eye, target, .2+.1*sin(t*2.0));
  vec3 col = vec3(0);

  // lets try nusan's transparency trick
  vec3 p = r.o;
  float d=0.0;
  float acc=.27;
  int bbb=0;
  float side=sign(scene(p));
  for(int i=0; i<200; i++) {
    float h=scene(p)*side*.92;
    if(h<0.00001) {
      bbb++;
      vec3 n=normal(p)*side;
      col += 1.*shade(p)+acc*vec3(-.1,0.1,.2+.1*cos(t));
      side=-side;
      acc *= .84;
      h = 0.001;
      r.d = refract(r.d, n, 1.0+.025*side);
    }
    p+=r.d*h;
    d+=h;
  }
  col /= float(bbb);
  glFragColor = vec4(pow(col, vec3(1.1/2.2)), 1);
}
