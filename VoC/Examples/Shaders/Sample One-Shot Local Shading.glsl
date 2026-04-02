#version 420

// original https://www.shadertoy.com/view/Wt3GDN

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float scene(vec3 p) {
  return length(p-vec3(0,0,1))-1.;
}

struct Plane {
  vec3 I;
  vec3 N;
};

struct PlaneHit {
  bool hit;
  vec3 p;
};

PlaneHit planeIntersect(vec3 init, vec3 cam, Plane pln) {
  float t = -(dot(init, pln.N) + dot(pln.I, pln.N))/dot(cam, pln.N);
  return PlaneHit(t > 0., cam*t+init);
}

vec3 checkerboard(vec2 uv, float d) {
  uv += sin(time)*3.;
  return pow(vec3(smoothstep(-d,d,sin(uv.x)*sin(uv.y)), smoothstep(-d,d,sin(uv.x)*sin(uv.y+0.8)), smoothstep(-d,d,sin(uv.x+0.8)*sin(uv.y))),vec3(2));
}

vec3 oneShot(vec3 p, vec3 n, Plane pln) {
  float x = dot(n, pln.N);
  vec3 rj = n - x*pln.N;
  vec3 pp = (p - pln.I) - dot(p - pln.I, pln.N)*pln.N + pln.I;
  float h = distance(pp, p);
  float hr = h/(sqrt(3.+x*x)-2.*x);
  vec3 pos = pp + rj*hr;
  vec3 dir = normalize(p-pos);
  float lod = distance(p,pos);
  
  return 1.5*checkerboard(pos.xy, lod)*dot(dir, pln.N)*dot(-n, dir)/pow(distance(p,pos)+1.,2.);
}

void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / resolution.x, gl_FragCoord.y / resolution.y);
  uv -= 0.5;
  uv /= vec2(resolution.y / resolution.x, 1);

  vec3 cam = normalize(vec3(0.7,uv));
  vec3 init = vec3(-4,0,1);
  vec3 p = init;
  bool hit = false;
  for (int i = 0; i < 100; i++) {
    float dist = scene(p);
    if (abs(dist) < 0.001) { hit = true; break; }
    if (distance(p, init) > 30.) { break; }
    p += cam*dist;
  }
  Plane plane = Plane(vec3(0), normalize(vec3(0,0,1)));
  PlaneHit pln = planeIntersect(init, cam, plane);
  vec3 n = p-vec3(0,0,1);
  vec3 color = vec3(0);
  if (pln.hit && (!hit || distance(init, pln.p) < distance(init, p))) {
    color = checkerboard(pln.p.xy, pow(distance(init, pln.p),2.)*0.001);
    color *= sqrt(smoothstep(150., 0., distance(init, pln.p)));
  }
  if (hit) {
    color = oneShot(p, n, plane);
  }
  if (color.x < 0. || color.y < 0. || color.z < 0.) {
    color = vec3(1,0,0);
  }
  glFragColor.xyz = sqrt(color);
}
