#version 420

// original https://www.shadertoy.com/view/tdyfWd

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

mat4 rotationX( in float angle) {
  return mat4(1.0, 0, 0, 0,
    0, cos(angle), -sin(angle), 0,
    0, sin(angle), cos(angle), 0,
    0, 0, 0, 1);
}

mat4 rotationY( in float angle) {
  return mat4(cos(angle), 0, sin(angle), 0,
    0, 1.0, 0, 0,
    -sin(angle), 0, cos(angle), 0,
    0, 0, 0, 1);
}

mat4 rotationZ( in float angle) {
  return mat4(cos(angle), -sin(angle), 0, 0,
    sin(angle), cos(angle), 0, 0,
    0, 0, 1, 0,
    0, 0, 0, 1);
}
vec3 rotate( in vec3 p, in float xrot, in float yrot, in float zrot) {
  vec4 rot = vec4(p, 1.0) * rotationX(xrot) * rotationY(yrot) * rotationZ(zrot);
  return rot.xyz; // ref https://gist.github.com/onedayitwillmake/3288507
}
float random( in vec2 st) {
  return fract(sin(dot(st.xy,
      vec2(12.9898, 78.233))) *
    43758.5453123);
}
float noise( in vec2 st) {
  vec2 i = floor(st);
  vec2 f = fract(st);

  float a = random(i);
  float b = random(i + vec2(1.0, 0.0));
  float c = random(i + vec2(0.0, 1.0));
  float d = random(i + vec2(1.0, 1.0));

  vec2 u = f * f * (3.0 - 2.0 * f);

  return mix(a, b, u.x) +
    (c - a) * u.y * (1.0 - u.x) +
    (d - b) * u.x * u.y;
}
float fbm( in vec2 p) { // ref https://thebookofshaders.com/13/
  float y = 0.;
  float f = 0.007;
  float a = 0.5;
  for (int i = 0; i < 10; i++) {
    y += a * noise(f * p * 100.);
    f *= 2.0;
    a *= 0.5;
  }
  return y;
}
float terrain( in vec2 p) {
  return fbm(p) * 2.0;
}
float raymarch( in vec3 ro, in vec3 rd, in int w) {
  #define dt 0.05
  vec3 p;
  float h;
  float t = 0.;
  float dist;
  for (int i = 0; i < 64; i++) {
    p = ro + rd * t;
    h = terrain(vec2(p.x, p.z));
    dist = (p.y - h) / 2.;
    if(w == 1) {
      dist = min(dist,abs(0.7-p.y));
    }
    t += dist;

  }
  return t;
}

float fresnel( in vec3 i, in vec3 n, in float eta) {
  float r0 = (1.-eta)/(1.+eta);
  r0 *= r0;
  return clamp(0.0,1.0,r0 + (1. - r0) * pow((1. - clamp(0.,1.,dot(i, n))), 5.0));
}
vec3 normal( in vec2 pos) {
  vec2 e = vec2(0.03, 0.0);
  return normalize(vec3(terrain(pos - e.xy) - terrain(pos + e.xy),
    2.0 * e.x,
    terrain(pos - e.yx) - terrain(pos + e.yx)));
}

vec3 interpolate(vec3 a, vec3 b, float t) {
  return mix(a, b, clamp(t, 0.0, 1.0));
}
float ggx( in float a, in float cosine) {
  return (a * a) / (3.14159265 * pow(cosine * cosine * (a * a - 1.) + 1., 2.0));
}
vec3 bgcol( in vec2 uv) {
  float len = length(vec2(uv.x, uv.y * resolution.y / resolution.x) - vec2(0.2, 0.2));
  float sun;
  if (abs(len) > 0.4) {
    sun = ggx(0.3, 0.0);
  } else {
    float dotProd = 1. - 2. * len;
    sun = ggx(0.3, dotProd);
  }
  return min(vec3(1., 1., 1.), mix(vec3(52., 82., 235.) / 255., vec3(135., 206., 235.) / 255., 0.5 - uv.y) + vec3(1.0, 1., 0.) * sun);

} // sun and sky

