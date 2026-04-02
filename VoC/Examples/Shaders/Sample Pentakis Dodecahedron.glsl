#version 420

// original https://www.shadertoy.com/view/sdsXzS

uniform int frames;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// "Pentakis Dodecahedron" by dr2 - 2021
// License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License

float SmoothMax (float a, float b, float r);
mat3 StdVuMat (float el, float az);
vec2 Rot2D (vec2 q, float a);
vec2 Rot2Cs (vec2 q, vec2 cs);
float Fbm2 (vec2 p);

vec3 ltDir;
float tCur, dstFar, rEx, rIn;
int idObj;
const float pi = 3.1415927;

#define VAR_ZERO min (frames, 0)

#define DMIN(id) if (d < dMin) { dMin = d;  idObj = id; }

vec3 DodecSym (vec3 p)
{   // (from "Chinese Puzzle Balls 2")
  vec2 csD;
  csD = sin (0.5 * atan (2.) + vec2 (0.5 * pi, 0.));
  p.xz = Rot2Cs (vec2 (p.x, abs (p.z)), csD);
  p.xy = Rot2D (p.xy, - 0.1 * pi);
  p.x = - abs (p.x);
  for (int k = VAR_ZERO; k <= 3; k ++) {
    p.zy = Rot2Cs (p.zy, vec2 (csD.x, - csD.y));
    p.y = - abs (p.y);
    p.zy = Rot2Cs (p.zy, csD);
    if (k < 3) p.xy = Rot2Cs (p.xy, sin (-2. * pi / 5. + vec2 (0.5 * pi, 0.)));
  }
  p.xy = sin (mod (atan (p.x, p.y) + pi / 5., 2. * pi / 5.) - pi / 5. +
     vec2 (0., 0.5 * pi)) * length (p.xy);
  p.xz = - vec2 (abs (p.x), p.z);
  return p;
}

float ObjDf (vec3 p)
{
  vec3 q;
  float dMin, d, a1, a2;
  dMin = dstFar;
  q = DodecSym (p);
  a1 = 0.5 * acos (- 1. / sqrt (5.));
  a2 = 0.5 * acos (- (80. + 9. * sqrt (5.)) / 109.);
  d = abs (length (q) - rEx) - 0.1;
  d = SmoothMax (d, min (dot (q.yz, sin (a1 - pi + vec2 (0., 0.5 * pi))),
     dot (q.xy, sin (pi / 5. + vec2 (0.5 * pi, 0.)))) - 0.06, 0.04);
  DMIN (1);
  d = - dot (q.yz, sin (a1 - a2 + vec2 (0., 0.5 * pi))) - rIn;
  DMIN (2);
  return dMin;
}

float ObjRay (vec3 ro, vec3 rd)
{
  float dHit, d;
  dHit = 0.;
  for (int j = VAR_ZERO; j < 120; j ++) {
    d = ObjDf (ro + dHit * rd);
    if (d < 0.001 || dHit > dstFar) break;
    dHit += d;
  }
  return dHit;
}

vec3 ObjNf (vec3 p)
{
  vec4 v;
  vec2 e;
  e = vec2 (0.0005, -0.0005);
  for (int j = VAR_ZERO; j < 4; j ++) {
    v[j] = ObjDf (p + ((j < 2) ? ((j == 0) ? e.xxx : e.xyy) : ((j == 2) ? e.yxy : e.yyx)));
  }
  v.x = - v.x;
  return normalize (2. * v.yzw - dot (v, vec4 (1.)));
}

float ObjSShadow (vec3 ro, vec3 rd)
{
  float sh, d, h;
  sh = 1.;
  d = 0.01;
  for (int j = VAR_ZERO; j < 40; j ++) {
    h = ObjDf (ro + d * rd);
    sh = min (sh, smoothstep (0., 0.05 * d, h));
    d += h;
    if (sh < 0.05) break;
  }
  return 0.5 + 0.5 * sh;
}

vec4 SphHit (vec3 ro, vec3 rd, float rad)
{
  vec3 vn;
  float b, d, w;
  b = dot (rd, ro);
  w = b * b + rad * rad - dot (ro, ro);
  d = dstFar;
  if (w > 0.) {
    d = - b - sqrt (w);
    vn = (ro + d * rd) / rad;
  }
  return vec4 (d, vn);
}

vec3 BgCol (vec3 rd)
{
  vec3 col;
  vec2 u;
  float el, f;
  el = asin (rd.y);
  u = vec2 (atan (rd.z, - rd.x) + pi, tan (2. * atan (0.5 * el))) / (2. * pi);
  f = 64.;
  col = mix (vec3 (0.1, 0.2, 0.4), vec3 (0.8), mix (Fbm2 (f * u),
     Fbm2 (f * (u - vec2 (1., 0.))), u.x));
  col = mix (col, vec3 (0.2, 0.3, 0.4), smoothstep (0.95, 0.98, abs (el) / (0.5 * pi)));
  return col;
}

