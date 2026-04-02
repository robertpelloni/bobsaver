#version 420

// original https://www.shadertoy.com/view/3sByzG

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define i_time time
#define i_resolution resolution

float tt;
vec3 ap, bp;
float attr;

mat2 rot2(float r) {
  return mat2(cos(r), sin(r), -sin(r), cos(r));
}

float sd_cylinder(vec3 p, float r, float height) {
  float d = length(p.xz) - r;
  d = max(d, abs(p.y) - height);
  return d;
}

float sd_box(vec3 p, vec3 b) {
  vec3 q  = abs(p) - b;
  return max(max(q.x, q.y), q.z);
}

float spiral(vec3 p) {
  vec3 q = p - vec3(.0, 2.5, .0);
  q.y *= 0.04;
  q.xz *= rot2((sin(q.y + 3.0)-tt*.05)*20.0);
  q.yz *= rot2(radians(20.0));
  q.y *= 0.18;
  q = abs(q) - vec3(0.3, -.55, 3.0);
  q -= vec3(.5, .05, 0.);
  float d = length(q) - .7;
  return d*0.5;
}

vec2 rails(vec3 p) {
  vec3 q = p;

  q.y -= .4;
  q = abs(q) - vec3(1.2, .2, 0.);
  vec2 a = vec2(sd_box(q, vec3(.1, .3, 20.)), 1.0);

  q = p;
  q.z = abs(q.z) - 2.0;
  q.xy *= rot2(radians(90.0));
  vec2 b = vec2(sd_cylinder(q - vec3(.8, 0, 0), 0.2, 5.), 1.0);

  a = (a.x < b.x) ? a : b;

  a.x *= 0.8;
  return a;
}

vec2 map(vec3 p) {
  attr = max(0.0, (6.0 - (length(p + vec3(0., 0., 1.0-tt*2.5)) - 6.0)));

  vec3 q = p;
  vec2 a = vec2(length(q - vec3(0., 0., 10. + tt*2.5)) - 2.5, 2.0);

  q = p;
  q.z = mod(q.z - 1.0, 11.0);
  q = abs(q) - vec3(0., 6., 11.);
  for (int i=0; i<6; i++) {
    q = abs(q) - vec3(2.0, 0.0, 0.5);
    //q.xz *= rot2(radians(i*5));
    q.xy *= rot2(radians(4.+float(i)*1.5));
  }

  vec2 b = rails(q);

  a = (a.x < b.x) ? a : b;

  float s = sin(tt*.5)*2.0 +  + 1.5;
  float ss = cos(tt*.5)*2.0 +  + 1.5;
  q = abs(q) - vec3(s, ss*2.0, 0.);
  b = rails(q);

  a = (a.x < b.x) ? a : b;

  q = p;
  q.yz *= rot2(radians(90.0));
  b = vec2(spiral(q), 1.0);

  a = (a.x < b.x) ? a : b;

  return a;
}

vec2 trace(vec3 ro, vec3 rd) {
  vec2 h, t = vec2(0.1);
  for (int i=0; i<128; i++) {
    h = map(ro+rd*t.x);
    if (h.x < .0001 || t.x > 50.0) break;
    t.x += h.x;
    t.y = h.y;
  }
  if (t.x > 50.0) t.x = 0.0;
  return t;
}

void main(void) {
  vec4 frag_color = glFragColor;
  vec2 frag_coord = gl_FragCoord.xy;

  vec2 uv = vec2(frag_coord.x / i_resolution.x, frag_coord.y / i_resolution.y);
  uv -= 0.5;
  uv /= vec2(i_resolution.y / i_resolution.x, 1);

  tt = i_time*0.5;

  vec3 ro = vec3(0., 1., -20.);
  ro.z += tt*2.5;
  // ro.xz *= rot2(tt*.5);

  vec3 cam_target = vec3(0, 5, 0);
  cam_target.z += tt*2.5;

  vec3 cw = normalize(cam_target - ro);
  vec3 cu = normalize(cross(cw, vec3(0,1,0)));
  vec3 cv = normalize(cross(cu, cw));

  vec3 rd = mat3(cu, cv, cw) * normalize(vec3(uv, 0.5));

  vec3 ld = normalize(vec3(.3, .5, -.5));

  // Fibonacci Blue #112358, R: 17, G: 35 B: 88

  vec3 fog = vec3(.066, .137, .345) * (1.0 - (length(uv)-0.2));
  vec3 col = fog;

  vec2 scene = trace(ro, rd);
  float t = scene.x;

  if (t > 0.0) {
    vec3 pp = ro+rd*t;

    vec2 e = vec2(.00035, -.00035);
    vec3 nor = normalize(e.xyy*map(pp+e.xyy).x +
                         e.yyx*map(pp+e.yyx).x +
                         e.xyx*map(pp+e.xyx).x +
                         e.xxx*map(pp+e.xxx).x);

    vec3 b0 = vec3(.1, .5, .8);
    vec3 b1 = vec3(0.7, .8, .8);
    vec3 base = mix(b0, b1, attr);

    if (scene.y == 1.0) {

      float diff = max(0., dot(nor, ld));

      float aor = t/30.;
      float ao = exp2(-2.*pow(max(0.,1.-map(pp+nor*aor).x/aor),2.));

      float fr = pow(1.+dot(nor,rd),2.);

      vec3 sss = vec3(0.5)*smoothstep(0.,1.,map(pp+ld*0.4).x/0.4);

      col = base*(0.9*ao+0.2)*(diff+sss);
      col = mix(col, b0, min(fr, 0.2));

    }

    col = mix(col, fog, 1.0 - exp(-.00005*t*t*t));

    if (scene.y == 2.0) {
      float fr = pow(1.+dot(nor,rd),5.);
      col = mix(vec3(0.), base, min(fr, 0.8));
    }

  }

  glFragColor = vec4(col, 1.0);
}
