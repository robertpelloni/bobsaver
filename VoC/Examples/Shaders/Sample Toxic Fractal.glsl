#version 420

// original https://www.shadertoy.com/view/WtlXW7

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float tt, g;

mat2 rotate(float a) {
  return mat2(cos(a), -sin(a), sin(a), cos(a));
}

float smin( float a, float b, float k ) {
  float h = max( k-abs(a-b), 0.0 )/k;
  return min( a, b ) - h*h*h*k*(1.0/6.0);
}

float sphereSDF (vec3 p, vec3 c, float r) {
  return length(c - p) - r;
}

float cubeSDF (vec3 p, vec3 c, vec3 dimensions, float borderRoundness) {
  vec3 pos = abs(c - p) - dimensions;
  return length(max(pos, 0.)) - borderRoundness + min(max(pos.x, max(pos.y, pos.z)), 0.);
}

vec2 map (vec3 p) {
  //fractal
  for (int i=0; i<3; i++) {
    p = abs(p) - vec3(6.);

    p.xz *= rotate(sin(tt) * .5 + .6);
    p.yz *= rotate(cos(tt) * .5 + .8);
    p += length(p.yx * sin(tt) * .2 + .4) * .2;
  }

  p *= .4; // to scale fractal

  // primitives
  float s1 = sphereSDF(p, normalize(vec3(5., 8., 3.)), .3);
  vec3 p2 = p;
  p2.xz *= rotate(tt * 10.);
  float s2 = sphereSDF(p2, normalize(vec3(-5., -3., -4.)), .2);

  vec2 t = vec2(min(s1 * .5, s2 * .5), 5.);
  g += .1 / (.1 + t.x * t.x * t.x * 50.); // for glow, 100 for tight glow (small = more spread)

  
  float c1 = cubeSDF(abs(p) - vec3(length(p.yz) + .2, .1, .8), vec3(0.), vec3(.5, .2, .8), .05);
  c1 += sin(p.x * 30. * sin(tt * .4) * 2.) * cos(p.y * 35. * sin(tt * .5) * 3.) * cos(p.z * 30.) * .03 + cos(tt * .08) * .01;
  float c2 = cubeSDF(abs(p) - vec3(.5, .3, 2.), vec3(0.), vec3(.3, .1, .8), .01);

  vec2 h = vec2(smin(c1 * .8, c2 * .8, 1.2), 1.);

  t = (t.x < h.x) ? t : h; // merge materials

  return t / .5;
}

vec2 trace (vec3 ro, vec3 rd) {
  const float MAX_DEPTH = 50.;
  vec2 h, t = vec2(.1);

  for (int i = 0; i < 128; i++) {
    h = map(ro + rd * t.x);
    if (h.x < .0001 || t.x > MAX_DEPTH) break;
    t.x += h.x; t.y = h.y;
  }
  if (t.x > MAX_DEPTH) t.x = 0.;
  return t;
}

vec3 getNormal (vec3 p) {
  float d = map(p).x;
  vec2 e = vec2(.01, 0.);

  return normalize(d - vec3(
    map(p - e.xyy).x,
    map(p - e.yxy).x,
    map(p - e.yyx).x));
}

struct Material {
  float ambient;
  float diffuse;
  float specular;
};

float getLight (vec3 lightPos, vec3 p, vec3 rd, float lightOcclusion, Material material) {
  // https://www.shadertoy.com/view/ll2GW1
  vec3 light = normalize(lightPos - p);
  vec3 normal = getNormal(p);

  // phong reflection
  float ambient = clamp(.5 + .5 * normal.y, 0., 1.);
  float diffuse = clamp(dot(normal, light), 0., 1.);
  vec3 half_way = normalize(-rd + light);
  float specular = pow(clamp(dot(half_way, normal), 0.0, 1.0), 16.);

  return (ambient * material.ambient * lightOcclusion) +
   (diffuse * material.diffuse * lightOcclusion) +
   (diffuse * specular * material.specular * lightOcclusion);
}

vec3 getRayDirection (vec2 uv, vec3 rayOrigin, vec3 lookat, float zoom) {
  // https://www.youtube.com/watch?v=PBxuVlp7nuM
  vec3 forward = normalize(lookat - rayOrigin);
  vec3 right = normalize(cross(vec3(0., 1., 0.), forward));
  vec3 up = cross(forward, right);
  vec3 center = rayOrigin + forward * zoom;
  vec3 intersection = center + uv.x * right + uv.y * up;
  return normalize(intersection - rayOrigin);
}

void main(void) {
  vec2 uv = (gl_FragCoord.xy / resolution.xy) * 2.0 - 1.0;
  uv.x *= resolution.x / resolution.y;
  tt = mod(time * .1, 100.);

  // camera
  vec3 ro = vec3(0., 0., 20. + sin(tt) * 10. + 15.);
  ro.xz *= rotate(tt * .25);
  ro.yz *= rotate(tt * .5);
  vec3 rd = getRayDirection(uv, ro, vec3(0.), 2.);

  // color, fog and light direction
  // vec3 ld = normalize(vec3(.5, .8, .5));
  // vec3 ld1 = vec3(5., 8., 3.);
  vec3 ld1 = vec3(5., 8., 3.);
  // vec3 ld2 = vec3(15., 28., 13.);
  vec3 ld2 = vec3(-5., -3., -4.);
  vec3 fog = vec3(.09, .08, .02) * (.5 + (length(uv) - .3));
  vec3 color = fog;

  // scene
  vec2 sc = trace(ro, rd);
  float t = sc.x;

  if (t > 0.) {
    vec3 p = ro + rd * t;
    vec3 normal = getNormal(p);
    vec3 albido = vec3(.5, .5, .2);//base color

    if (sc.y < 3.) {
      albido = vec3(.8, .2, .3);
    }

    // lightning
    // float diff = clamp(dot(p, ld), 0., 1.) * .5;
    color *= getLight(ld1, p, rd, .2, Material(.1, .5, .2));
    ld2.xz *= rotate(tt * 10.);
    color += getLight(ld2, p, rd, .5, Material(.1, .8, 3.2));
    color *= albido;
    color = mix(color, fog, 1. - exp(-.0001*t*t*t)); //gradient
  }

  color += vec3(.5, .5, .2) * g * .03; // for glow
  glFragColor = vec4(pow(color, vec3(.45)), 1.);
}