vec3 fullBcol( in vec2 uv, in vec3 o, in vec3 d, inout vec3 bcol) {
  vec2 cloudUV = 0.00002 * (o.xz + d.xz * ((3.) * 40000.0 - o.y) / d.y); // ref https://www.shadertoy.com/view/Msdfz8
  cloudUV.y += time * 0.7;
  bcol = bgcol(uv * 0.5 * resolution.y / resolution.x + vec2(d.x, d.y));
  vec3 bcol2 = bcol;
  bcol = interpolate(bcol, vec3(1.0), 2.5 * pow(fbm(cloudUV), 5.));
  bcol = interpolate(bcol2, bcol, d.y * 4.0);
  return bcol;
} // sun, sky, and clouds
vec3 scol( in float y) {
  vec3 sc;
  if (y < .9)
    sc = vec3(0.486, 0.988, 0.0);
  else if (y < 1.2)
    sc = interpolate(vec3(0.486, 0.988, 0.0), vec3(0.341, 0.231, 0.047), (y - 1.) / 0.1);
  else
    sc = interpolate(vec3(0.341, 0.231, 0.047), vec3(1.0), (y - 1.3) / 0.1);
  return sc;
} // terrain color
void main(void) {
  vec3 col, bcol;
  vec2 uv = gl_FragCoord.xy / resolution.xy - vec2(0.5);
  vec2 mouse = vec2(0.0); //mouse*resolution.xy.xy / resolution.xy - vec2(0.5);
  vec3 o = vec3(0., 2., time);
  vec3 d = normalize(vec3(uv.x, uv.y - 0.2, 1.0));
  d = rotate(d, -mouse.y, mouse.x, 0.0);
  float t = raymarch(o, d, 1);
  vec3 i = o + d * t;
  vec3 l = -normalize(vec3(vec2(.2, .2)-i.xy, 1.0-(i.y-o.y)));
  vec3 n = normal(i.xz);
  n = normalize(n + 0.4 * vec3(random(n.xy * 100.), random(n.yz * 100.), random(n.zx * 100.)));
  float shade = dot(n, l);
  vec3 sc;
  if (i.y < .71) {
    n = vec3(0.,1.,0.);
    vec3 r = reflect(d,n);
    vec3 rf = refract(d, n, 1.);
    float t2 = raymarch(i, r, 0);
    vec3 rcol;
    vec3 rfcol;
    vec3 bcol2;
    vec3 i2;
    vec3 n2;
    vec3 l2;
    if (t2 > 16.) {
      rcol = mix(vec3(52., 82., 235.) / 255., vec3(135., 206., 235.) / 255., .5 - r.y);
    } else {
      i2 = i + r * t2;
      n2 = normal(i2.xz);
      l2 = -normalize(vec3(vec2(.2, .2)-i2.xy, 1.0-(i2.y-i.y)));
      rcol = scol(i2.y) * dot(n2, l2);
    }
    t2 = raymarch(i, rf, 0);
      if (t2 > 16.) {
      rfcol = mix(vec3(52., 82., 235.) / 255., vec3(135., 206., 235.) / 255., 0.5 - r.y);
    } else {
      i2 = i + rf * t2;
      n2 = normal(i2.xz);
      l2 = -normalize(vec3(vec2(.2, .2)-i2.xy, 1.0-(i2.y-i.y)));
      rfcol = scol(i2.y) * dot(n2, l2);
    }
    vec3 h = normalize(l-i);
    rcol += ggx(0.3,dot(n,h))*vec3(1.0,1.0,0.8);
    float fres = fresnel(d, -n, 1.33);
    fres = 0.0;
    col = mix(mix(rfcol,rcol,fres),vec3(0.0,0.0,1.0)*dot(n,l),0.5);
    //col = rcol;
    //col = vec3(fres);
  } else {
    sc = scol(i.y);

    col = sc * shade;
  }

  if (t > 16.) {
    col = fullBcol(uv, o, d, bcol);
    col = interpolate(col, bcol, (min(20., t) - 16.0) / 4.0);
  }

  glFragColor = vec4(col, 1.0);
}
