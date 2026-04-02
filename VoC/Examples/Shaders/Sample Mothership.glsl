#version 420

// original https://www.shadertoy.com/view/3tXXDj

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
    
  float n = sin(tt * 6.) * .05 + .05;
  for (int i=0; i<2; i++) {
    p = abs(p) - vec3(4., 3., 5.);
    //p = abs(p) - vec3(2., 1., 3.);

    p.xz *= rotate(sin(tt - p.y + p.x) * n + .6);
    p.yz *= rotate(cos(tt + p.x) * (n * .7) + 5.8);
    p.xy *= rotate(cos(tt + p.z) * (n * 1.2) + 2.);
    //p += length(p.yx * sin(tt) * .2 + .4) * .5;
  }

  p *= .7; // to scale fractal

  // primitives
  
  float c1 = cubeSDF(abs(p) - vec3(length(p.yz) + .2, .1, .8), vec3(0.), vec3(.5, .2, .8), .05);
  c1 += sin(p.x * 4.) * cos(p.y * 6. + sin(tt)) * sin(p.z * 3.) * .3;
  float c2 = cubeSDF(abs(p) - vec3(.5, .3, 2.), vec3(0.), vec3(.3, .1, .6), .01);

  vec2 t = vec2(smin(c1 * .1, c2 * .05, .5), 2.);
  
  p += sin(length(p) * 22. + tt * .2) * .04;
  float c3 = cubeSDF(abs(p) - vec3(.3, .2, .2), vec3(2.), vec3(.2, .4, .3), .03) * .3;  
  vec2 h = vec2(smin(c3 * .2, c2 * .3, 1.2), .1);
  t = (t.x < h.x) ? t : h; // merge materials

  return t / .8;
}

vec2 trace (vec3 ro, vec3 rd) {
  const float MAX_DEPTH = 50.;
  vec2 h, t = vec2(.1);

  for (int i = 0; i < 268; i++) {
    h = map(ro + rd * t.x);
    if (h.x < .00001 || t.x > MAX_DEPTH) break;
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
  vec3 ro = vec3(0., 0., 30. + sin(tt * 1.2) * 10.);
  //vec3 ro = vec3(0., 0., 35.);
  ro.xz *= rotate(tt * .25);
  ro.yz *= rotate(tt * .5);
  vec3 rd = getRayDirection(uv, ro, vec3(0.), 2.);

  // color, fog and light direction
  //vec3 ld = normalize(vec3(.5, .8, .5));
  vec3 ld = vec3(5., 8., 3.);
  vec3 fogColor = vec3(.1, .4, .5);
  //vec3 fogColor = vec3(.2, .3, .8) * .1;
  vec3 fog = fogColor * (.5 + (length(uv) - .3));
  vec3 color = fog;

  // scene
  vec2 sc = trace(ro, rd);
  float t = sc.x;

  if (t > 0.) {
    vec3 p = ro + rd * t;
    vec3 normal = getNormal(p);
    vec3 albido = vec3(.2, .3, .8) * 2.;//base color

    if (sc.y > .9) {
      albido = vec3(.8, .2, .3) * 2.;
      color = getLight(ld, p, rd, 1.2, Material(0., .8, 1.)) * vec3(.3, .5, .2) * 2.;
      color *= albido * 2.;
    } else {
      color = getLight(ld, p, rd, .5, Material(.7, .3, 4.5)) * vec3(.3, .5, .2) * 2.;
      color /= albido * 3.;
    }

    // lightning
    ld.xz *= rotate(tt * 10.);
    color = mix(color, getLight(ro, p, rd, .5, Material(0., .7, 5.2)) * albido, .4);

    color = mix(color, fog, 1. - exp(-.00006*t*t*t)); //gradient
  } 

  glFragColor = vec4(pow(color, vec3(.45)), 1.);
}