vec3 ShowScene (vec3 ro, vec3 rd)
{
  vec4 col4, ds4;
  vec3 col, vn, roo;
  float dstObj, nDotL, sh;
  rEx = 2.;
  rIn = 0.8 + 0.4 * sin (tCur);
  roo = ro;
  dstObj = ObjRay (ro, rd);
  if (dstObj < dstFar) {
    ro += dstObj * rd;
    vn = ObjNf (ro);
    if (idObj == 1) col4 = vec4 (1., 0.8, 0.2, 0.2) * (0.95 + 0.05 * sin (32. * pi * length (ro)));
    else if (idObj == 2) col4 = vec4 (0.8, 1., 0.2, 0.3);
    sh = ObjSShadow (ro + 0.01 * vn, ltDir);
    nDotL = max (dot (vn, ltDir), 0.);
    col = col4.rgb * (0.2 + 0.8 * sh * nDotL * nDotL) +
       col4.a * step (0.95, sh) * pow (max (0., dot (ltDir, reflect (rd, vn))), 32.);
  } else {
    col = BgCol (rd);
  }
  ds4 = SphHit (roo, rd, rEx + 0.06);
  if (ds4.x < min (dstObj, dstFar)) {
    vn = ds4.yzw;
    col = mix (col * vec3 (0.9, 1., 0.9), BgCol (reflect (rd, vn)),
       0.1 + 0.9 * pow (1. - max (- dot (rd, vn), 0.), 5.));
  }
  return clamp (col, 0., 1.);
}

#define AA  1   // optional antialiasing

void main(void)
{
  mat3 vuMat;
  vec4 mPtr;
  vec3 ro, rd, col;
  vec2 canvas, uv;
  float el, az, zmFac, sr;
  canvas = resolution.xy;
  uv = 2. * gl_FragCoord.xy / canvas - 1.;
  uv.x *= canvas.x / canvas.y;
  tCur = time;
  mPtr = vec4(0.0);//mouse*resolution.xy;
  mPtr.xy = mPtr.xy / canvas - 0.5;
  az = 0.;
  el = 0.1 * pi;
  if (mPtr.z > 0.) {
    az += 2. * pi * mPtr.x;
    el += pi * mPtr.y;
  } else {
    az -= 0.03 * pi * tCur;
    el -= 0.15 * pi * sin (0.01 * pi * tCur);
  }
  vuMat = StdVuMat (el, az);
  ro = vuMat * vec3 (0., 0., -12.);
  zmFac = 5.2;
  dstFar = 100.;
  ltDir = vuMat * normalize (vec3 (1., 1., -1.));
#if ! AA
  const float naa = 1.;
#else
  const float naa = 3.;
#endif  
  col = vec3 (0.);
  sr = 2. * mod (dot (mod (floor (0.5 * (uv + 1.) * canvas), 2.), vec2 (1.)), 2.) - 1.;
  for (float a = float (VAR_ZERO); a < naa; a ++) {
    rd = vuMat * normalize (vec3 (uv + step (1.5, naa) * Rot2D (vec2 (0.5 / canvas.y, 0.),
       sr * (0.667 * a + 0.5) * pi), zmFac));
    col += (1. / naa) * ShowScene (ro, rd);
  }
  glFragColor = vec4 (col, 1.);
}

vec2 Rot2Cs (vec2 q, vec2 cs)
{
  return vec2 (dot (q, vec2 (cs.x, - cs.y)), dot (q.yx, cs));
}

float SmoothMin (float a, float b, float r)
{
  float h;
  h = clamp (0.5 + 0.5 * (b - a) / r, 0., 1.);
  return mix (b, a, h) - r * h * (1. - h);
}

float SmoothMax (float a, float b, float r)
{
  return - SmoothMin (- a, - b, r);
}

mat3 StdVuMat (float el, float az)
{
  vec2 ori, ca, sa;
  ori = vec2 (el, az);
  ca = cos (ori);
  sa = sin (ori);
  return mat3 (ca.y, 0., - sa.y, 0., 1., 0., sa.y, 0., ca.y) *
         mat3 (1., 0., 0., 0., ca.x, - sa.x, 0., sa.x, ca.x);
}

vec2 Rot2D (vec2 q, float a)
{
  vec2 cs;
  cs = sin (a + vec2 (0.5 * pi, 0.));
  return vec2 (dot (q, vec2 (cs.x, - cs.y)), dot (q.yx, cs));
}

const float cHashM = 43758.54;

vec2 Hashv2v2 (vec2 p)
{
  vec2 cHashVA2 = vec2 (37., 39.);
  return fract (sin (dot (p, cHashVA2) + vec2 (0., cHashVA2.x)) * cHashM);
}

float Noisefv2 (vec2 p)
{
  vec2 t, ip, fp;
  ip = floor (p);  
  fp = fract (p);
  fp = fp * fp * (3. - 2. * fp);
  t = mix (Hashv2v2 (ip), Hashv2v2 (ip + vec2 (0., 1.)), fp.y);
  return mix (t.x, t.y, fp.x);
}

float Fbm2 (vec2 p)
{
  float f, a;
  f = 0.;
  a = 1.;
  for (int i = 0; i < 5; i ++) {
    f += a * Noisefv2 (p);
    a *= 0.5;
    p *= 2.;
  }
  return f * (1. / 1.9375);
}
